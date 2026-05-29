import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'nutrition_log.dart';
import 'app_theme.dart';

class AiService {
  static final AiService instance = AiService._();
  AiService._();

  Future<GenerateContentResponse> _generateContentWithRetry(
    String prompt, {
    List<Part>? additionalParts,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API Key is missing. Please configure it in your .env file.');
    }

    final models = ['gemini-2.0-flash', 'gemini-2.5-flash-lite', 'gemini-2.5-flash', 'gemini-3.5-flash'];
    dynamic lastError;

    for (final modelName in models) {
      int attempt = 0;
      const maxAttempts = 2;
      Duration delay = const Duration(milliseconds: 1000);

      while (attempt < maxAttempts) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            generationConfig: GenerationConfig(
              temperature: 0.0,
            ),
          );
          
          final content = Content.multi([
            TextPart(prompt),
            ...?additionalParts,
          ]);

          final response = await model.generateContent([content]).timeout(const Duration(seconds: 25));
          return response;
        } catch (e) {
          lastError = e;
          final errorMsg = e.toString().toLowerCase();
          
          if (errorMsg.contains('503') || errorMsg.contains('limit') || errorMsg.contains('demand') || errorMsg.contains('unavailable')) {
            attempt++;
            if (attempt < maxAttempts) {
              debugPrint('Model $modelName busy (503/Quota). Retrying in ${delay.inSeconds}s (attempt $attempt/$maxAttempts)...');
              await Future.delayed(delay);
              delay = delay * 2;
              continue;
            }
          }
          
          debugPrint('Model $modelName failed: $e. Trying next model...');
          break; // Break the retry loop to try the next model string
        }
      }
    }

    throw lastError ?? Exception('Failed to generate content after retries and fallbacks');
  }

  Future<List<Map<String, dynamic>>> generateDailyInsights(
      NutrientTotals totals, List<FoodEntry> entries, double waterLitres) async {
    try {
      final foodNames = entries.map((e) => e.name).join(', ');
      
      final prompt = '''
You are a personalized AI nutrition assistant. I will provide you with a user's daily macronutrient totals, their water intake, and a list of foods they have eaten today.
Based on this data, provide 1 to 3 very brief, encouraging, and actionable insights about their day. 
For each insight, return exactly a JSON object in a list, with the following keys:
- "type": One of: "warning", "success", "tip", "info"
- "title": A short title for the insight (e.g., "Great Protein!")
- "body": A concise 1-2 sentence explanation or tip.

Here is the data:
Totals: Calories: ${totals.calories.round()}, Protein: ${totals.protein.round()}g, Carbs: ${totals.carbs.round()}g, Fat: ${totals.fat.round()}g, Sugar: ${totals.sugar.round()}g, Fiber: ${totals.fiber.round()}g, Sodium: ${totals.sodium.round()}mg.
Water Intake: ${waterLitres.toStringAsFixed(2)} Litres.
Foods Eaten: ${foodNames.isEmpty ? 'None' : foodNames}

Respond ONLY with the raw JSON array.
''';

      final response = await _generateContentWithRetry(prompt);
      final text = response.text;
      
      if (text != null) {
        var jsonStr = text.trim();
        if (jsonStr.startsWith('```json')) {
          jsonStr = jsonStr.substring(7, jsonStr.length - 3).trim();
        } else if (jsonStr.startsWith('```')) {
          jsonStr = jsonStr.substring(3, jsonStr.length - 3).trim();
        }

        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return jsonList.map((e) {
          final map = e as Map<String, dynamic>;
          
          IconData icon;
          Color color;
          
          switch (map['type']) {
            case 'warning':
              icon = Icons.warning_amber_rounded;
              color = AppTheme.dangerRed;
              break;
            case 'success':
              icon = Icons.check_circle_outline;
              color = AppTheme.primaryNeon;
              break;
            case 'tip':
              icon = Icons.lightbulb_outline;
              color = const Color(0xFFFF9F43);
              break;
            case 'info':
            default:
              icon = Icons.info_outline;
              color = Colors.blue;
              break;
          }
          
          return {
            'icon': icon,
            'color': color,
            'title': map['title'] ?? '',
            'body': map['body'] ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error generating AI insights: $e');
    }
    
    return [];
  }

  Future<FoodAnalysisResult?> analyzeFoodImage(Uint8List imageBytes, {bool isLabelMode = false}) async {
    try {
      final modeInstructions = isLabelMode
          ? '''The user has scanned an ingredient list / nutrition facts label of a food product.
Specifically identify and analyze the list of ingredients, chemical additives, artificial sweeteners, preservatives (e.g., MSG, sodium benzoate, BHA, carrageenan, high fructose corn syrup, food dyes), and processing agents.
In the "risks" list:
- Highlight these additives, artificial compounds, or excessive sodium/sugar.
- Detail the physiological or metabolic impact of each (e.g., gut microbiome disruption, insulin spikes, carcinogenic risk, inflammation).
Set the "healthScore" based heavily on the level of processing (highly processed foods with multiple chemical additives should get scores < 50).'''
          : '''The user has scanned a food dish, fresh item, or meal.
Identify the food, estimate the portion size, and determine its nutritional values.
In the "risks" list:
- Highlight allergens, high saturated fat, high sugar, or lack of essential nutrients.
- Provide clear reasons related to daily intake thresholds.''';

      final prompt = '''
You are an expert nutritionist, diet expert, and food scientist AI.
I am providing an image of a food item or its nutrition/ingredient label.

$modeInstructions

First, analyze if the image contains food, a dish, a meal, a food product, or a nutrition facts/ingredient label.
If the image is NOT relevant to food (e.g., humans, animals, cars, buildings, electronics, landscape, non-food text, etc.), you MUST set "isFood" to false in the JSON output, and you can leave other fields empty or zero.
Otherwise, if it is a food item or label, set "isFood" to true and perform the full analysis.

To ensure absolute consistency and prevent health score variance when scanning the same food, you MUST calculate the "healthScore" (0 to 100) using this exact mathematical rubric:
1. Start with a baseline score of 70.
2. Categorize the food level of processing:
   - Whole Foods / Single Ingredient (e.g., fresh fruit, raw vegetables, eggs, plain chicken breast, plain nuts): ADD +25 (Max 100).
   - Minimally Processed (e.g., olive oil, plain milk, plain yogurt, canned beans): ADD +10.
   - Moderately Processed (e.g., cheese, freshly baked bread, flavored yogurt): SUBTRACT -10.
   - Ultra-processed / Junk Foods (e.g., potato chips, soda, candy, instant noodles, sugary cereals, highly processed meats): SUBTRACT -40.
3. Adjust for nutrient density:
   - High Added Sugar (>10g per serving): SUBTRACT -15.
   - High Sodium (>400mg per serving): SUBTRACT -15.
   - High Saturated Fat (>5g per serving): SUBTRACT -10.
   - High Protein (>12g per serving) or High Fiber (>3g per serving): ADD +10.
4. Check for chemical additives (especially if isLabelMode is true):
   - Subtract -10 for each major artificial additive, sweetener, preservative, or coloring (e.g., aspartame, MSG, sodium benzoate, BHA, carrageenan, food dyes) up to a max deduction of -30.
5. Clamp the final healthScore strictly between 0 and 100.
Always apply this exact math logically so that identical foods return the exact same score.

Analyze it and return EXACTLY a JSON object with this exact structure, no markdown formatting (do NOT wrap in ```json ... ```, just return the raw JSON string):

{
  "isFood": true or false (boolean),
  "name": "Name of the food / product (string)",
  "healthScore": 0 to 100 (integer),
  "calories": number,
  "protein": number,
  "carbs": number,
  "sugar": number,
  "fat": number,
  "fiber": number,
  "sodium": number,
  "vitaminD": number,
  "iron": number,
  "calcium": number,
  "nutrients": [
    { "name": "Calories", "amount": "e.g. 380 kcal", "dailyValue": "e.g. 19% DV", "progress": 0.0 to 1.0 (float) }
  ],
  "risks": [
    { "name": "Ingredient or Additive name", "reason": "Detailed physiological impact / health consequence.", "level": "high" or "moderate" or "safe" }
  ],
  "summary": "A 2-3 sentence summary explaining the product's health quality. If it crosses the junk food limit (health score < 50), explicitly warn about the health consequences.",
  "tags": ["Tag1", "Tag2"],
  "alternatives": [
    {
      "name": "Healthier Alternative Name",
      "subtitle": "Brief reason why it's better",
      "price": "\$X.XX",
      "tag": "e.g. Organic, Low Sodium",
      "foodImageQuery": "A short, specific 1-2 word food tag (e.g. chickpeas or salad or yogurt)",
      "score": integer 0 to 100,
      "reason": "Why this alternative is recommended."
    }
  ]
}
''';

      final response = await _generateContentWithRetry(
        prompt,
        additionalParts: [DataPart('image/jpeg', imageBytes)],
      );

      final text = response.text;
      if (text != null) {
        var jsonStr = text.trim();
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr);
        if (match != null) {
          jsonStr = match.group(0)!;
        }

        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        return FoodAnalysisResult(
          isFood: map['isFood'] ?? true,
          name: map['name'] ?? 'Unknown',
          healthScore: map['healthScore'] ?? 50,
          calories: (map['calories'] ?? 0).toDouble(),
          protein: (map['protein'] ?? 0).toDouble(),
          carbs: (map['carbs'] ?? 0).toDouble(),
          sugar: (map['sugar'] ?? 0).toDouble(),
          fat: (map['fat'] ?? 0).toDouble(),
          fiber: (map['fiber'] ?? 0).toDouble(),
          sodium: (map['sodium'] ?? 0).toDouble(),
          vitaminD: (map['vitaminD'] ?? 0).toDouble(),
          iron: (map['iron'] ?? 0).toDouble(),
          calcium: (map['calcium'] ?? 0).toDouble(),
          nutrients: (map['nutrients'] as List<dynamic>? ?? []).map((n) {
            return AnalysisNutrient(
              name: n['name'] ?? '',
              amount: n['amount'] ?? '',
              dailyValue: n['dailyValue'] ?? '',
              progress: (n['progress'] ?? 0).toDouble(),
            );
          }).toList(),
          risks: (map['risks'] as List<dynamic>? ?? []).map((r) {
            return AnalysisRisk(
              name: r['name'] ?? '',
              reason: r['reason'] ?? '',
              level: r['level'] ?? 'safe',
            );
          }).toList(),
          summary: map['summary'] ?? '',
          tags: List<String>.from(map['tags'] ?? []),
          alternatives: (map['alternatives'] as List<dynamic>? ?? []).map((a) {
            final foodName = a['name']?.toString() ?? 'healthy food';
            
            // Extremely reliable direct image URLs that work perfectly on Flutter Web
            final fallbackUrls = [
              'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80', // Salad
              'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&q=80', // Healthy bowl
              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&q=80', // Veggie bowl
              'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400&q=80', // Salad bowl
              'https://images.unsplash.com/photo-1498837167922-41c543310776?w=400&q=80', // Various healthy
              'https://images.unsplash.com/photo-1511690656952-34342bb7c2f2?w=400&q=80', // Tomatoes/veggies
            ];
            
            final safeUrl = fallbackUrls[foodName.hashCode.abs() % fallbackUrls.length];

            return AnalysisAlternative(
              name: foodName,
              subtitle: a['subtitle'] ?? '',
              price: a['price'] ?? '',
              tag: a['tag'] ?? '',
              imageUrl: safeUrl,
              score: ((a['score'] ?? a['healthScore'] ?? a['health_score'] ?? 80) as num).toInt(),
              reason: a['reason'] ?? '',
            );
          }).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error analyzing food image: $e');
      rethrow;
    }
    
    return null;
  }

  Future<String> generateExpertTip() async {
    try {
      final prompt = 'You are an expert nutritionist. Provide a single, fascinating, highly actionable nutrition tip in 2 sentences max. No quotes, no markdown, just plain text.';
      final response = await _generateContentWithRetry(prompt);
      return response.text?.trim() ?? 'Stay hydrated! Drinking water boosts your metabolism.';
    } catch (e) {
      debugPrint('Error generating expert tip: $e');
      return 'Stay hydrated! Drinking water boosts your metabolism.';
    }
  }

  Future<List<CommunityPost>> generateLiveFeed() async {
    try {
      final prompt = '''
Generate a JSON array of exactly 4 realistic social media posts for a nutrition community app.
Each post must be an object with:
- "username": A fake realistic name (e.g. "Sarah J.")
- "timeAgo": A string (e.g. "2h ago", "15m ago")
- "foodName": A realistic healthy meal (e.g. "Avocado Toast", "Salmon Salad")
- "healthScore": A number between 70 and 100
- "calories": A number (e.g. 350)
- "protein": A number (e.g. 25)
- "foodImageQuery": A single, specific keyword to search for the food image (e.g. "avocado,toast" or "salmon,salad")
- "avatarSeed": A random number between 1 and 70

Return ONLY the raw JSON array. Do not include markdown blocks or any conversational text.
''';
      final response = await _generateContentWithRetry(prompt);
      final text = response.text;
      
      if (text != null) {
        // Use regex to strictly extract the JSON array in case Gemini adds markdown or conversational text
        final match = RegExp(r'\[[\s\S]*\]').firstMatch(text);
        if (match != null) {
          final jsonStr = match.group(0)!;
          final List<dynamic> jsonList = jsonDecode(jsonStr);
          return jsonList.map<CommunityPost>((e) {
            final map = e as Map<String, dynamic>;
            final foodQuery = map['foodImageQuery']?.toString() ?? 'healthy,food';
            final avatarSeed = map['avatarSeed']?.toString() ?? '1';
            
            return CommunityPost(
              username: map['username']?.toString() ?? 'User',
              userAvatar: 'https://i.pravatar.cc/150?img=$avatarSeed',
              timeAgo: map['timeAgo']?.toString() ?? 'Just now',
              foodName: map['foodName']?.toString() ?? 'Healthy Meal',
              foodImage: 'https://image.pollinations.ai/prompt/${Uri.encodeComponent('$foodQuery food plate')}?width=400&height=300&nologo=true',
              healthScore: (map['healthScore'] as num?)?.toInt() ?? 85,
              calories: (map['calories'] as num?)?.toInt() ?? 300,
              protein: (map['protein'] as num?)?.toInt() ?? 15,
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error generating live feed: $e');
    }
    return [];
  }

  Future<List<SmartRecipe>> generateSmartRecipes(String dietaryContext) async {
    try {
      final prompt = '''
You are a master nutritionist and chef. The user has the following nutritional context for today:
$dietaryContext

Generate a JSON array of exactly 4 unique recipes that would be highly beneficial for them right now.
Each recipe must be an object with:
- "name": Recipe title
- "foodImageQuery": A single, specific keyword to search for the food image (e.g. "chicken,salad")
- "healthScore": A number between 80 and 100
- "calories": A number (e.g. 450)
- "protein": A number (e.g. 35)
- "carbs": A number (e.g. 40)
- "fat": A number (e.g. 15)
- "fiber": A number (e.g. 8)
- "sugar": A number (e.g. 5)
- "sodium": A number (e.g. 400)

Return ONLY the raw JSON array. Do not include markdown blocks or any conversational text.
''';
      final response = await _generateContentWithRetry(prompt);
      final text = response.text;
      
      if (text != null) {
        final match = RegExp(r'\[[\s\S]*\]').firstMatch(text);
        if (match != null) {
          final jsonStr = match.group(0)!;
          final List<dynamic> jsonList = jsonDecode(jsonStr);
          return jsonList.map<SmartRecipe>((e) {
            final map = e as Map<String, dynamic>;
            final foodQuery = map['foodImageQuery']?.toString() ?? 'healthy,food';
            
            return SmartRecipe(
              name: map['name']?.toString() ?? 'Healthy Meal',
              foodImageQuery: 'https://image.pollinations.ai/prompt/${Uri.encodeComponent('$foodQuery recipe meal')}?width=400&height=300&nologo=true',
              healthScore: (map['healthScore'] as num?)?.toInt() ?? 85,
              calories: (map['calories'] as num?)?.toDouble() ?? 300,
              protein: (map['protein'] as num?)?.toDouble() ?? 15,
              carbs: (map['carbs'] as num?)?.toDouble() ?? 30,
              fat: (map['fat'] as num?)?.toDouble() ?? 10,
              fiber: (map['fiber'] as num?)?.toDouble() ?? 5,
              sugar: (map['sugar'] as num?)?.toDouble() ?? 5,
              sodium: (map['sodium'] as num?)?.toDouble() ?? 300,
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error generating smart recipes: $e');
    }
    return [];
  }
}

class CommunityPost {
  final String username;
  final String userAvatar;
  final String timeAgo;
  final String foodName;
  final String foodImage;
  final int healthScore;
  final int calories;
  final int protein;

  CommunityPost({
    required this.username,
    required this.userAvatar,
    required this.timeAgo,
    required this.foodName,
    required this.foodImage,
    required this.healthScore,
    required this.calories,
    required this.protein,
  });
}

class SmartRecipe {
  final String name;
  final String foodImageQuery;
  final int healthScore;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;

  SmartRecipe({
    required this.name,
    required this.foodImageQuery,
    required this.healthScore,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
  });
}
class FoodAnalysisResult {
  final bool isFood;
  final String name;
  final int healthScore;
  final double calories;
  final double protein;
  final double carbs;
  final double sugar;
  final double fat;
  final double fiber;
  final double sodium;
  final double vitaminD;
  final double iron;
  final double calcium;
  
  final List<AnalysisNutrient> nutrients;
  final List<AnalysisRisk> risks;
  final String summary;
  final List<String> tags;
  final List<AnalysisAlternative> alternatives;

  FoodAnalysisResult({
    required this.isFood,
    required this.name,
    required this.healthScore,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.sugar,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.vitaminD,
    required this.iron,
    required this.calcium,
    required this.nutrients,
    required this.risks,
    required this.summary,
    required this.tags,
    required this.alternatives,
  });
}

class AnalysisNutrient {
  final String name;
  final String amount;
  final String dailyValue;
  final double progress;

  AnalysisNutrient({required this.name, required this.amount, required this.dailyValue, required this.progress});
}

class AnalysisRisk {
  final String name;
  final String reason;
  final String level;

  AnalysisRisk({required this.name, required this.reason, required this.level});
}

class AnalysisAlternative {
  final String name;
  final String subtitle;
  final String price;
  final String tag;
  final String imageUrl;
  final int score;
  final String reason;

  AnalysisAlternative({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.tag,
    required this.imageUrl,
    required this.score,
    required this.reason,
  });
}

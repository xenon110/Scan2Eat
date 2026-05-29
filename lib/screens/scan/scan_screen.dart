import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../../core/app_theme.dart';
import '../../core/ai_service.dart';
import 'post_scan_action_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  CameraController? _cameraController;
  Uint8List? _pickedImageBytes;
  bool _isScanning = false;
  bool _isLabelMode = false; // false = Smart Scan, true = Label Reader

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
        
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras.first, ResolutionPreset.max, enableAudio: false);
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _showAnalysisErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1C2534),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.dangerRed, width: 1),
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.dangerRed,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerScan({ImageSource? directSource}) async {
    final picker = ImagePicker();
    final source = directSource ?? ImageSource.camera;
    Uint8List? bytes;

    // 1. Pick image (camera/gallery)
    if (source == ImageSource.camera && _cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final xFile = await _cameraController!.takePicture();
        bytes = await xFile.readAsBytes();
      } catch (e) {
        if (mounted) {
          _showAnalysisErrorSnackBar('Error capturing image: $e');
        }
        return;
      }
    } else {
      try {
        final pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 60,
          maxWidth: 512,
          maxHeight: 512,
        );
        if (pickedFile == null) return;
        bytes = await pickedFile.readAsBytes();
      } catch (e) {
        if (mounted) {
          setState(() {
            _pickedImageBytes = null;
            _isScanning = false;
          });
          _showAnalysisErrorSnackBar('Error choosing image: $e');
        }
        return;
      }
    }

    // 2. Perform AI analysis
    setState(() {
      _pickedImageBytes = bytes;
      _isScanning = true;
    });

    try {
      final result = await AiService.instance.analyzeFoodImage(bytes!, isLabelMode: _isLabelMode);
      
      if (!mounted) return;
      setState(() => _isScanning = false);

      if (result != null) {
        if (!result.isFood) {
          setState(() {
            _pickedImageBytes = null;
          });
          _showInvalidFoodPopup();
          return;
        }

        await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, animation, _) => FadeTransition(
              opacity: animation,
              child: PostScanActionScreen(
                result: result,
                imageBytes: bytes!,
              ),
            ),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
        if (mounted) {
          setState(() {
            _pickedImageBytes = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _pickedImageBytes = null;
          });
        }
        _showAnalysisErrorSnackBar('Failed to parse analysis response. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pickedImageBytes = null;
          _isScanning = false;
        });
        _showAnalysisErrorSnackBar('Analysis Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D14),
      body: Stack(
        children: [
          // ── Background Gradient Radial Glow ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, _) => CustomPaint(
                painter: _BackgroundGlowPainter(opacity: _pulseAnim.value * 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // 2. Guide text
                  _buildGuideText(),
                  const SizedBox(height: 12),

                  // 3. Scanner Reticle (Flexibly Centered & Responsive)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Dynamically scale scanner size based on screen height/width constraints
                        final scannerSize = math.min(
                          constraints.maxHeight * 0.85,
                          math.min(constraints.maxWidth * 0.95, 290.0),
                        );

                        return Center(
                          child: GestureDetector(
                            onTap: () => _triggerScan(directSource: ImageSource.camera),
                            child: AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, child) {
                                return Container(
                                  width: scannerSize,
                                  height: scannerSize,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                      color: AppTheme.primaryNeon.withValues(alpha: 0.5 + _pulseAnim.value * 0.4),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryNeon.withValues(alpha: _pulseAnim.value * 0.2),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: child,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Stack(
                                  children: [
                                    // Camera preview placeholder or picked image
                                    Positioned.fill(
                                      child: _pickedImageBytes != null
                                          ? Image.memory(
                                              _pickedImageBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : (_cameraController != null && _cameraController!.value.isInitialized)
                                              ? FittedBox(
                                                  fit: BoxFit.cover,
                                                  child: SizedBox(
                                                    width: _cameraController!.value.previewSize?.height ?? 1,
                                                    height: _cameraController!.value.previewSize?.width ?? 1,
                                                    child: CameraPreview(_cameraController!),
                                                  ),
                                                )
                                              : Container(
                                                  color: const Color(0xFF101722),
                                                  child: const Icon(Icons.camera_alt, color: Colors.white24, size: 60),
                                                ),
                                    ),
                                    
                                    // Dark Overlay
                                    Container(color: Colors.black.withValues(alpha: 0.2)),

                                    // Dynamic laser sweep
                                    AnimatedBuilder(
                                      animation: _scanLineController,
                                      builder: (_, _) {
                                        final topOffset = _scanLineController.value * (scannerSize - 6);
                                        return Positioned(
                                          top: topOffset,
                                          left: 0,
                                          right: 0,
                                            child: Container(
                                              height: 3,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    AppTheme.primaryNeon,
                                                    AppTheme.primaryCyan,
                                                    Colors.transparent,
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primaryNeon.withValues(alpha: 0.8),
                                                    blurRadius: 10,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                    // Tech HUD details at corners
                                    Positioned(
                                      top: 12,
                                      left: 14,
                                      child: Text(
                                        _isLabelMode ? 'HUD: INGREDIENT_SCAN' : 'HUD: SMART_MEAL_AI',
                                        style: TextStyle(
                                          color: AppTheme.primaryNeon.withValues(alpha: 0.6),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 14,
                                      child: Text(
                                        '60 FPS / 4K UHD',
                                        style: TextStyle(
                                          color: AppTheme.primaryCyan.withValues(alpha: 0.6),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      left: 14,
                                      child: Text(
                                        'AUTO_FOCUS: LOCKED',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      right: 14,
                                      child: Text(
                                        'SCAN2EAT_v2.0',
                                        style: TextStyle(
                                          color: AppTheme.primaryNeon.withValues(alpha: 0.5),
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),

                                    // Analyzing indicator overlay
                                    if (_isScanning)
                                      Container(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        child: const Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(color: AppTheme.primaryNeon, strokeWidth: 3),
                                              SizedBox(height: 16),
                                              Text(
                                                'ANALYZING NUTRITION...',
                                                style: TextStyle(
                                                  color: AppTheme.primaryNeon,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Corner brackets
                                    const Positioned(top: 0, left: 0, child: _CornerBracket(angle: 0)),
                                    const Positioned(top: 0, right: 0, child: _CornerBracket(angle: math.pi / 2)),
                                    const Positioned(bottom: 0, right: 0, child: _CornerBracket(angle: math.pi)),
                                    const Positioned(bottom: 0, left: 0, child: _CornerBracket(angle: math.pi * 1.5)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Status chip
                  _buildStatusChip(),
                  const SizedBox(height: 18),

                  // 5. Mode switcher
                  _buildModeSwitcher(),
                  const SizedBox(height: 14),

                  // 6. Big scan button
                  _buildScanButton(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header Widget ──────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Brand logo
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5A4FCF), Color(0xFF7E75E2)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5A4FCF).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Scan2Eat',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        
        // Actions
        Row(
          children: [
            // Gallery Upload Button (Pill shaped, clear CTA)
            GestureDetector(
              onTap: () => _triggerScan(directSource: ImageSource.gallery),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.photo_library, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Gallery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Flash Indicator
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, _) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNeon.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flash_on,
                  color: AppTheme.primaryNeon.withValues(alpha: 0.5 + _pulseAnim.value * 0.5),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Guide Text Widget ──────────────────────────────────────────────────────

  Widget _buildGuideText() {
    return Column(
      children: [
        Text(
          _isLabelMode ? 'Point at Ingredient Label' : 'Point at Food Item',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          _isLabelMode
              ? 'Align the ingredient list within the scanner frame'
              : 'AI will instantly identify & analyze nutritional content',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Status Chip Widget ─────────────────────────────────────────────────────

  Widget _buildStatusChip() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF131922),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppTheme.primaryNeon.withValues(alpha: 0.2 + _pulseAnim.value * 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryNeon.withValues(alpha: _pulseAnim.value * 0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNeon.withValues(alpha: 0.6 + _pulseAnim.value * 0.4),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withValues(alpha: _pulseAnim.value * 0.6),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isScanning ? 'PROCESSING MEAL...' : 'READY TO SCAN',
                style: TextStyle(
                  color: AppTheme.primaryNeon.withValues(alpha: 0.7 + _pulseAnim.value * 0.3),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mode Switcher Widget ───────────────────────────────────────────────────

  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF131922),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildModeTab('SMART SCAN', Icons.center_focus_weak, false)),
          Expanded(child: _buildModeTab('LABEL READER', Icons.document_scanner_outlined, true)),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, IconData icon, bool targetMode) {
    final isActive = _isLabelMode == targetMode;
    return GestureDetector(
      onTap: () => setState(() => _isLabelMode = targetMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryNeon.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? AppTheme.primaryNeon.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primaryNeon : Colors.white38,
              size: 15,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryNeon : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Scan Button Widget ─────────────────────────────────────────────────────

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () => _triggerScan(directSource: ImageSource.camera),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryNeon, AppTheme.primaryCyan],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryNeon.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.black, size: 22),
            const SizedBox(width: 10),
            Text(
              _isScanning ? 'ANALYZING...' : 'TAP TO SCAN',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvalidFoodPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final scale = 1.0 - (1.0 - anim1.value) * 0.12;
        return FadeTransition(
          opacity: anim1,
          child: Transform.scale(
            scale: scale,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161F2C).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFFAA00).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFAA00).withValues(alpha: 0.12),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Elegant Warning Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFAA00).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFAA00).withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.no_food_outlined,
                            color: Color(0xFFFFAA00),
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Dialog Heading
                        const Text(
                          'No Food Detected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Informational Text
                        Text(
                          'Scan2Eat analyzed the photo but could not identify any food items, ingredients, meals, or nutrition labels.\n\nKindly scan or upload a clear picture of your food.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        // Primary CTA Button
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            _triggerScan(directSource: ImageSource.camera);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFAA00), Color(0xFFFF8800)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFAA00).withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'TRY AGAIN',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Cancel/Dismiss option
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Corner Bracket Painter ──────────────────────────────────────────────────

class _CornerBracket extends StatelessWidget {
  final double angle;
  const _CornerBracket({required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.primaryNeon, width: 3.5),
            left: BorderSide(color: AppTheme.primaryNeon, width: 3.5),
          ),
        ),
      ),
    );
  }
}

// ─── Background Glow Painter ─────────────────────────────────────────────────

class _BackgroundGlowPainter extends CustomPainter {
  final double opacity;
  _BackgroundGlowPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryNeon.withValues(alpha: opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.45,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundGlowPainter old) =>
      old.opacity != opacity;
}

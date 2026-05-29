import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/notification_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.instance.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load notifications',
                style: TextStyle(color: AppTheme.dangerRed.withValues(alpha: 0.8), fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, color: Colors.white.withValues(alpha: 0.2), size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No Notifications Yet',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will let you know when there is an update.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? 'Notification';
              final message = data['message'] as String? ?? '';
              final isRead = data['isRead'] as bool? ?? true;
              final timestamp = data['timestamp'] as Timestamp?;
              final type = data['type'] as String? ?? 'info';

              String timeString = 'Just now';
              if (timestamp != null) {
                final date = timestamp.toDate();
                timeString = DateFormat('MMM d, h:mm a').format(date);
              }

              IconData icon;
              Color iconColor;
              switch (type) {
                case 'water':
                  icon = Icons.water_drop_rounded;
                  iconColor = const Color(0xFF4FC3F7);
                  break;
                case 'food':
                  icon = Icons.restaurant_rounded;
                  iconColor = AppTheme.primaryNeon;
                  break;
                case 'goal':
                  icon = Icons.emoji_events_rounded;
                  iconColor = const Color(0xFFFFD700);
                  break;
                default:
                  icon = Icons.info_outline_rounded;
                  iconColor = AppTheme.primaryCyan;
                  break;
              }

              return GestureDetector(
                onTap: () {
                  if (!isRead) {
                    NotificationService.instance.markAsRead(doc.id);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead ? AppTheme.cardBackground : AppTheme.primaryNeon.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryNeon.withValues(alpha: 0.3),
                    ),
                    boxShadow: isRead ? [] : AppTheme.neonGlow(intensity: 0.05, blur: 12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: isRead ? Colors.white : AppTheme.primaryNeon,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryNeon,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timeString,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

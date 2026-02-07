import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../services/moderation_service.dart';

class ModerationLogsScreen extends StatelessWidget {
  const ModerationLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Padding(
          padding: EdgeInsets.all(
            isMobile ? AppSizes.paddingMD : AppSizes.paddingLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moderation Logs',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),
              Expanded(
                child: StreamBuilder<List<ModerationLog>>(
                  stream: ModerationService.getAllLogs(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.security,
                              size: 64,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 16),
                            const Text('All clear! No moderation logs found.'),
                          ],
                        ),
                      );
                    }

                    final logs = snapshot.data!;
                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: AppSizes.paddingMD,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMD,
                            ),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.5),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: _buildLogIcon(log.type),
                            title: Text(
                              log.userName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.details,
                                  style: GoogleFonts.inter(fontSize: 13),
                                ),
                                Text(
                                  '${log.timestamp.toString().split('.')[0]} ${log.type.name.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: !isMobile && log.relatedOrderId != null
                                ? Chip(
                                    label: Text(
                                      'Order: ${log.relatedOrderId!.substring(0, 5)}...',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogIcon(ModerationLogType type) {
    IconData icon;
    Color color;
    switch (type) {
      case ModerationLogType.contactSharing:
        icon = Icons.contact_phone;
        color = AppColors.warning;
        break;
      case ModerationLogType.suspiciousDispute:
        icon = Icons.gavel;
        color = AppColors.error;
        break;
      case ModerationLogType.fakeAccount:
        icon = Icons.person_off;
        color = AppColors.error;
        break;
      case ModerationLogType.spam:
        icon = Icons.email;
        color = AppColors.secondary;
        break;
    }
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

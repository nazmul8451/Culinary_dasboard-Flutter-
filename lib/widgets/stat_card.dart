import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';

/// Reusable statistics card widget for dashboard
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final double? percentageChange;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.percentageChange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isSmall = cardWidth < 180;
        final isXSmall = cardWidth < 140;

        return Card(
          elevation: AppSizes.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
            child: Container(
              padding: EdgeInsets.all(
                isSmall ? AppSizes.paddingSM : AppSizes.paddingMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon Container
                      Container(
                        padding: EdgeInsets.all(
                          isXSmall ? AppSizes.paddingSM : AppSizes.paddingMD,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSM,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: isXSmall ? AppSizes.iconMD : AppSizes.iconLG,
                        ),
                      ),

                      // Percentage Change Badge
                      if (percentageChange != null && !isXSmall)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingSM,
                            vertical: AppSizes.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color: percentageChange! >= 0
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusXS,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                percentageChange! >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: AppSizes.iconXS,
                                color: percentageChange! >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${percentageChange!.abs().toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: percentageChange! >= 0
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.paddingSM),

                  // Title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: isSmall ? 12 : 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: isSmall ? 2 : AppSizes.paddingXS),

                  // Value
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: isSmall ? 20 : 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  // Subtitle
                  if (subtitle != null && !isSmall) ...[
                    const SizedBox(height: AppSizes.paddingXS),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

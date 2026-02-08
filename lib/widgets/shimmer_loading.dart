import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerLoading.circular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  ShimmerLoading.rounded({
    super.key,
    this.width = double.infinity,
    required this.height,
    double borderRadius = 8,
  }) : shapeBorder = RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(borderRadius),
       );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border.withOpacity(0.3),
      highlightColor: AppColors.surface,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: AppColors.border,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class ShimmerSwitcher extends StatelessWidget {
  final bool isLoading;
  final Widget skeleton;
  final Widget child;

  const ShimmerSwitcher({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Using a simple ternary instead of AnimatedSwitcher/AnimatedCrossFade
    // because complex widgets like DataTable2 and GridView can trigger
    // framework-level assertion errors when detached during animations.
    return isLoading ? skeleton : child;
  }
}

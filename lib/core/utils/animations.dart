import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension AnimationExtension on Widget {
  /// Simple fade in with a slide up effect
  Widget animateFadeInUp({int delay = 0, int duration = 500}) {
    return this
        .animate()
        .fadeIn(duration: duration.ms, delay: delay.ms)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: duration.ms,
          curve: Curves.easeOutQuad,
        );
  }

  /// Scale in effect
  Widget animateScaleIn({int delay = 0, int duration = 400}) {
    return this
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: duration.ms,
          delay: delay.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: duration.ms, delay: delay.ms);
  }

  /// Staggered entry for lists or grids
  Widget animateStaggered(int index, {int interval = 50}) {
    return this.animateFadeInUp(delay: index * interval);
  }

  /// Slide from right effect (good for side panels or cards)
  Widget animateSlideInRight({int delay = 0, int duration = 500}) {
    return this
        .animate()
        .fadeIn(duration: duration.ms, delay: delay.ms)
        .slideX(
          begin: 0.1,
          end: 0,
          duration: duration.ms,
          curve: Curves.easeOutQuad,
        );
  }
}

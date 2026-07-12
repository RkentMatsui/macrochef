import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// A light, rounded card: solid fill, hairline border, soft drop shadow.
///
/// Previously a frosted-glass surface; in the light theme it is a plain card.
/// The [frosted] and [blurSigma] parameters are retained for source
/// compatibility but no longer have a visual effect.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blurSigma;
  final Color fill;
  final bool frosted;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.blurSigma = 18,
    this.fill = AppColors.glassFill,
    this.frosted = true,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: br,
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }
}

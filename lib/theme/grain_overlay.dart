import 'package:flutter/material.dart';

/// No-op in the light theme (kept for source compatibility). Previously painted
/// a subtle grain texture over the dark canvas.
class GrainOverlay extends StatelessWidget {
  final Widget child;
  const GrainOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

import 'package:flutter/material.dart';

class ThreeDots extends StatefulWidget {
  final Color? color;
  final double? size;

  const ThreeDots({
    super.key,
    this.color,
    this.size,
  });

  @override
  ThreeDotsState createState() => ThreeDotsState();
}

class ThreeDotsState extends State<ThreeDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAnimatedDot(delay: 0.0),
        SizedBox(width: widget.size ?? 6),
        _buildAnimatedDot(delay: 0.2),
        SizedBox(width: widget.size ?? 6),
        _buildAnimatedDot(delay: 0.4),
      ],
    );
  }

  Widget _buildAnimatedDot({required double delay}) {
    final double dotSize = widget.size ?? 8;
    final Color dotColor = widget.color ?? Colors.grey.shade600;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double animationValue = _animationController.value;
        final double delayedValue = (animationValue - delay).clamp(0.0, 1.0);

        // Create bounce effect
        double scale = 1.0;
        double offsetY = 0.0;

        if (delayedValue > 0 && delayedValue < 1) {
          // Sine wave for smooth bounce
          final double bounce = (1 - (delayedValue * 2 - 1).abs());
          scale = 1.0 + (bounce * 0.3);
          offsetY = -bounce * 8;
        }

        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

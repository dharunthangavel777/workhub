import 'package:flutter/material.dart';
import 'dart:math' as math;

class AIModeButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isActive;

  const AIModeButton({
    Key? key,
    this.onTap,
    this.isActive = true,
  }) : super(key: key);

  @override
  State<AIModeButton> createState() => _AIModeButtonState();
}

class _AIModeButtonState extends State<AIModeButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    // Controller for the slow gradient rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // Controller for the tap scale effect
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) => _scaleController.reverse();
  void _handleTapUp(TapUpDetails details) => _scaleController.forward();
  void _handleTapCancel() => _scaleController.forward();

  @override
  Widget build(BuildContext context) {
    const double borderRadiusValue = 16.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleController,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadiusValue),
            // Layer 1: Outer Soft Container (Background Shell)
            color: const Color(0xFFF6F7FA),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(
                3.0), // Reduced outer padding to allow more space for border
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadiusValue - 2),
                // Layer 2: Inner Button Surface
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadiusValue - 2),
                child: CustomPaint(
                  // Layer 3: Gradient Stroke Border - Increased strokeWidth
                  painter: GradientBorderPainter(
                    animation: _rotationController,
                    strokeWidth: 2.5, // Increased from 2.0
                    isActive: widget.isActive,
                    radius: borderRadiusValue - 2,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon Design
                        const Icon(
                          Icons.auto_awesome, // Wand/Spark icon
                          color: Color(0xFF4A4A4A),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        // Text Style
                        const Text(
                          "AI Match",
                          style: TextStyle(
                            color: Color(0xFF3C3C3C),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter to handle the animated gradient stroke
class GradientBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final double strokeWidth;
  final bool isActive;
  final double radius;

  GradientBorderPainter({
    required this.animation,
    required this.strokeWidth,
    required this.isActive,
    required this.radius,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Inset the rect by half the stroke width to ensure it paints within bounds
    final rect = Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);

    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius - strokeWidth / 2),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isActive) {
      // Sweep gradient for the "Active" animated feel
      paint.shader = SweepGradient(
        transform: GradientRotation(animation.value * 2 * math.pi),
        colors: const [
          Color(0xFF5B8CFF), // Blue
          Color(0xFF8E7BFF), // Violet
          Color(0xFFFF8A65), // Orange
          Color(0xFFFFD54F), // Yellow
          Color(0xFF4DD0A6), // Green
          Color(0xFF5B8CFF), // Loop back to Blue
        ],
        stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      ).createShader(Offset.zero & size);
    } else {
      paint.color = Colors.grey.withOpacity(0.2);
    }

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GradientBorderPainter oldDelegate) {
    return oldDelegate.isActive != isActive ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

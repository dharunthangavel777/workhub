import 'package:flutter/material.dart';

class PredictiveShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? margin;

  final Color? baseColor;
  final Color? highlightColor;

  const PredictiveShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.margin,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<PredictiveShimmer> createState() => _PredictiveShimmerState();
}

class _PredictiveShimmerState extends State<PredictiveShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = widget.baseColor ??
        (isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB));
    final highlightColor = widget.highlightColor ??
        (isDark ? const Color(0xFF323232) : const Color(0xFFF3F4F6));

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseColor,
                  highlightColor,
                  baseColor,
                ],
                stops: [
                  0.0,
                  _animation.value < 0
                      ? 0.0
                      : (_animation.value > 1 ? 1.0 : _animation.value),
                  1.0,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}




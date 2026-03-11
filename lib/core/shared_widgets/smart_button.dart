import 'package:flutter/material.dart';
import '../design_system/tokens.dart';

enum SmartButtonState { idle, loading, success, error }

class SmartButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final SmartButtonState state;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Widget? icon;

  const SmartButton({
    super.key,
    required this.text,
    this.onPressed,
    this.state = SmartButtonState.idle,
    this.width,
    this.height,
    this.backgroundColor,
    this.icon,
  });

  @override
  State<SmartButton> createState() => _SmartButtonState();
}

class _SmartButtonState extends State<SmartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTokens.durationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      AppTokens.hapticSelection();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.state == SmartButtonState.idle ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppTokens.durationMedium,
          curve: AppTokens.curveStandard,
          width: widget.width ?? double.infinity,
          height: widget.height ?? 56,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? theme.primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.state == SmartButtonState.idle
                ? (isDark ? AppTokens.elevationMedium : AppTokens.elevationLow)
                : [],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: AppTokens.durationFast,
              child: _buildContent(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (widget.state) {
      case SmartButtonState.loading:
        return const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case SmartButtonState.success:
        AppTokens.hapticSuccess();
        return const Icon(Icons.check_circle_outline,
            color: Colors.white, key: ValueKey('success'));
      case SmartButtonState.error:
        AppTokens.hapticError();
        return const Icon(Icons.error_outline,
            color: Colors.white, key: ValueKey('error'));
      case SmartButtonState.idle:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              widget.icon!,
              const SizedBox(width: 8),
            ],
            Text(
              widget.text,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
    }
  }
}




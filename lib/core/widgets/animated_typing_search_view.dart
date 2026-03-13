import 'dart:async';
import 'package:work_hub/core/config/app_export.dart';

class AnimatedTypingSearchView extends StatefulWidget {
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? hintColor;
  final bool showShadow;

  const AnimatedTypingSearchView({
    super.key,
    this.onChanged,
    this.controller,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.textColor,
    this.hintColor,
    this.showShadow = true,
  });

  @override
  State<AnimatedTypingSearchView> createState() =>
      _AnimatedTypingSearchViewState();
}

class _AnimatedTypingSearchViewState extends State<AnimatedTypingSearchView> {
  final List<String> _phrases = [
    'Search "App Developer"',
    'Search "Graphic Designer"',
    'Search "Digital Marketer"',
    'Search "Web Developer"',
    'Search "UI/UX Designer"',
  ];

  late String _currentHint;
  int _phraseIndex = 0;
  int _charIndex = 0;
  bool _isDeleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentHint = "";
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    const typeSpeed = Duration(milliseconds: 150);
    const deleteSpeed = Duration(milliseconds: 50);
    const pauseEndOfPhrase = Duration(seconds: 2);
    const pauseStartOfPhrase = Duration(milliseconds: 500);

    void tick() {
      if (!mounted) return;

      final currentPhrase = _phrases[_phraseIndex];

      setState(() {
        if (_isDeleting) {
          _charIndex--;
        } else {
          _charIndex++;
        }

        _currentHint = currentPhrase.substring(0, _charIndex);
      });

      Duration nextDuration = _isDeleting ? deleteSpeed : typeSpeed;

      if (!_isDeleting && _charIndex == currentPhrase.length) {
        _isDeleting = true;
        nextDuration = pauseEndOfPhrase;
      } else if (_isDeleting && _charIndex == 0) {
        _isDeleting = false;
        _phraseIndex = (_phraseIndex + 1) % _phrases.length;
        nextDuration = pauseStartOfPhrase;
      }

      _timer = Timer(nextDuration, tick);
    }

    _timer = Timer(typeSpeed, tick);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      height: 54.h,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? CustomColors.lightCard,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(
          color: widget.borderColor ?? appTheme.indigo_A700.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: widget.iconColor ?? Colors.white,
            size: 24.h,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              onTap: widget.onTap,
              cursorColor: widget.textColor ?? appTheme.indigo_A700,
              style: TextStyle(
                color: widget.textColor ?? appTheme.black_900,
                fontSize: 16.fSize,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: _currentHint,
                hintStyle: TextStyle(
                  color: widget.hintColor ?? appTheme.gray_400,
                  fontSize: 14.fSize,
                  fontFamily: 'Poppins',
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                suffixIcon: widget.controller != null
                    ? ValueListenableBuilder<TextEditingValue>(
                        valueListenable: widget.controller!,
                        builder: (context, value, child) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: Icon(Icons.close,
                                size: 20.h, color: widget.hintColor ?? appTheme.gray_400),
                            onPressed: () {
                              widget.controller!.clear();
                              widget.onChanged?.call("");
                            },
                          );
                        },
                      )
                    : null,
                suffixIconConstraints: BoxConstraints(
                  maxHeight: 40.h,
                  maxWidth: 40.h,
                ),
              ),
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
        ],
      ),
    );
  }
}

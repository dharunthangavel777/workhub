import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ReelPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;

  final bool isActive;

  const ReelPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    required this.isActive,
  });

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;

  bool _isMuted = true;
  bool _showMuteIcon = false;
  Timer? _muteIconTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      _controller = VideoPlayerController.file(file);

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _initialized = true;
          _controller!.setLooping(true);
          _controller!.setVolume(_isMuted ? 0 : 1);
          if (widget.autoPlay && widget.isActive) {
            _controller!.play();
          }
        });
      }
    } catch (e) {
      debugPrint("Error initializing video: $e");
      if (mounted) {
        setState(() {
          _error = true;
        });
      }
    }
  }

  bool _isLongPressPaused = false;

  void toggleMute() {
    if (_controller == null) return;
    _muteIconTimer?.cancel();
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0 : 1);
      _showMuteIcon = true;
    });
    _muteIconTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showMuteIcon = false;
        });
      }
    });
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (_controller == null || !_initialized) return;
    setState(() {
      _isLongPressPaused = true;
      _controller!.pause();
    });
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (_controller == null || !_initialized) return;
    setState(() {
      _isLongPressPaused = false;
      _controller!.play();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _muteIconTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_initialized) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller!.pause();
    } else if (state == AppLifecycleState.resumed &&
        widget.isActive &&
        !_isLongPressPaused) {
      _controller!.play();
    }
  }

  @override
  void didUpdateWidget(ReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        if (_initialized && !_isLongPressPaused) _controller?.play();
      } else {
        _controller?.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.8) {
          if (_initialized && !_isLongPressPaused) _controller?.play();
        } else {
          if (_initialized) _controller?.pause();
        }
      },
      child: GestureDetector(
        onTap: toggleMute,
        onLongPressStart: _handleLongPressStart,
        onLongPressEnd: _handleLongPressEnd,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: _error
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.white54, size: 42),
                        SizedBox(height: 8),
                        Text("Could not load video",
                            style: TextStyle(color: Colors.white54)),
                      ],
                    )
                  : _initialized && _controller != null
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : const CircularProgressIndicator(color: Colors.white),
            ),
            if (_initialized)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: (_showMuteIcon || _isLongPressPaused) ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isLongPressPaused
                        ? Icons.pause
                        : (_isMuted ? Icons.volume_off : Icons.volume_up),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

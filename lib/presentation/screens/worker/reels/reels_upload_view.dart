import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../logic/providers/reel_provider.dart';
import '../../../../logic/providers/auth_provider.dart';
import '../../../../core/theme/custom_colors.dart';

class ReelsUploadView extends StatefulWidget {
  final VoidCallback onUploadComplete;
  const ReelsUploadView({super.key, required this.onUploadComplete});

  @override
  State<ReelsUploadView> createState() => _ReelsUploadViewState();
}

class _ReelsUploadViewState extends State<ReelsUploadView> {
  File? _videoFile;
  final _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  final _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        _videoController = VideoPlayerController.file(_videoFile!)
          ..initialize().then((_) {
            setState(() {});
            _videoController?.play();
            _videoController?.setLooping(true);
          });
      });
    }
  }

  Future<void> _upload() async {
    if (_videoFile == null) return;

    final auth = context.read<AuthProvider>();
    if (auth.userModel == null) return;

    final success = await context.read<ReelProvider>().uploadReel(
          _videoFile!,
          _captionController.text,
          auth.userModel!,
        );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reel uploaded successfully!")),
      );
      widget.onUploadComplete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload reel.")),
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ReelProvider>().isLoading;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_videoFile == null)
                Column(
                  children: [
                    const Icon(Icons.video_library_outlined,
                        size: 80, color: Colors.white54),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      child: const Text("Select Video",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Container(
                      height: 400,
                      width: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white10,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _videoController?.value.isInitialized ?? false
                            ? AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _captionController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter caption...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => setState(() {
                            _videoFile = null;
                            _videoController?.dispose();
                            _videoController = null;
                          }),
                          child: const Text("Change Video",
                              style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: isLoading ? null : _upload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CustomColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text("Upload Reel",
                                  style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

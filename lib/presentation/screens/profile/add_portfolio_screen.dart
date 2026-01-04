import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../logic/providers/auth_provider.dart';

class AddPortfolioScreen extends StatefulWidget {
  const AddPortfolioScreen({super.key});

  @override
  State<AddPortfolioScreen> createState() => _AddPortfolioScreenState();
}

class _AddPortfolioScreenState extends State<AddPortfolioScreen> {
  final _titleController = TextEditingController();
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.lightBg,
      appBar: AppBar(title: const Text("Add to Portfolio")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CustomColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  border:
                      Border.all(color: Colors.black.withValues(alpha: 0.1)),
                ),
                child: _imageFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: CustomColors.textMuted,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tap to upload project image",
                            style: TextStyle(color: CustomColors.textMuted),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Project Title",
                hintText: "e.g. E-commerce App Redesign",
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () async {
                        if (_titleController.text.isEmpty ||
                            _imageFile == null) {
                          // Optionally show a snackbar or toast for validation
                          return;
                        }

                        setState(() => _isUploading = true);
                        final auth = context.read<AuthProvider>();
                        await auth.addPortfolioItem(
                          _titleController.text,
                          _imageFile!,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add to Portfolio"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

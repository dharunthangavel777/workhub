import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../data/models/carousel_slide_model.dart';
import '../../../data/repositories/carousel_repository.dart';

class AdminCarouselScreen extends StatefulWidget {
  const AdminCarouselScreen({Key? key}) : super(key: key);

  @override
  State<AdminCarouselScreen> createState() => _AdminCarouselScreenState();
}

class _AdminCarouselScreenState extends State<AdminCarouselScreen> {
  final CarouselRepository _repository = CarouselRepository();
  List<CarouselSlideModel> _slides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSlides();
  }

  Future<void> _fetchSlides() async {
    try {
      final slides = await _repository.fetchAllSlidesAdmin();
      if (mounted) {
        setState(() {
          _slides = slides;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching slides: $e")),
        );
      }
    }
  }

  Future<void> _deleteSlide(String id) async {
    try {
      await _repository.deleteSlide(id);
      _fetchSlides();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Slide deleted")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting slide: $e")),
        );
      }
    }
  }

  void _showSlideDialog({CarouselSlideModel? slide}) {
    showDialog(
      context: context,
      builder: (context) => _SlideDialog(
        slide: slide,
        onSave: (newSlide) async {
          try {
            if (slide == null) {
              await _repository.addSlide(newSlide);
            } else {
              // For update, we might want a specific update method or just use the same insert if handling ID properly
              // Since repository has updateSlide taking map, let's use that for existing
              await _repository.updateSlide(
                  slide.id, newSlide.toJson()..remove('id'));
            }
            _fetchSlides();
            Navigator.pop(context);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error saving slide: $e")),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.gray_50,
      appBar: AppBar(
        title: Text(
          "Manage Carousel",
          style: TextStyleHelper.instance.headline24Bold.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _slides.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          slide.imageUrl,
                          height: 60,
                          width: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 60,
                            width: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Order: ${slide.orderIndex}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${slide.navType}: ${slide.navUrl}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                            Text(
                              slide.isActive ? "Active" : "Inactive",
                              style: TextStyle(
                                  color: slide.isActive
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showSlideDialog(slide: slide),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSlide(slide.id),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSlideDialog(),
        backgroundColor: appTheme.indigo_A700,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SlideDialog extends StatefulWidget {
  final CarouselSlideModel? slide;
  final Function(CarouselSlideModel) onSave;

  const _SlideDialog({Key? key, this.slide, required this.onSave})
      : super(key: key);

  @override
  State<_SlideDialog> createState() => _SlideDialogState();
}

class _SlideDialogState extends State<_SlideDialog> {
  late TextEditingController _imageController;
  late TextEditingController _navUrlController;
  late TextEditingController _orderController;
  String _navType = 'internal';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _imageController =
        TextEditingController(text: widget.slide?.imageUrl ?? '');
    _navUrlController = TextEditingController(text: widget.slide?.navUrl ?? '');
    _orderController =
        TextEditingController(text: widget.slide?.orderIndex.toString() ?? '0');
    _navType = widget.slide?.navType ?? 'internal';
    _isActive = widget.slide?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.slide == null ? "Add Slide" : "Edit Slide"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: "Image URL"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _navType,
              items: const [
                DropdownMenuItem(
                    value: 'internal', child: Text("Internal Route")),
                DropdownMenuItem(
                    value: 'external', child: Text("External URL")),
              ],
              onChanged: (val) => setState(() => _navType = val!),
              decoration: const InputDecoration(labelText: "Navigation Type"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _navUrlController,
              decoration:
                  const InputDecoration(labelText: "Navigation URL / Route"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orderController,
              decoration: const InputDecoration(labelText: "Order Index"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text("Active"),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final newSlide = CarouselSlideModel(
              id: widget.slide?.id ?? '', // ID handled by DB for inserts
              imageUrl: _imageController.text,
              navType: _navType,
              navUrl: _navUrlController.text,
              orderIndex: int.tryParse(_orderController.text) ?? 0,
              isActive: _isActive,
            );
            widget.onSave(newSlide);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

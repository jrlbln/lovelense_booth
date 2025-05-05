import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovelense_booth/screens/share_screen.dart';
import 'package:lovelense_booth/services/gdrive_service.dart';
import 'package:lovelense_booth/widgets/sticker_panel.dart';
import 'package:lovelense_booth/services/photo_editor.dart';
import 'package:lovelense_booth/providers/photo_booth_provider.dart';

class EditScreen extends ConsumerStatefulWidget {
  final List<String> photos;
  final int frameCount;

  const EditScreen({super.key, required this.photos, required this.frameCount});

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  bool isSaving = false;
  final GlobalKey _photoCanvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final couple = ref.watch(coupleInfoProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Row(
        children: [
          // Left side - Sticker Panel
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            child: StickerPanel(
              onStickerSelected: (sticker) {
                ref.read(photoEditorProvider).addSticker(sticker);
              },
              onTextStickerRequested: () {
                _showTextStickerDialog();
              },
            ),
          ),

          // Right side - Photo Canvas and Controls
          Expanded(
            child: Column(
              children: [
                // Photo Canvas Area
                Expanded(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          children: [
                            // Couple names header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              color: Colors.white,
                              child: Text(
                                '${couple.name1} & ${couple.name2}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Photo grid
                            Expanded(
                              child: RepaintBoundary(
                                key: _photoCanvasKey,
                                child: _buildPhotoGrid(
                                  widget.frameCount,
                                  widget.photos,
                                ),
                              ),
                            ),

                            // Event date footer
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.white,
                              child: Text(
                                couple.eventDate,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Save button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child:
                        isSaving
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            )
                            : const Text(
                              'SAVE',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(int frameCount, List<String> photos) {
    // This would be connected to the photo editor service
    // which manages stickers, text, etc.
    switch (frameCount) {
      case 3:
        return Column(
          children: [
            Expanded(child: _buildPhotoFrame(photos[0])),
            const SizedBox(height: 4),
            Expanded(child: _buildPhotoFrame(photos[1])),
            const SizedBox(height: 4),
            Expanded(child: _buildPhotoFrame(photos[2])),
          ],
        );
      case 4:
        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          padding: const EdgeInsets.all(4),
          children: [
            _buildPhotoFrame(photos[0]),
            _buildPhotoFrame(photos[1]),
            _buildPhotoFrame(photos[2]),
            _buildPhotoFrame(photos[3]),
          ],
        );
      case 5:
        return Column(
          children: [
            Expanded(flex: 2, child: _buildPhotoFrame(photos[0])),
            const SizedBox(height: 4),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(child: _buildPhotoFrame(photos[1])),
                  const SizedBox(width: 4),
                  Expanded(child: _buildPhotoFrame(photos[2])),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(child: _buildPhotoFrame(photos[3])),
                  const SizedBox(width: 4),
                  Expanded(child: _buildPhotoFrame(photos[4])),
                ],
              ),
            ),
          ],
        );
      default:
        return Container(); // Should never reach here
    }
  }

  Widget _buildPhotoFrame(String photoPath) {
    // In a real implementation, this would load the image from the photoPath
    // For now, we'll use a placeholder
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey),
      ),
    );
  }

  void _showTextStickerDialog() {
    String text = '';
    Color color = Colors.black;
    double fontSize = 24;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Add Text Sticker'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Text',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    text = value;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Font Size:'),
                    Expanded(
                      child: Slider(
                        value: fontSize,
                        min: 12,
                        max: 48,
                        divisions: 12,
                        label: fontSize.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            fontSize = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                // Color picker would go here
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  if (text.isNotEmpty) {
                    ref
                        .read(photoEditorProvider)
                        .addTextSticker(
                          text: text,
                          fontSize: fontSize,
                          color: color,
                        );
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('ADD'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveAndContinue() async {
    setState(() {
      isSaving = true;
    });

    try {
      // Capture the canvas as an image
      final editedImage = await ref
          .read(photoEditorProvider)
          .captureCanvas(_photoCanvasKey);

      // Upload to Google Drive
      final imageUrl = await ref
          .read(gdriveServiceProvider)
          .uploadImage(editedImage);

      // Navigate to share screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ShareScreen(imageUrl: imageUrl),
          ),
        );
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving photo: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }
}

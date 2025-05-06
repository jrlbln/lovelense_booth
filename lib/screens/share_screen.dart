import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareScreen extends ConsumerStatefulWidget {
  final String imageUrl;
  final List<String> capturedPhotos;

  const ShareScreen({
    Key? key,
    required this.imageUrl,
    this.capturedPhotos = const [],
  }) : super(key: key);

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  bool _saving = false;
  String? _saveMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Share Your Photos'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the combined photo composition
            Expanded(
              child: widget.capturedPhotos.isNotEmpty
                  ? _buildPhotoComposition()
                  : Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'Error loading image',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
            ),

            // Share buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Status message for save actions
                  if (_saveMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _saveMessage!,
                        style: TextStyle(
                          color: _saveMessage!.contains('Error')
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Save to Gallery button
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _saveToGallery,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_alt),
                        label: const Text(
                          'Save to Gallery',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      // Share button
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _sharePhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text(
                          'Share',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoComposition() {
    // This is a simplified version - you'll need to implement
    // the actual layout based on the frame count
    if (widget.capturedPhotos.isEmpty) {
      return const Center(
        child: Text(
          'No photos captured',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // For now, just show the first photo if we have any
    return Image.file(
      File(widget.capturedPhotos.first),
      fit: BoxFit.contain,
    );

    // TODO: Implement the proper layout based on the number of photos,
    // similar to how you've done it in the CameraScreen
  }

  Future<void> _saveToGallery() async {
    try {
      setState(() {
        _saving = true;
        _saveMessage = null;
      });

      // If we have captured photos, save them all
      if (widget.capturedPhotos.isNotEmpty) {
        for (final photoPath in widget.capturedPhotos) {
          final result = await ImageGallerySaver.saveFile(photoPath);
          print('Save result: $result');
        }

        setState(() {
          _saveMessage = 'Photos saved to gallery successfully!';
        });
      } else if (widget.imageUrl.isNotEmpty) {
        // If we have an image URL, download and save
        // This is a placeholder - in a real app, you'd need to download the image first
        setState(() {
          _saveMessage = 'Error: No local image to save';
        });
      } else {
        setState(() {
          _saveMessage = 'Error: No image available to save';
        });
      }
    } catch (e) {
      setState(() {
        _saveMessage = 'Error saving photos: ${e.toString()}';
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _sharePhoto() async {
    try {
      if (widget.capturedPhotos.isEmpty) {
        setState(() {
          _saveMessage = 'Error: No photos to share';
        });
        return;
      }

      // Create temporary directory for sharing
      // final tempDir = await getTemporaryDirectory();
      final shareFiles = <XFile>[];

      // Add all captured photos to the share list
      for (final photoPath in widget.capturedPhotos) {
        shareFiles.add(XFile(photoPath));
      }

      // Share the photos
      await Share.shareXFiles(
        shareFiles,
        text: 'Check out my photos from LoveLense Booth!',
      );
    } catch (e) {
      setState(() {
        _saveMessage = 'Error sharing photos: ${e.toString()}';
      });
    }
  }
}

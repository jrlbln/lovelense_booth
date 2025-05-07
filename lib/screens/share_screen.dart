import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:lovelense_booth/widgets/frame_util.dart';
import 'dart:html' as html;

class ShareScreen extends ConsumerStatefulWidget {
  final String imageUrl;
  final List<String> capturedPhotos;
  final String frameImagePath;
  final int frameCount;

  const ShareScreen({
    Key? key,
    required this.imageUrl,
    this.capturedPhotos = const [],
    required this.frameImagePath,
    required this.frameCount,
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
      // Remove AppBar, use gradient background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF61ECD9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Centered framed photo
              Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 600, // Increased to accommodate header/footer
                    maxHeight: 800, // Increased to accommodate header/footer
                  ),
                  child: AspectRatio(
                    aspectRatio: 3 / 4, // Adjusted for header and footer
                    child: _buildFrameImage(),
                  ),
                ),
              ),
              const Spacer(flex: 1),
              // Status message
              if (_saveMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _saveMessage!,
                    style: TextStyle(
                      color: _saveMessage!.contains('Error')
                          ? Colors.red
                          : Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ),
              // Buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _navigateToStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 40),
                  ElevatedButton(
                    onPressed: _saving ? null : _saveToGallery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrameImage() {
    // Handle web or mobile frame display
    if (widget.frameImagePath.startsWith('memory://')) {
      // Web: get the bytes from the provider
      final frameBytes =
          ref.read(frameImageBytesProvider)[widget.frameImagePath];
      if (frameBytes != null) {
        return Container(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              frameBytes,
              fit: BoxFit.contain,
            ),
          ),
        );
      }
    } else if (widget.frameImagePath.isNotEmpty) {
      // Mobile: display from file
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(widget.frameImagePath),
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Fallback if the frame isn't available
    return const Center(
      child: Text(
        'No frame image available',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _saveToGallery() async {
    try {
      setState(() {
        _saving = true;
        _saveMessage = null;
      });

      // Save the frame image
      if (widget.frameImagePath.isNotEmpty) {
        if (widget.frameImagePath.startsWith('memory://')) {
          // For web: Implement download functionality
          final frameBytes =
              ref.read(frameImageBytesProvider)[widget.frameImagePath];
          if (frameBytes != null) {
            // Create a blob from the bytes
            final blob = html.Blob([frameBytes]);
            final url = html.Url.createObjectUrlFromBlob(blob);

            // Create an anchor element and trigger download
            // ignore: unused_local_variable
            final anchor = html.AnchorElement(href: url)
              ..setAttribute('download',
                  'lovelense_${DateTime.now().millisecondsSinceEpoch}.png')
              ..click();

            // Clean up
            html.Url.revokeObjectUrl(url);

            setState(() {
              _saveMessage = 'Photo download started!';
            });

            // Navigate back to start screen after a delay
            Future.delayed(const Duration(seconds: 2), _navigateToStart);
          } else {
            setState(() {
              _saveMessage = 'Error: Could not find image data';
            });
          }
        } else {
          // For mobile, save to gallery
          final result =
              await ImageGallerySaver.saveFile(widget.frameImagePath);
          print('Save result: $result');
          setState(() {
            _saveMessage = 'Photo saved to gallery successfully!';
          });

          // Navigate back to start screen after a delay
          Future.delayed(const Duration(seconds: 2), _navigateToStart);
        }
      } else {
        setState(() {
          _saveMessage = 'Error: No frame image to save';
        });
      }
    } catch (e) {
      setState(() {
        _saveMessage = 'Error saving photo: ${e.toString()}';
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  void _navigateToStart() {
    // Navigate back to the start screen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

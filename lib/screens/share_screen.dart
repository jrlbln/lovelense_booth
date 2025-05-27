import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:lovelense_booth/widgets/frame_util.dart';
import 'dart:html' as html;

class ShareScreen extends ConsumerStatefulWidget {
  final String frameImagePath;

  const ShareScreen({
    Key? key,
    required this.frameImagePath,
  }) : super(key: key);

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

              // Display the captured frame
              Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                    maxHeight: 800,
                  ),
                  child: _buildFrameImage(),
                ),
              ),

              const Spacer(flex: 1),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _navigateBackToCamera,
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
                    onPressed: _saving ? null : _downloadImage,
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
                        : const Text('Download'),
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
    if (widget.frameImagePath.startsWith('memory://')) {
      // Web: get the bytes from the provider
      final frameBytes =
          ref.read(frameImageBytesProvider)[widget.frameImagePath];
      if (frameBytes != null) {
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

  Future<void> _downloadImage() async {
    try {
      setState(() {
        _saving = true;
      });

      if (kIsWeb) {
        // Web: Download the image
        if (widget.frameImagePath.startsWith('memory://')) {
          final frameBytes =
              ref.read(frameImageBytesProvider)[widget.frameImagePath];
          if (frameBytes != null) {
            await _downloadForWeb(frameBytes);
          }
        }
      } else {
        // Mobile: Save to gallery
        await ImageGallerySaver.saveFile(widget.frameImagePath);
      }

      // Show success dialog for 2 seconds before navigating
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Photo Downloaded Successfully',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Wait for 2 seconds
        await Future.delayed(const Duration(seconds: 2));

        // Close the dialog and navigate back to start screen
        if (mounted) {
          Navigator.of(context).pop(); // Close the success dialog
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      print('Download error: $e');
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _downloadForWeb(List<int> bytes) async {
    try {
      // Create blob with correct MIME type
      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create download link
      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download =
            'lovelense_frame_${DateTime.now().millisecondsSinceEpoch}.png';

      // Add to DOM, click, and remove
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);

      // Clean up the URL
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Web download error: $e');
      rethrow;
    }
  }

  void _navigateBackToCamera() {
    // Go back to the camera screen
    Navigator.of(context).pop();
  }
}

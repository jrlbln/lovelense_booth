import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:lovelense_booth/services/gdrive_service.dart';
import 'package:lovelense_booth/widgets/frame_util.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isUploading = false;
  String? _uploadUrl;
  bool _showEmailPrompt = false;

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
            // Display the frame image
            Expanded(
              child: _buildFrameImage(),
            ),

            // Status and action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Status message
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

                      // Upload to Google Drive button
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadToDrive,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: const Text(
                          'Upload to Drive',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Email prompt if upload is complete
                  if (_showEmailPrompt)
                    Column(
                      children: [
                        const Text(
                          'Would you like to email this photo?',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _uploadUrl != null ? _sendEmail : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                          icon: const Icon(Icons.email),
                          label: const Text(
                            'Send Email',
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

  Widget _buildFrameImage() {
    // Handle web or mobile frame display
    if (widget.frameImagePath.startsWith('memory://')) {
      // Web: get the bytes from the provider
      final frameBytes =
          ref.read(frameImageBytesProvider)[widget.frameImagePath];
      if (frameBytes != null) {
        return Image.memory(
          frameBytes,
          fit: BoxFit.contain,
        );
      }
    } else if (widget.frameImagePath.isNotEmpty) {
      // Mobile: display from file
      return Image.file(
        File(widget.frameImagePath),
        fit: BoxFit.contain,
      );
    }

    // Fallback to displaying just the first photo if the frame isn't available
    if (widget.capturedPhotos.isNotEmpty) {
      return Image.file(
        File(widget.capturedPhotos.first),
        fit: BoxFit.contain,
      );
    }

    return const Center(
      child: Text(
        'No frame image available',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  // Existing _saveToGallery method with modification to save the frame
  Future<void> _saveToGallery() async {
    try {
      setState(() {
        _saving = true;
        _saveMessage = null;
      });

      // Save the frame image instead of individual photos
      if (widget.frameImagePath.isNotEmpty) {
        if (widget.frameImagePath.startsWith('memory://')) {
          // For web, we need to handle this differently since we can't directly save to gallery
          setState(() {
            _saveMessage =
                'On web, please use the download button in your browser';
          });
        } else {
          // For mobile, save to gallery
          final result =
              await ImageGallerySaver.saveFile(widget.frameImagePath);
          print('Save result: $result');
          setState(() {
            _saveMessage = 'Photo saved to gallery successfully!';
          });
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

  // Add Google Drive upload functionality
  Future<void> _uploadToDrive() async {
    try {
      setState(() {
        _isUploading = true;
        _saveMessage = 'Uploading to Google Drive...';
      });

      // Get the Google Drive service
      final driveService = ref.read(googleDriveServiceProvider);

      // Upload the frame image
      if (widget.frameImagePath.startsWith('memory://')) {
        // For web
        final frameBytes =
            ref.read(frameImageBytesProvider)[widget.frameImagePath];
        if (frameBytes != null) {
          // For web, we need to temporarily save the bytes to a file
          final tempFile = await _saveBytesToTempFile(frameBytes);
          _uploadUrl = await driveService.uploadImage(tempFile);
        }
      } else if (widget.frameImagePath.isNotEmpty) {
        // For mobile
        _uploadUrl = await driveService.uploadImage(widget.frameImagePath);
      }

      if (_uploadUrl != null) {
        setState(() {
          _saveMessage = 'Successfully uploaded to Google Drive!';
          _showEmailPrompt = true;
        });
      } else {
        setState(() {
          _saveMessage = 'Failed to upload to Google Drive';
        });
      }
    } catch (e) {
      setState(() {
        _saveMessage = 'Error uploading to Drive: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Helper method to save bytes to a temporary file for web
  Future<String> _saveBytesToTempFile(Uint8List bytes) async {
    if (kIsWeb) {
      // For web, we'll handle this differently (this is a placeholder)
      // In a real app, you might use a package like file_picker_web
      // For now, we'll just use a data URI
      return 'data:image/png;base64,${base64Encode(bytes)}';
    } else {
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/temp_frame_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    }
  }

  // Add email sending functionality
  void _sendEmail() {
    if (_uploadUrl == null) return;

    // Open email client with precomposed message
    const subject = 'My Photo from LoveLense Booth';
    final body = 'Check out my photo from LoveLense Booth!\n\n$_uploadUrl';
    final uri = Uri(
      scheme: 'mailto',
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    launchUrl(uri);

    setState(() {
      _saveMessage = 'Email client opened';
    });
  }
}

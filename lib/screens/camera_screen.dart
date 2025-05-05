import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovelense_booth/screens/edit_screen.dart';
import 'package:lovelense_booth/widgets/camera_preview.dart';
import 'package:lovelense_booth/widgets/frame_selector.dart';
import 'package:lovelense_booth/widgets/countdown_timer.dart';
import 'package:lovelense_booth/services/camera_service.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final int initialFrameCount;

  const CameraScreen({super.key, required this.initialFrameCount});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  late int selectedFrameCount;
  bool isCapturing = false;
  int currentCaptureIndex = 0;
  List<String> capturedPhotos = [];

  @override
  void initState() {
    super.initState();
    selectedFrameCount = widget.initialFrameCount;
    // Initialize camera
    Future.delayed(Duration.zero, () {
      ref.read(cameraServiceProvider).initializeCamera();
    });
  }

  @override
  void dispose() {
    // Dispose camera resources
    ref.read(cameraServiceProvider).disposeCamera();
    super.dispose();
  }

  void startCapturing() {
    setState(() {
      isCapturing = true;
      currentCaptureIndex = 0;
      capturedPhotos = [];
    });

    _captureNextPhoto();
  }

  void _captureNextPhoto() {
    if (currentCaptureIndex >= selectedFrameCount) {
      // All photos captured, proceed to edit screen
      setState(() {
        isCapturing = false;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => EditScreen(
                photos: capturedPhotos,
                frameCount: selectedFrameCount,
              ),
        ),
      );
      return;
    }

    // Show countdown and capture
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => CountdownTimer(
            onFinished: () async {
              // Capture photo
              final photoPath =
                  await ref.read(cameraServiceProvider).capturePhoto();

              setState(() {
                capturedPhotos.add(photoPath);
                currentCaptureIndex++;
              });

              Navigator.of(context).pop(); // Close countdown dialog

              // Small delay before next capture
              Future.delayed(const Duration(milliseconds: 500), () {
                _captureNextPhoto();
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left section: Camera preview
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: CameraPreviewWidget()),
              ),
            ),

            const SizedBox(width: 16),

            // Right section: Frame selection and start button
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Frame preview grid
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildFramePreview(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Frame selection buttons
                  FrameSelector(
                    selectedFrameCount: selectedFrameCount,
                    onFrameSelected: (frameCount) {
                      setState(() {
                        selectedFrameCount = frameCount;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Start button
                  ElevatedButton(
                    onPressed: isCapturing ? null : startCapturing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'START',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFramePreview() {
    switch (selectedFrameCount) {
      case 3:
        return Column(
          children: [
            Expanded(child: Container(color: Colors.grey.shade300)),
            const SizedBox(height: 4),
            Expanded(child: Container(color: Colors.grey.shade300)),
            const SizedBox(height: 4),
            Expanded(child: Container(color: Colors.grey.shade300)),
          ],
        );
      case 4:
        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: List.generate(
            4,
            (index) => Container(color: Colors.grey.shade300),
          ),
        );
      case 5:
        return Column(
          children: [
            Expanded(child: Container(color: Colors.grey.shade300)),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Container(color: Colors.grey.shade300)),
                  const SizedBox(width: 4),
                  Expanded(child: Container(color: Colors.grey.shade300)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Container(color: Colors.grey.shade300)),
                  const SizedBox(width: 4),
                  Expanded(child: Container(color: Colors.grey.shade300)),
                ],
              ),
            ),
          ],
        );
      default:
        return Container(); // Should never reach here
    }
  }
}

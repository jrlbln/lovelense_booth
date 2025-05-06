import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:lovelense_booth/screens/share_screen.dart';
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
  List<int> samplePhotoIndices = []; // Store randomly selected photo indices

  @override
  void initState() {
    super.initState();
    selectedFrameCount = widget.initialFrameCount;
    _randomizeSamplePhotos(); // Initialize with random sample photos

    // Initialize the camera after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    try {
      await ref.read(cameraServiceProvider).initializeCamera();
    } catch (e) {
      // Error is already handled in CameraService
      print('Camera initialization error caught in screen: $e');
    }
  }

  @override
  void dispose() {
    // Dispose camera resources
    ref.read(cameraServiceProvider).disposeCamera();
    super.dispose();
  }

  // Randomize sample photos whenever frame count changes
  void _randomizeSamplePhotos() {
    final random = Random();
    // Clear existing indices
    samplePhotoIndices = [];
    List<int> availableIndices = List.generate(6, (index) => index + 1);
    final photosToSelect = min(selectedFrameCount, availableIndices.length);

    for (int i = 0; i < photosToSelect; i++) {
      final randomPosition = random.nextInt(availableIndices.length);
      samplePhotoIndices.add(availableIndices[randomPosition]);
      availableIndices.removeAt(randomPosition);
    }

    if (selectedFrameCount > photosToSelect) {
      while (samplePhotoIndices.length < selectedFrameCount) {
        final randomIndex = random.nextInt(6) + 1; // 1 to 6
        samplePhotoIndices.add(randomIndex);
      }
    }
  }

  Future<void> startCapturing() async {
    // Check if camera is ready
    final cameraState = ref.read(cameraStateProvider);
    if (cameraState != CameraState.initialized) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Camera Not Ready'),
          content: const Text(
              'The camera is not ready to take photos. Please wait or try initializing the camera again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeCamera();
              },
              child: const Text('RETRY'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      isCapturing = true;
      currentCaptureIndex = 0;
      capturedPhotos = [];
    });

    _captureNextPhoto();
  }

  void _captureNextPhoto() {
    if (currentCaptureIndex >= selectedFrameCount) {
      // All photos captured, proceed to share screen
      setState(() {
        isCapturing = false;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ShareScreen(
            // Pass the captured photos to the share screen
            imageUrl: '',
            capturedPhotos: capturedPhotos,
          ),
        ),
      );
      return;
    }

    // Show countdown and capture
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CountdownTimer(
        onFinished: () async {
          try {
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
          } catch (e) {
            Navigator.of(context).pop(); // Close countdown dialog

            // Show error dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Capture Error'),
                content: Text('Failed to capture photo: ${e.toString()}'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        isCapturing = false;
                      });
                    },
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _captureNextPhoto(); // Try next photo
                    },
                    child: const Text('SKIP & CONTINUE'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch camera state to update UI if needed
    final cameraState = ref.watch(cameraStateProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF61ECD9)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Main content in two columns
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column - Camera preview
                      Expanded(
                        child: Column(
                          children: [
                            // Camera preview (square)
                            SizedBox(
                              width: 600, // Fixed width
                              height: 600, // Fixed height (square)
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const CameraPreviewWidget(),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Frame selector text
                            const Text(
                              'Select the number of Photos...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Frame selector buttons
                            FrameSelector(
                              selectedFrameCount: selectedFrameCount,
                              onFrameSelected: (frameCount) {
                                setState(() {
                                  selectedFrameCount = frameCount;
                                  _randomizeSamplePhotos(); // Randomize photos when frame count changes
                                });
                              },
                            ),

                            const SizedBox(height: 32),

                            // Start button
                            Align(
                              alignment: Alignment.center,
                              child: ElevatedButton(
                                onPressed: isCapturing ||
                                        cameraState != CameraState.initialized
                                    ? null
                                    : startCapturing,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  // Disabled style
                                  disabledBackgroundColor: Colors.grey.shade300,
                                ),
                                child: const Text(
                                  'START',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Right column - Frame preview - FIXED LAYOUT
                      Expanded(
                        child: Column(
                          children: [
                            // Frame preview (shows selected layout)
                            Expanded(
                              child: _buildFramePreview(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFramePreview() {
    // Fixed dimensions for each frame
    const double frameSize = 250.0; // Individual photo frame size
    const double framePadding = 12.0; // Padding between frames
    const double containerPadding = 16.0; // Padding inside the white container

    // Helper method to create a square frame preview box with sample image
    Widget buildFrameBox(int index) {
      // If we have a captured photo for this index, use it
      if (capturedPhotos.length > index) {
        return Container(
          width: frameSize,
          height: frameSize,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(capturedPhotos[index]),
              fit: BoxFit.cover,
            ),
          ),
        );
      }

      // Otherwise use a sample photo from our unique selection
      final photoIndex = index < samplePhotoIndices.length
          ? samplePhotoIndices[index]
          : 1; // Default to sample-1 if somehow we don't have an index

      return Container(
        width: frameSize,
        height: frameSize,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            'assets/images/sample-$photoIndex.png',
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Build frame layout based on selected count
    Widget buildFrameLayout() {
      switch (selectedFrameCount) {
        case 3:
          // 3 frames in a vertical column
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildFrameBox(0),
              const SizedBox(height: framePadding),
              buildFrameBox(1),
              const SizedBox(height: framePadding),
              buildFrameBox(2),
            ],
          );

        case 4:
          // 4 frames in a 2x2 grid
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildFrameBox(0),
                  const SizedBox(width: framePadding),
                  buildFrameBox(1),
                ],
              ),
              const SizedBox(height: framePadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildFrameBox(2),
                  const SizedBox(width: framePadding),
                  buildFrameBox(3),
                ],
              ),
            ],
          );

        case 6:
          // 6 frames in a 2x3 grid
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildFrameBox(0),
                  const SizedBox(width: framePadding),
                  buildFrameBox(1),
                ],
              ),
              const SizedBox(height: framePadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildFrameBox(2),
                  const SizedBox(width: framePadding),
                  buildFrameBox(3),
                ],
              ),
              const SizedBox(height: framePadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildFrameBox(4),
                  const SizedBox(width: framePadding),
                  buildFrameBox(5),
                ],
              ),
            ],
          );

        default:
          return Container(); // Should never reach here
      }
    }

    // Container with white background and consistent padding
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(containerPadding),
        child: buildFrameLayout(),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:lovelense_booth/screens/share_screen.dart';
import 'package:lovelense_booth/widgets/camera_preview.dart';
import 'package:lovelense_booth/widgets/frame_selector.dart';
import 'package:lovelense_booth/widgets/countdown_timer.dart';
import 'package:lovelense_booth/services/camera_service.dart';
import 'package:lovelense_booth/widgets/frame_util.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final int initialFrameCount;

  const CameraScreen({super.key, required this.initialFrameCount});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final GlobalKey frameKey = GlobalKey();
  late int selectedFrameCount;
  bool isCapturing = false;
  int currentCaptureIndex = 0;
  List<String> capturedPhotoPaths = []; // Store paths or URLs
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

    // Clear any previously captured photos
    ref.read(cameraServiceProvider).clearCapturedPhotos();

    setState(() {
      isCapturing = true;
      currentCaptureIndex = 0;
      capturedPhotoPaths = [];
    });

    _captureNextPhoto();
  }

  Future<void> _captureNextPhoto() async {
    if (currentCaptureIndex >= selectedFrameCount) {
      // All photos captured, capture the entire frame before proceeding
      setState(() {
        isCapturing = false;
      });

      // Delay to ensure UI is fully rendered
      await Future.delayed(const Duration(milliseconds: 300));

      // Capture the frame
      final frameBytes = await frameKey.captureAsPngBytes();
      final frameImagePath = await _saveFrameImage(frameBytes);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ShareScreen(
            imageUrl: '',
            capturedPhotos: capturedPhotoPaths,
            frameImagePath: frameImagePath,
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
      builder: (context) => CountdownTimer(
        onFinished: () async {
          try {
            // Capture photo
            final photoPathOrUrl =
                await ref.read(cameraServiceProvider).capturePhoto();

            setState(() {
              capturedPhotoPaths.add(photoPathOrUrl);
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

  Future<String> _saveFrameImage(Uint8List? bytes) async {
    if (bytes == null) return '';

    if (kIsWeb) {
      // For web: store the bytes in our provider
      final path =
          'memory://frame_${DateTime.now().millisecondsSinceEpoch}.png';
      ref.read(frameImageBytesProvider.notifier).update((state) => {
            ...state,
            path: bytes,
          });
      return path;
    } else {
      // For mobile: save to file
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/frame_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch camera state to update UI if needed
    final cameraState = ref.watch(cameraStateProvider);
    final capturedPhotos = ref.watch(capturedPhotosProvider);

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
                              'Select a Frame',
                              style: TextStyle(
                                fontSize: 18,
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
                        child: RepaintBoundary(
                          key: frameKey,
                          child: _buildFramePreview(capturedPhotos),
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

  Widget _buildFramePreview(List<CapturedPhoto> allCapturedPhotos) {
    // Fixed dimensions for each frame
    const double frameSize = 250.0; // Individual photo frame size
    const double framePadding = 12.0; // Padding between frames
    const double containerPadding = 16.0; // Padding inside the white container

    // Helper method to create a square frame preview box with sample image
    Widget buildFrameBox(int index) {
      // If we have a captured photo for this index, use it
      if (index < allCapturedPhotos.length) {
        final capturedPhoto = allCapturedPhotos[index];

        if (kIsWeb && capturedPhoto.webUrl != null) {
          // For web: Use webUrl to display the image
          return Container(
            width: frameSize,
            height: frameSize,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                capturedPhoto.webUrl!,
                fit: BoxFit.cover,
              ),
            ),
          );
        } else if (!kIsWeb) {
          // For mobile: Use file path
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
                File(capturedPhoto.path),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
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

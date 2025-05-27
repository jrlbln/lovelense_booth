import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovelense_booth/screens/share_screen.dart';
import 'package:lovelense_booth/services/camera_service.dart';
import 'package:lovelense_booth/widgets/camera_preview.dart';
import 'package:lovelense_booth/widgets/countdown_timer.dart';
import 'package:lovelense_booth/widgets/frame_selector.dart';
import 'package:lovelense_booth/widgets/frame_util.dart';
import 'package:lovelense_booth/main.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final int initialFrameCount;

  const CameraScreen({super.key, required this.initialFrameCount});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with RouteAware {
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
      if (mounted) {
        _initializeCamera();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    // Only unsubscribe from route changes
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    // Called when navigating to a new route
    if (mounted) {
      final cameraService = ref.read(cameraServiceProvider);
      cameraService.disposeCamera();
      cameraService.clearCapturedPhotos();
    }
  }

  @override
  void didPopNext() {
    // Called when returning to this route
    if (mounted) {
      _initializeCamera();
    }
  }

  @override
  void didPop() {
    // Called when this route is popped
    if (mounted) {
      final cameraService = ref.read(cameraServiceProvider);
      cameraService.disposeCamera();
      cameraService.clearCapturedPhotos();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await ref.read(cameraServiceProvider).initializeCamera();
    } catch (e) {
      // Error is already handled in CameraService
      print('Camera initialization error caught in screen: $e');
    }
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

      // Generate the frame image with header and footer
      final frameImagePath = await FrameUtil.generateFrameImage(
        ref.read(capturedPhotosProvider),
        selectedFrameCount,
        frameKey,
      );

      // For web: store the bytes in our provider if needed
      if (kIsWeb && frameImagePath.startsWith('memory://')) {
        final frameBytes = await frameKey.captureAsPngBytes();
        ref.read(frameImageBytesProvider.notifier).update((state) => {
              ...state,
              frameImagePath: frameBytes!,
            });
      }

      // Close the loading dialog
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (context.mounted) {
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
      }
      return;
    }

    // Show countdown and capture
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CountdownTimer(
        onFinished: () async {
          try {
            // Show loading dialog immediately after countdown
            if (context.mounted) {
              Navigator.of(context).pop(); // Close countdown dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing your photos...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Capture photo
            final photoPathOrUrl =
                await ref.read(cameraServiceProvider).capturePhoto();

            setState(() {
              capturedPhotoPaths.add(photoPathOrUrl);
              currentCaptureIndex++;
            });

            // Small delay before next capture
            Future.delayed(const Duration(milliseconds: 500), () {
              _captureNextPhoto();
            });
          } catch (e) {
            if (context.mounted) {
              Navigator.of(context).pop(); // Close loading dialog
            }

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
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Changed from .start to .center
                    children: [
                      // Left column - Camera preview
                      Expanded(
                        child: Center(
                          // Wrap the entire left column in Center
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center, // Center vertically
                            mainAxisSize:
                                MainAxisSize.min, // Take only needed space
                            children: [
                              // Camera preview (square)
                              SizedBox(
                                width: 500, // Fixed width
                                height: 500, // Fixed height (square)
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
                                disabled: isCapturing,
                              ),

                              const SizedBox(height: 32),

                              // Start button
                              ElevatedButton(
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
                            ],
                          ),
                        ),
                      ),

                      // Right column - Frame preview with FIXED DIMENSIONS
                      SizedBox(
                        width: 600,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left:
                                    0), // Change this value to move it right/left
                            child: _buildFramePreview(capturedPhotos),
                          ),
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
    // Calculate frame dimensions based on layout
    double frameWidth;
    double frameHeight;

    switch (selectedFrameCount) {
      case 3:
        frameWidth = 250.0; // Single column width
        frameHeight = 250.0 * 3 + 12.0 * 2; // 3 photos + 2 gaps
        break;
      case 4:
        frameWidth = 250.0 * 2 + 12.0; // 2 columns + 1 gap
        frameHeight = 250.0 * 2 + 12.0; // 2 rows + 1 gap
        break;
      case 6:
        frameWidth = 250.0 * 2 + 12.0; // 2 columns + 1 gap
        frameHeight = 250.0 * 3 + 12.0 * 2; // 3 rows + 2 gaps
        break;
      default:
        frameWidth = 250.0;
        frameHeight = 250.0;
    }

    // Fixed dimensions for each individual photo frame
    const double photoSize = 250.0; // Individual photo frame size
    const double framePadding = 8.0; // Padding between frames
    const double containerPadding = 12.0; // Padding inside the white container
    const double headerHeight = 60.0; // Height for header section
    const double footerHeight = 30.0; // Height for footer section

    // Total frame dimensions including header and footer
    final totalFrameWidth = frameWidth + (containerPadding * 2);
    final totalFrameHeight =
        frameHeight + (containerPadding * 2) + headerHeight + footerHeight;

    // Helper method to create a square frame preview box with sample image
    Widget buildFrameBox(int index) {
      // If we have a captured photo for this index, use it
      if (index < allCapturedPhotos.length) {
        final capturedPhoto = allCapturedPhotos[index];

        if (kIsWeb && capturedPhoto.webUrl != null) {
          // For web: Use webUrl to display the image
          return Container(
            width: photoSize,
            height: photoSize,
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
            width: photoSize,
            height: photoSize,
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
        width: photoSize,
        height: photoSize,
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

    // Build header section
    Widget buildHeader() {
      return Container(
        height: headerHeight,
        width: totalFrameWidth,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Jimuel & Jaybei',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'AlexBrush',
              ),
            ),
            SizedBox(height: 4),
            Text(
              '05/31/2025',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Build footer section
    Widget buildFooter() {
      return Container(
        height: footerHeight,
        width: totalFrameWidth,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'made with LoveLense',
              style: TextStyle(
                color: Colors.black,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // LoveLense icon
            Image.asset(
              'assets/images/LoveLenseIcon.png',
              width: 20,
              height: 20,
            ),
          ],
        ),
      );
    }

    // Place the RepaintBoundary around the complete frame with FIXED DIMENSIONS
    return RepaintBoundary(
      key: frameKey,
      child: SizedBox(
        width: totalFrameWidth,
        height: totalFrameHeight,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              buildHeader(),

              // Photo grid content
              Container(
                width: totalFrameWidth,
                padding: const EdgeInsets.all(containerPadding),
                child: buildFrameLayout(),
              ),

              // Footer
              buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

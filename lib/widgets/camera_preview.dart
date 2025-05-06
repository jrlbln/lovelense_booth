import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:lovelense_booth/services/camera_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CameraPreviewWidget extends ConsumerWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraController = ref.watch(cameraControllerProvider);
    final cameraState = ref.watch(cameraStateProvider);
    final errorMessage = ref.watch(cameraErrorProvider);

    // Build UI based on camera state
    switch (cameraState) {
      case CameraState.uninitialized:
        return _buildUninitializedView(context, ref);
      case CameraState.initializing:
        return _buildLoadingPreview();
      case CameraState.initialized:
        // Check if controller is actually initialized before using it
        if (cameraController != null && cameraController.value.isInitialized) {
          return _buildCameraPreview(context, cameraController);
        } else {
          // Fall back to loading view if controller isn't ready yet
          return _buildLoadingPreview();
        }
      case CameraState.permissionDenied:
        return _buildPermissionDeniedView(context, ref);
      case CameraState.error:
        return _buildErrorView(context, ref, errorMessage);
    }
  }

  Widget _buildCameraPreview(
      BuildContext context, CameraController controller) {
    // Guard clause to ensure controller is initialized
    if (!controller.value.isInitialized) {
      return _buildLoadingPreview();
    }

    // Get screen size for proper calculations
    final screenSize = MediaQuery.of(context).size;
    final screenRatio = screenSize.width / screenSize.height;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1.0, // Ensure the container is square
            child: Transform.scale(
              scale: kIsWeb
                  ? _getWebCameraScale(controller, screenRatio)
                  : _getMobileCameraScale(controller),
              alignment: Alignment.center,
              child: CameraPreview(controller),
            ),
          ),
        ),
      ),
    );
  }

  // Special scaling for web camera views
  double _getWebCameraScale(CameraController controller, double screenRatio) {
    // Get the camera's aspect ratio
    final cameraRatio = controller.value.aspectRatio;

    // For portrait orientation (height > width), we want to scale up to fill height
    if (cameraRatio < 1.0) {
      return 1.0 / cameraRatio; // Scale up to fill height
    }
    // For landscape orientation, we need to scale up to fill width
    else {
      return 1.0; // Scale to fit width
    }
  }

  // Mobile scaling calculation
  double _getMobileCameraScale(CameraController controller) {
    final cameraRatio = controller.value.aspectRatio;

    // For square containers, we want to fill the width or height depending on camera orientation
    if (cameraRatio > 1.0) {
      // Landscape camera - scale to fill height
      return 1.0;
    } else {
      // Portrait camera - scale to fill width
      return 1.0 / cameraRatio;
    }
  }

  Widget _buildLoadingPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Initializing camera...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildUninitializedView(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Camera not initialized',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(cameraServiceProvider).initializeCamera();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Initialize Camera',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Camera permission denied',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'We need camera access to take photos. Please allow camera access in your browser or device permissions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(
      BuildContext context, WidgetRef ref, String? errorMessage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                errorMessage ?? 'An unknown error occurred with the camera',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(cameraServiceProvider).initializeCamera();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

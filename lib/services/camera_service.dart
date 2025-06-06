import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:typed_data';

// Camera initialization state
enum CameraState {
  uninitialized,
  initializing,
  initialized,
  error,
  permissionDenied,
}

// Camera state provider
final cameraStateProvider = StateProvider<CameraState>((ref) {
  return CameraState.uninitialized;
});

// Error message provider
final cameraErrorProvider = StateProvider<String?>((ref) {
  return null;
});

// Camera controller provider
final cameraControllerProvider = StateProvider<CameraController?>((ref) {
  return null;
});

// Available cameras provider
final availableCamerasProvider =
    FutureProvider<List<CameraDescription>>((ref) async {
  try {
    return await availableCameras();
  } catch (e) {
    print('Error getting available cameras: $e');
    return [];
  }
});

// Provider to store captured photos
final capturedPhotosProvider = StateProvider<List<CapturedPhoto>>((ref) {
  return [];
});

// Class to store photo data for both web and mobile
class CapturedPhoto {
  final String path; // File path for mobile
  final Uint8List? webBytes; // Bytes for web
  final String? webUrl; // Object URL for web images

  CapturedPhoto({
    required this.path,
    this.webBytes,
    this.webUrl,
  });

  bool get isWeb => webBytes != null || webUrl != null;
}

// Camera service provider
final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService(ref);
});

class CameraService {
  final Ref _ref;

  CameraService(this._ref);

  Future<void> initializeCamera() async {
    try {
      // Reset any previous state
      _ref.read(cameraStateProvider.notifier).state = CameraState.initializing;
      _ref.read(cameraErrorProvider.notifier).state = null;

      // First handle permissions for web
      if (kIsWeb) {
        try {
          // Request camera permission using the browser's MediaDevices API
          await html.window.navigator.mediaDevices?.getUserMedia({
            'video': true,
            'audio': false,
          });
          print('Web camera permission granted');
        } catch (e) {
          print('Web camera permission error: $e');
          _ref.read(cameraStateProvider.notifier).state =
              CameraState.permissionDenied;
          _ref.read(cameraErrorProvider.notifier).state =
              'Camera permission denied. Please allow camera access in your browser settings.';
          return;
        }
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw 'No cameras available on this device';
      }

      // Choose the front camera if available (for a photobooth experience)
      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Create a new controller
      final controller = CameraController(
        selectedCamera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize the controller
      await controller.initialize();

      // Update the controller reference in the provider
      _ref.read(cameraControllerProvider.notifier).state = controller;

      // Important: Add a small delay for web to ensure the camera is properly connected
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Now that we're sure the controller is initialized, update the state
      _ref.read(cameraStateProvider.notifier).state = CameraState.initialized;
    } catch (e) {
      print('Error initializing camera: $e');

      // Check if the error is related to permissions
      if (e.toString().contains('permission') ||
          e.toString().contains('Permission')) {
        _ref.read(cameraStateProvider.notifier).state =
            CameraState.permissionDenied;
      } else {
        _ref.read(cameraStateProvider.notifier).state = CameraState.error;
      }

      _ref.read(cameraErrorProvider.notifier).state = e.toString();
    }
  }

  Future<String> capturePhoto() async {
    final controller = _ref.read(cameraControllerProvider);
    if (controller == null || !controller.value.isInitialized) {
      throw 'Camera not initialized';
    }

    try {
      final xFile = await controller.takePicture();

      if (kIsWeb) {
        // For Web: Read the bytes and create a URL
        final bytes = await xFile.readAsBytes();

        // Create a blob URL for the image
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Store the captured photo in our provider
        final capturedPhotos = _ref.read(capturedPhotosProvider.notifier);
        capturedPhotos.state = [
          ...capturedPhotos.state,
          CapturedPhoto(
            path: xFile.path,
            webBytes: bytes,
            webUrl: url,
          ),
        ];

        return url; // Return the URL for web
      } else {
        // For Mobile: Store the file path
        final capturedPhotos = _ref.read(capturedPhotosProvider.notifier);
        capturedPhotos.state = [
          ...capturedPhotos.state,
          CapturedPhoto(path: xFile.path),
        ];

        return xFile.path;
      }
    } catch (e) {
      print('Error capturing photo: $e');
      rethrow;
    }
  }

  void disposeCamera() {
    final controller = _ref.read(cameraControllerProvider);
    controller?.dispose();
    _ref.read(cameraControllerProvider.notifier).state = null;
    _ref.read(cameraStateProvider.notifier).state = CameraState.uninitialized;
  }

  // Helper method to clear captured photos
  void clearCapturedPhotos() {
    // Release any web URLs to prevent memory leaks
    if (kIsWeb) {
      for (final photo in _ref.read(capturedPhotosProvider)) {
        if (photo.webUrl != null) {
          html.Url.revokeObjectUrl(photo.webUrl!);
        }
      }
    }

    _ref.read(capturedPhotosProvider.notifier).state = [];
  }
}

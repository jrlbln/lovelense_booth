import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovelense_booth/services/camera_service.dart';

class CameraPreviewWidget extends ConsumerWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraController = ref.watch(cameraControllerProvider);

    return cameraController == null || !cameraController.value.isInitialized
        ? _buildLoadingPreview()
        : ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: cameraController.value.aspectRatio,
            child: CameraPreview(cameraController),
          ),
        );
  }

  Widget _buildLoadingPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '*camera preview*',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// Mock CameraPreview for example
class CameraPreview extends StatelessWidget {
  final dynamic controller;

  const CameraPreview(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    // This is a placeholder - in a real app, this would use the camera plugin
    return Container(
      color: Colors.grey.shade400,
      child: const Center(
        child: Text(
          '*camera preview*',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

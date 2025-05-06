import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lovelense_booth/services/camera_service.dart';

class FrameUtil {
  /// Creates a single image from multiple captured photos based on the layout
  /// Returns the file path of the created image
  static Future<String> generateFrameImage(
    List<CapturedPhoto> photos,
    int frameCount,
    GlobalKey frameKey,
  ) async {
    try {
      // Capture the widget as image using RepaintBoundary
      final RenderRepaintBoundary boundary =
          frameKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert widget to image');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save the image
      if (kIsWeb) {
        // For web, we can't use the file system directly
        // We'll return a dummy path that represents the bytes
        // The bytes will be stored in a provider and accessed by this path
        return 'memory://frame_${DateTime.now().millisecondsSinceEpoch}.png';
      } else {
        // For mobile, save to a file
        final directory = await getApplicationDocumentsDirectory();
        final String path =
            '${directory.path}/frame_${DateTime.now().millisecondsSinceEpoch}.png';
        final File file = File(path);
        await file.writeAsBytes(pngBytes);
        return path;
      }
    } catch (e) {
      print('Error generating frame image: $e');
      rethrow;
    }
  }
}

// Provider to store the generated frame image bytes for web
final frameImageBytesProvider =
    StateProvider<Map<String, Uint8List>>((ref) => {});

// Extension method to capture a widget as an image
extension GlobalKeyExtension on GlobalKey {
  Future<Uint8List?> captureAsPngBytes() async {
    try {
      final RenderRepaintBoundary? boundary =
          currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing widget as image: $e');
      return null;
    }
  }
}

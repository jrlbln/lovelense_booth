import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lovelense_booth/services/camera_service.dart';
import 'package:flutter/services.dart' show rootBundle;

class FrameUtil {
  /// Creates a single image from multiple captured photos based on the layout
  /// Returns the file path of the created image
  static Future<String> generateFrameImage(
    List<CapturedPhoto> photos,
    int frameCount,
    GlobalKey frameKey,
  ) async {
    try {
      // First capture the widget as image using RepaintBoundary
      final RenderRepaintBoundary boundary =
          frameKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture the frame layout at a higher resolution for quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert widget to image');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Now add header and footer to the image
      final Uint8List finalImageBytes = await _addHeaderAndFooter(pngBytes);

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
        await file.writeAsBytes(finalImageBytes);
        return path;
      }
    } catch (e) {
      print('Error generating frame image: $e');
      rethrow;
    }
  }

  /// Adds a header and footer to the frame image
  static Future<Uint8List> _addHeaderAndFooter(
      Uint8List originalImageBytes) async {
    // Create a new image with header and footer
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Decode the original image
    final codec = await ui.instantiateImageCodec(originalImageBytes);
    final frame = await codec.getNextFrame();
    final originalImage = frame.image;

    // Calculate dimensions
    const double headerHeight = 100.0;
    const double footerHeight = 100.0;
    final double totalWidth = originalImage.width.toDouble();
    final double totalHeight =
        originalImage.height + headerHeight + footerHeight;

    // Draw white background
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalWidth, totalHeight),
      paint,
    );

    // Draw header
    final headerPaint = Paint()
      ..color = const Color(0xFF87CEEB)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, totalWidth, headerHeight),
      headerPaint,
    );

    // Draw header text (names)
    const headerNames = 'Jimuel & Jaybei';
    const headerNamesStyle = TextStyle(
      color: Colors.white,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    );
    const headerNamesSpan = TextSpan(
      text: headerNames,
      style: headerNamesStyle,
    );
    final headerNamesPainter = TextPainter(
      text: headerNamesSpan,
      textDirection: TextDirection.ltr,
    );
    headerNamesPainter.layout();
    headerNamesPainter.paint(
      canvas,
      Offset(
        (totalWidth - headerNamesPainter.width) / 2,
        (headerHeight / 2 - headerNamesPainter.height),
      ),
    );

    // Draw header date below names
    const headerDate = '05.31.2025';
    const headerDateStyle = TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w500,
    );
    const headerDateSpan = TextSpan(
      text: headerDate,
      style: headerDateStyle,
    );
    final headerDatePainter = TextPainter(
      text: headerDateSpan,
      textDirection: TextDirection.ltr,
    );
    headerDatePainter.layout();
    headerDatePainter.paint(
      canvas,
      Offset(
        (totalWidth - headerDatePainter.width) / 2,
        (headerHeight / 2),
      ),
    );

    // Draw the original image
    canvas.drawImage(
      originalImage,
      const Offset(0, headerHeight),
      Paint(),
    );

    // Draw footer
    final footerPaint = Paint()
      ..color = const Color(0xFF61ECD9)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, totalHeight - footerHeight, totalWidth, footerHeight),
      footerPaint,
    );

    // Draw footer text and icon
    const footerText = 'made with LoveLense';
    const footerTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );
    const footerTextSpan = TextSpan(
      text: footerText,
      style: footerTextStyle,
    );
    final footerTextPainter = TextPainter(
      text: footerTextSpan,
      textDirection: TextDirection.ltr,
    );
    footerTextPainter.layout();

    // Load the LoveLense icon asset as an image
    final ByteData iconData =
        await rootBundle.load('assets/images/LoveLenseIcon.png');
    final ui.Codec iconCodec =
        await ui.instantiateImageCodec(iconData.buffer.asUint8List());
    final ui.FrameInfo iconFrame = await iconCodec.getNextFrame();
    final ui.Image iconImage = iconFrame.image;
    const double iconSize = 36.0;

    // Calculate total width for text + icon
    final double totalFooterContentWidth =
        footerTextPainter.width + iconSize + 12.0;
    final double footerContentStartX =
        (totalWidth - totalFooterContentWidth) / 2;
    final double footerContentY =
        totalHeight - footerHeight / 2 - footerTextPainter.height / 2;

    // Draw text
    footerTextPainter.paint(
      canvas,
      Offset(footerContentStartX, footerContentY),
    );
    // Draw icon to the right of the text
    final double iconY = totalHeight - footerHeight / 2 - iconSize / 2;
    canvas.drawImageRect(
      iconImage,
      Rect.fromLTWH(
          0, 0, iconImage.width.toDouble(), iconImage.height.toDouble()),
      Rect.fromLTWH(footerContentStartX + footerTextPainter.width + 12.0, iconY,
          iconSize, iconSize),
      Paint(),
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      totalWidth.toInt(),
      totalHeight.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
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

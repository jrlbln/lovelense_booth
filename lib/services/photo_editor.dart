import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

// Photo editor provider
final photoEditorProvider = Provider<PhotoEditorService>((ref) {
  return PhotoEditorService();
});

class PhotoEditorService {
  final List<PhotoSticker> stickers = [];

  void addSticker(String stickerId) {
    // Generate random position within reasonable bounds
    final position = Offset(
      100 + math.Random().nextDouble() * 200,
      100 + math.Random().nextDouble() * 200,
    );

    stickers.add(
      ImageSticker(
        id: 'sticker_${stickers.length}',
        stickerId: stickerId,
        position: position,
        rotation: 0,
        scale: 1.0,
      ),
    );
  }

  void addTextSticker({
    required String text,
    required double fontSize,
    required Color color,
  }) {
    // Generate random position within reasonable bounds
    final position = Offset(
      100 + math.Random().nextDouble() * 200,
      100 + math.Random().nextDouble() * 200,
    );

    stickers.add(
      TextSticker(
        id: 'text_${stickers.length}',
        text: text,
        position: position,
        rotation: 0,
        scale: 1.0,
        fontSize: fontSize,
        color: color,
      ),
    );
  }

  void updateStickerPosition(String id, Offset position) {
    final index = stickers.indexWhere((sticker) => sticker.id == id);
    if (index != -1) {
      stickers[index] = stickers[index].copyWith(position: position);
    }
  }

  void updateStickerRotation(String id, double rotation) {
    final index = stickers.indexWhere((sticker) => sticker.id == id);
    if (index != -1) {
      stickers[index] = stickers[index].copyWith(rotation: rotation);
    }
  }

  void updateStickerScale(String id, double scale) {
    final index = stickers.indexWhere((sticker) => sticker.id == id);
    if (index != -1) {
      stickers[index] = stickers[index].copyWith(scale: scale);
    }
  }

  void removeSticker(String id) {
    stickers.removeWhere((sticker) => sticker.id == id);
  }

  Future<String> captureCanvas(GlobalKey key) async {
    // In a real app, this would use a package like screenshot or render_to_image
    // to capture the rendered canvas as an image
    await Future.delayed(const Duration(seconds: 1));

    // Return a mock image path
    return 'edited_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
}

abstract class PhotoSticker {
  final String id;
  final Offset position;
  final double rotation;
  final double scale;

  PhotoSticker({
    required this.id,
    required this.position,
    required this.rotation,
    required this.scale,
  });

  PhotoSticker copyWith({
    String? id,
    Offset? position,
    double? rotation,
    double? scale,
  });
}

class ImageSticker extends PhotoSticker {
  final String stickerId;

  ImageSticker({
    required super.id,
    required this.stickerId,
    required super.position,
    required super.rotation,
    required super.scale,
  });

  @override
  PhotoSticker copyWith({
    String? id,
    String? stickerId,
    Offset? position,
    double? rotation,
    double? scale,
  }) {
    return ImageSticker(
      id: id ?? this.id,
      stickerId: stickerId ?? this.stickerId,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }
}

class TextSticker extends PhotoSticker {
  final String text;
  final double fontSize;
  final Color color;

  TextSticker({
    required super.id,
    required this.text,
    required super.position,
    required super.rotation,
    required super.scale,
    required this.fontSize,
    required this.color,
  });

  @override
  PhotoSticker copyWith({
    String? id,
    String? text,
    Offset? position,
    double? rotation,
    double? scale,
    double? fontSize,
    Color? color,
  }) {
    return TextSticker(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
    );
  }
}

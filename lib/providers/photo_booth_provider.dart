import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model for couple information
class CoupleInfo {
  final String name1;
  final String name2;
  final String eventDate;

  CoupleInfo({
    required this.name1,
    required this.name2,
    required this.eventDate,
  });
}

// Provider for couple info
final coupleInfoProvider = Provider<CoupleInfo>((ref) {
  // In a real app, this could be loaded from configuration
  return CoupleInfo(
      name1: 'Jimuel', name2: 'Jaybei', eventDate: 'May 30, 2025');
});

// Photos provider to track captured photos
final photosProvider = StateProvider<List<String>>((ref) => []);

// Selected frame count provider
final selectedFrameCountProvider = StateProvider<int>((ref) => 3);

// Current step in the booth flow
enum BoothStep { start, camera, share }

final currentStepProvider = StateProvider<BoothStep>((ref) => BoothStep.start);

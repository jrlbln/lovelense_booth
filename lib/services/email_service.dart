import 'package:flutter_riverpod/flutter_riverpod.dart';

final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

class EmailService {
  Future<void> sendPhotoEmail({
    required String email,
    required String imageUrl,
  }) async {
    // In a real app, this would call a backend API or Firebase Function
    // to send an email with the photo attached

    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, handle potential errors here
    // For this example, we'll just return success
    return;
  }
}

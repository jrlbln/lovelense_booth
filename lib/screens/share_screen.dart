import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovelense_booth/screens/start_screen.dart';
import 'package:lovelense_booth/widgets/email_form.dart';
import 'package:lovelense_booth/services/email_service.dart';
import 'package:lovelense_booth/providers/photo_booth_provider.dart';

class ShareScreen extends ConsumerStatefulWidget {
  final String imageUrl;

  const ShareScreen({super.key, required this.imageUrl});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  bool isSending = false;
  bool isComplete = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final couple = ref.watch(coupleInfoProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${couple.name1} & ${couple.name2}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Photo Preview
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // In a real app, load the image from the URL
                    child: const Center(
                      child: Icon(Icons.image, size: 120, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              // Email form or thank you message
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: isComplete ? _buildThankYouMessage() : _buildEmailForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const Text(
          'Would you like a copy of this photo sent to your email?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        EmailForm(onSubmit: (email) => _sendEmail(email), isLoading: isSending),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _returnToStart,
          child: const Text(
            'No Thanks, Return to Start',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildThankYouMessage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Thank you! Your photo has been sent.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _returnToStart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Take More Photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendEmail(String email) async {
    setState(() {
      isSending = true;
      errorMessage = null;
    });

    try {
      await ref
          .read(emailServiceProvider)
          .sendPhotoEmail(email: email, imageUrl: widget.imageUrl);

      setState(() {
        isComplete = true;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to send email. Please try again.';
      });
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  void _returnToStart() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const StartScreen()),
      (route) => false,
    );
  }
}

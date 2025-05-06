import 'package:flutter/material.dart';

class EmailDialog extends StatefulWidget {
  final Function(String email) onSendEmail;

  const EmailDialog({super.key, required this.onSendEmail});

  @override
  State<EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<EmailDialog> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send to Email'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the email address to send your photos to:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email address';
                }
                // Simple email validation
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isSubmitting = true;
                    });

                    // Call the callback with the email
                    widget.onSendEmail(_emailController.text);

                    // Close the dialog
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SEND'),
        ),
      ],
    );
  }
}

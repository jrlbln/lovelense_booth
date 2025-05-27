import 'package:flutter/material.dart';

class FlashEffect extends StatefulWidget {
  final VoidCallback onFlashComplete;

  const FlashEffect({
    super.key,
    required this.onFlashComplete,
  });

  @override
  State<FlashEffect> createState() => _FlashEffectState();
}

class _FlashEffectState extends State<FlashEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300), // Flash duration
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 1.0, // Start fully visible (white)
      end: 0.0, // Fade to transparent
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Start the flash animation immediately
    _controller.forward().then((_) {
      // Call the callback when animation completes
      widget.onFlashComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white.withOpacity(_opacityAnimation.value),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

class FrameSelector extends StatelessWidget {
  final int selectedFrameCount;
  final Function(int) onFrameSelected;
  final bool disabled;

  const FrameSelector({
    super.key,
    required this.selectedFrameCount,
    required this.onFrameSelected,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFrameButton(context, 3),
        const SizedBox(width: 16),
        _buildFrameButton(context, 4),
        const SizedBox(width: 16),
        _buildFrameButton(context, 6),
      ],
    );
  }

  Widget _buildFrameButton(BuildContext context, int frameCount) {
    final isSelected = selectedFrameCount == frameCount;

    return Material(
      color: isSelected ? Colors.blue.shade300 : Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: isSelected ? 4 : 2,
      child: InkWell(
        onTap: disabled ? null : () => onFrameSelected(frameCount),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$frameCount',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Photos',
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

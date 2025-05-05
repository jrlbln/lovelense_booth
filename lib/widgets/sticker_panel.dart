import 'package:flutter/material.dart';

class StickerPanel extends StatelessWidget {
  final Function(String) onStickerSelected;
  final VoidCallback onTextStickerRequested;

  const StickerPanel({
    super.key,
    required this.onStickerSelected,
    required this.onTextStickerRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Theme.of(context).colorScheme.primary,
            child: const Center(
              child: Text(
                'Stickers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Add text sticker button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: onTextStickerRequested,
              icon: const Icon(Icons.text_fields),
              label: const Text('Add Text'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Colors.white,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),

          const Divider(),

          // Sticker grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _mockStickers.length,
              itemBuilder: (context, index) {
                return _buildStickerItem(_mockStickers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerItem(Map<String, dynamic> sticker) {
    return InkWell(
      onTap: () => onStickerSelected(sticker['id']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            sticker['icon'] as IconData,
            size: 32,
            color: sticker['color'] as Color,
          ),
        ),
      ),
    );
  }

  // Mock sticker data
  static final List<Map<String, dynamic>> _mockStickers = [
    {'id': 'heart', 'icon': Icons.favorite, 'color': Colors.red},
    {'id': 'star', 'icon': Icons.star, 'color': Colors.amber},
    {'id': 'flower', 'icon': Icons.local_florist, 'color': Colors.pink},
    {'id': 'cake', 'icon': Icons.cake, 'color': Colors.brown},
    {'id': 'celebration', 'icon': Icons.celebration, 'color': Colors.purple},
    {'id': 'party', 'icon': Icons.emoji_emotions, 'color': Colors.orange},
    {
      'id': 'rings',
      'icon': Icons.volunteer_activism,
      'color': Colors.red.shade800,
    },
    {'id': 'gift', 'icon': Icons.card_giftcard, 'color': Colors.teal},
    {'id': 'music', 'icon': Icons.music_note, 'color': Colors.blue},
    {'id': 'confetti', 'icon': Icons.auto_awesome, 'color': Colors.purple},
    {'id': 'moon', 'icon': Icons.nightlight_round, 'color': Colors.indigo},
    {'id': 'sun', 'icon': Icons.wb_sunny, 'color': Colors.amber},
  ];
}

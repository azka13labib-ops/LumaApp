import 'package:flutter/material.dart';

class PlayShuffleBar extends StatelessWidget {
  const PlayShuffleBar({
    super.key,
    required this.onPlayAll,
    required this.onShuffle,
  });

  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyMedium?.color ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Putar Semua',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              onPressed: onPlayAll,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: textPrimary,
              side: BorderSide(color: theme.dividerColor),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.shuffle_rounded, size: 18),
            label: const Text('Acak', style: TextStyle(fontSize: 14)),
            onPressed: onShuffle,
          ),
        ],
      ),
    );
  }
}

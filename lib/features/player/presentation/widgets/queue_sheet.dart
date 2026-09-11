import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/player_provider.dart';
import '../../../../core/theme/app_theme.dart';

class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final queue = state.queue;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Antrian',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${queue.length} lagu',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF2A2A2A)),
            Expanded(
              child: queue.isEmpty
                  ? const Center(
                      child: Text(
                        'Antrian kosong',
                        style: TextStyle(color: LumaColors.darkTextSecondary),
                      ),
                    )
                  : ReorderableListView.builder(
                      scrollController: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: queue.length,
                      onReorderItem: (oldIndex, newIndex) {
                        ref.read(playerProvider.notifier).reorderQueue(oldIndex, newIndex);
                      },
                      itemBuilder: (context, i) {
                        final item = queue[i];
                        final isCurrent = i == state.currentIndex;
                        return ListTile(
                          key: ValueKey('${item.id}_$i'),
                          onTap: () {
                            ref.read(playerProvider.notifier).jumpToQueueIndex(i);
                          },
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.thumbnailUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                color: LumaColors.darkSurface,
                                child: const Icon(Icons.music_note, color: Colors.white38, size: 18),
                              ),
                            ),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent ? LumaColors.accent : Colors.white,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            item.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isCurrent)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                                  onPressed: () =>
                                      ref.read(playerProvider.notifier).removeFromQueue(i),
                                ),
                              const Icon(Icons.drag_handle_rounded, color: Colors.white24),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

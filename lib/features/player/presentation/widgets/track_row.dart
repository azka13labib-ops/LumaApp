import 'package:flutter/material.dart';

import '../../../../core/services/youtube_service.dart';
import '../../../../core/theme/app_theme.dart';

class TrackRow extends StatelessWidget {
  const TrackRow({
    super.key,
    required this.item,
    required this.onTap,
    this.trailing,
  });

  final MusicItem item;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                item.thumbnailUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: LumaColors.darkSurface,
                    child: const Icon(Icons.music_note, color: Colors.white30, size: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.author,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/services/lyrics_service.dart';
import '../../../../core/theme/app_theme.dart';

class LyricsSheet extends StatefulWidget {
  const LyricsSheet({super.key, required this.title, required this.artist});

  final String title;
  final String artist;

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  late Future<String?> _future;

  @override
  void initState() {
    super.initState();
    _future = LyricsService.instance.fetch(title: widget.title, artist: widget.artist);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                widget.artist,
                style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1, color: Color(0xFF2A2A2A)),
            Expanded(
              child: FutureBuilder<String?>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: LumaColors.accent, strokeWidth: 2),
                    );
                  }
                  if (snap.hasError || snap.data == null) {
                    return _Empty(
                      scrollController: scrollController,
                      message: 'Gagal memuat lirik.\nPeriksa koneksi lalu coba lagi.',
                      onRetry: () => setState(() {
                        _future = LyricsService.instance
                            .fetch(title: widget.title, artist: widget.artist);
                      }),
                    );
                  }
                  final text = snap.data!;
                  if (text.isEmpty) {
                    return _Empty(
                      scrollController: scrollController,
                      message: 'Lirik tidak ditemukan untuk lagu ini.',
                    );
                  }
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                      ),
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

class _Empty extends StatelessWidget {
  const _Empty({
    required this.scrollController,
    required this.message,
    this.onRetry,
  });

  final ScrollController scrollController;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.lyrics_outlined, color: Colors.white24, size: 48),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: LumaColors.darkTextSecondary, fontSize: 14, height: 1.4),
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi', style: TextStyle(color: LumaColors.accent)),
          ),
        ],
      ],
    );
  }
}

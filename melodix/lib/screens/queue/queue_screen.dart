import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../providers/music_providers.dart';
import '../../models/song_model.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.read(audioHandlerProvider);
    final queue = ref.watch(queueProvider);
    final currentSong = ref.watch(currentSongProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Queue'),
        backgroundColor: AppTheme.darkSurface,
        actions: [
          TextButton(
            onPressed: handler.clearQueue,
            child: const Text('Clear All',
                style: TextStyle(color: AppTheme.accentPink)),
          ),
        ],
      ),
      body: queue.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.queue_music_outlined,
                      color: Color(0xFF6B6B6B), size: 64),
                  SizedBox(height: 12),
                  Text('Queue is empty',
                      style: TextStyle(
                          color: Color(0xFF8A8A8A), fontSize: 16)),
                ],
              ),
            );
          }

          return currentSong.when(
            data: (current) => ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: songs.length,
              onReorder: (oldIndex, newIndex) {
                handler.reorderQueue(
                    oldIndex, newIndex > oldIndex ? newIndex - 1 : newIndex);
              },
              itemBuilder: (_, i) {
                final song = songs[i];
                final isPlaying = current?.id == song.id;

                return ListTile(
                  key: Key(song.id + i.toString()),
                  leading: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.darkCard,
                            child: const Icon(Icons.music_note,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                      if (isPlaying)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.equalizer_rounded,
                              color: AppTheme.primaryGreen, size: 20),
                        ),
                    ],
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          isPlaying ? AppTheme.primaryGreen : Colors.white,
                      fontWeight: isPlaying
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF8A8A8A), fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(song.durationString,
                          style: const TextStyle(
                              color: Color(0xFF8A8A8A), fontSize: 12)),
                      const SizedBox(width: 8),
                      if (!isPlaying)
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Color(0xFF6B6B6B), size: 18),
                          onPressed: () => handler.removeFromQueue(i),
                        ),
                      const Icon(Icons.drag_handle_rounded,
                          color: Color(0xFF6B6B6B)),
                    ],
                  ),
                  onTap: () => handler.skipToIndex(i),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox(),
      ),
    );
  }
}

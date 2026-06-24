import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/music_providers.dart';
import '../services/audio_handler.dart';
import '../screens/player/player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final handler = ref.read(audioHandlerProvider);

    return currentSong.when(
      data: (song) {
        if (song == null) return const SizedBox();
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const PlayerScreen(),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.darkElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar at top
                StreamBuilder<PositionData>(
                  stream: handler.positionDataStream,
                  builder: (_, snapshot) {
                    final pos = snapshot.data;
                    final progress = pos != null && pos.duration.inMilliseconds > 0
                        ? pos.position.inMilliseconds / pos.duration.inMilliseconds
                        : 0.0;
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: AppTheme.darkBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        minHeight: 2,
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.darkCard,
                            width: 44,
                            height: 44,
                            child: const Icon(Icons.music_note, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Song info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8A8A8A),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Controls
                      StreamBuilder(
                        stream: handler.playerStateStream,
                        builder: (_, snapshot) {
                          final isPlaying = snapshot.data?.playing ?? false;
                          final isLoading =
                              snapshot.data?.processingState == ProcessingState.loading ||
                              snapshot.data?.processingState == ProcessingState.buffering;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: handler.skipToPrevious,
                                icon: const Icon(Icons.skip_previous_rounded,
                                    color: Colors.white, size: 24),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.primaryGreen),
                                      )
                                    : IconButton(
                                        onPressed: isPlaying ? handler.pause : handler.play,
                                        icon: Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                              ),
                              IconButton(
                                onPressed: handler.skipToNext,
                                icon: const Icon(Icons.skip_next_rounded,
                                    color: Colors.white, size: 24),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';
import '../providers/music_providers.dart';
import '../services/download_service.dart';

class SongListTile extends ConsumerWidget {
  final SongModel song;
  final VoidCallback onTap;
  final bool showIndex;
  final int? index;

  const SongListTile({
    super.key,
    required this.song,
    required this.onTap,
    this.showIndex = false,
    this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongs = ref.watch(likedSongsProvider);
    final isLiked = likedSongs.any((s) => s.id == song.id);
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = currentSong.value?.id == song.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: song.thumbnailUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppTheme.darkCard,
                width: 56,
                height: 56,
                child: const Icon(Icons.music_note, color: Color(0xFF6B6B6B), size: 24),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.darkCard,
                width: 56,
                height: 56,
                child: const Icon(Icons.music_note, color: Color(0xFF6B6B6B), size: 24),
              ),
            ),
          ),
          if (isPlaying)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.equalizer_rounded,
                  color: AppTheme.primaryGreen, size: 22),
            ),
        ],
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying ? AppTheme.primaryGreen : Colors.white,
          fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '${song.artist} • ${song.durationString}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Color(0xFF6B6B6B), size: 20),
        color: AppTheme.darkCard,
        onSelected: (action) => _handleAction(context, ref, action),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'like',
            child: Row(children: [
              Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppTheme.accentPink : Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(isLiked ? 'Unlike' : 'Like',
                  style: const TextStyle(color: Colors.white)),
            ]),
          ),
          const PopupMenuItem(
            value: 'add_next',
            child: Row(children: [
              Icon(Icons.queue_play_next_outlined, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Play Next', style: TextStyle(color: Colors.white)),
            ]),
          ),
          const PopupMenuItem(
            value: 'add_queue',
            child: Row(children: [
              Icon(Icons.add_to_queue_outlined, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Add to Queue', style: TextStyle(color: Colors.white)),
            ]),
          ),
          const PopupMenuItem(
            value: 'add_playlist',
            child: Row(children: [
              Icon(Icons.playlist_add, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Add to Playlist', style: TextStyle(color: Colors.white)),
            ]),
          ),
          const PopupMenuItem(
            value: 'download',
            child: Row(children: [
              Icon(Icons.download_outlined, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Download', style: TextStyle(color: Colors.white)),
            ]),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final handler = ref.read(audioHandlerProvider);
    switch (action) {
      case 'like':
        ref.read(likedSongsProvider.notifier).toggleLike(song);
        break;
      case 'add_next':
        handler.addNextInQueue(song);
        _showSnack(context, 'Playing next: ${song.title}');
        break;
      case 'add_queue':
        handler.addToQueue(song);
        _showSnack(context, 'Added to queue: ${song.title}');
        break;
      case 'add_playlist':
        _showAddToPlaylistDialog(context, ref);
        break;
      case 'download':
        _downloadSong(context, ref);
        break;
    }
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref) {
    final playlists = ref.read(playlistProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Add to Playlist',
                style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No playlists yet. Create one first!',
                  style: TextStyle(color: Color(0xFF8A8A8A))),
            )
          else
            ...playlists.map((p) => ListTile(
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${p.songCount} songs',
                      style: const TextStyle(color: Color(0xFF8A8A8A))),
                  onTap: () {
                    ref.read(playlistProvider.notifier).addSongToPlaylist(p.id, song);
                    Navigator.pop(context);
                    _showSnack(context, 'Added to ${p.name}');
                  },
                )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _downloadSong(BuildContext context, WidgetRef ref) async {
    _showSnack(context, 'Downloading ${song.title}...');
    try {
      await DownloadService().downloadSong(song);
      _showSnack(context, '✓ Downloaded: ${song.title}');
    } catch (e) {
      _showSnack(context, 'Download failed: $e');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.darkElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

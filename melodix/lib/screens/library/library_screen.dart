import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../providers/music_providers.dart';
import '../../models/song_model.dart';
import '../../models/playlist_model.dart';
import '../../services/download_service.dart';
import '../../widgets/song_list_tile.dart';
import '../player/player_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        title: const Text('Your Library',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showCreatePlaylistDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: const Color(0xFF6B6B6B),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Liked'),
            Tab(text: 'Downloads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PlaylistsTab(onCreatePlaylist: _showCreatePlaylistDialog),
          _LikedSongsTab(),
          _DownloadsTab(),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('New Playlist',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Color(0xFF6B6B6B)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryGreen),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B6B6B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(playlistProvider.notifier)
                    .createPlaylist(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Playlists Tab
// ────────────────────────────────────────────────────────────────────────────

class _PlaylistsTab extends ConsumerWidget {
  final VoidCallback onCreatePlaylist;
  const _PlaylistsTab({required this.onCreatePlaylist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);

    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_music_outlined,
                color: Color(0xFF6B6B6B), size: 64),
            const SizedBox(height: 12),
            const Text('No playlists yet',
                style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onCreatePlaylist,
              icon: const Icon(Icons.add),
              label: const Text('Create Playlist'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: playlists.length,
      itemBuilder: (_, i) => _PlaylistTile(playlist: playlists[i]),
    );
  }
}

class _PlaylistTile extends ConsumerWidget {
  final PlaylistModel playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = playlist.songs.isNotEmpty
        ? playlist.songs.first.thumbnailUrl
        : null;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: cover != null
            ? CachedNetworkImage(
                imageUrl: cover,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
            : Container(
                width: 56,
                height: 56,
                color: AppTheme.darkCard,
                child: const Icon(Icons.queue_music_rounded,
                    color: AppTheme.primaryGreen, size: 28),
              ),
      ),
      title: Text(playlist.name,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${playlist.songCount} songs • ${playlist.totalDurationString}',
        style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Color(0xFF6B6B6B)),
        color: AppTheme.darkCard,
        onSelected: (action) => _handleAction(context, ref, action),
        itemBuilder: (_) => [
          const PopupMenuItem(
              value: 'rename',
              child: Text('Rename',
                  style: TextStyle(color: Colors.white))),
          const PopupMenuItem(
              value: 'delete',
              child: Text('Delete',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(playlist: playlist),
        ),
      ),
    );
  }

  void _handleAction(
      BuildContext context, WidgetRef ref, String action) {
    if (action == 'delete') {
      ref.read(playlistProvider.notifier).deletePlaylist(playlist.id);
    } else if (action == 'rename') {
      // Show rename dialog
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Liked Songs Tab
// ────────────────────────────────────────────────────────────────────────────

class _LikedSongsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongs = ref.watch(likedSongsProvider);

    if (likedSongs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded,
                color: Color(0xFF6B6B6B), size: 64),
            SizedBox(height: 12),
            Text('No liked songs yet',
                style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 16)),
            SizedBox(height: 4),
            Text('Like songs to see them here',
                style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Liked songs header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4B0082), AppTheme.darkBg],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Liked Songs',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  Text('${likedSongs.length} songs',
                      style: const TextStyle(
                          color: Color(0xFFB3B3B3), fontSize: 13)),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (likedSongs.isNotEmpty) {
                    final handler = ref.read(audioHandlerProvider);
                    handler.playSong(likedSongs.first,
                        queue: likedSongs);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PlayerScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  backgroundColor: AppTheme.primaryGreen,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.black, size: 28),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: likedSongs.length,
            itemBuilder: (_, i) => SongListTile(
              song: likedSongs[i],
              onTap: () {
                final handler = ref.read(audioHandlerProvider);
                handler.playSong(likedSongs[i], queue: likedSongs);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PlayerScreen()),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Downloads Tab
// ────────────────────────────────────────────────────────────────────────────

class _DownloadsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<SongModel>>(
      future: DownloadService().getDownloadedSongs(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final songs = snapshot.data ?? [];
        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_outlined,
                    color: Color(0xFF6B6B6B), size: 64),
                SizedBox(height: 12),
                Text('No downloads yet',
                    style: TextStyle(
                        color: Color(0xFF8A8A8A), fontSize: 16)),
                SizedBox(height: 4),
                Text('Download songs to listen offline',
                    style: TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (_, i) => SongListTile(
            song: songs[i],
            onTap: () {
              final handler = ref.read(audioHandlerProvider);
              handler.playSong(songs[i], queue: songs);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              );
            },
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Playlist Detail Screen
// ────────────────────────────────────────────────────────────────────────────

class PlaylistDetailScreen extends ConsumerWidget {
  final PlaylistModel playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = playlist.songs.isNotEmpty
        ? playlist.songs.first.thumbnailUrl
        : null;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.darkBg,
            flexibleSpace: FlexibleSpaceBar(
              background: cover != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.darkBg.withOpacity(0.9),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(color: AppTheme.darkCard),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  if (playlist.description != null)
                    Text(playlist.description!,
                        style: const TextStyle(
                            color: Color(0xFF8A8A8A), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.songCount} songs • ${playlist.totalDurationString}',
                    style: const TextStyle(
                        color: Color(0xFF8A8A8A), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (playlist.songs.isNotEmpty) {
                            final handler =
                                ref.read(audioHandlerProvider);
                            handler.playSong(playlist.songs.first,
                                queue: playlist.songs);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PlayerScreen()),
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play All'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (playlist.songs.isNotEmpty) {
                            final handler =
                                ref.read(audioHandlerProvider);
                            handler.toggleShuffle();
                            handler.playSong(playlist.songs.first,
                                queue: playlist.songs);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PlayerScreen()),
                            );
                          }
                        },
                        icon: const Icon(Icons.shuffle_rounded,
                            color: Colors.white),
                        label: const Text('Shuffle',
                            style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.darkBorder),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => SongListTile(
                song: playlist.songs[i],
                onTap: () {
                  final handler = ref.read(audioHandlerProvider);
                  handler.playSong(playlist.songs[i],
                      queue: playlist.songs);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PlayerScreen()),
                  );
                },
              ),
              childCount: playlist.songs.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

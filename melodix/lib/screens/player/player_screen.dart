import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:marquee/marquee.dart';
import '../../theme/app_theme.dart';
import '../../providers/music_providers.dart';
import '../../services/audio_handler.dart';
import '../../models/song_model.dart';
import '../queue/queue_screen.dart';
import '../lyrics/lyrics_screen.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  Color _dominantColor = AppTheme.darkSurface;
  late AnimationController _rotationController;
  bool _isLyricsVisible = false;
  SongModel? _lastSong;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _updateColor(String imageUrl) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        size: const Size(100, 100),
      );
      if (mounted) {
        setState(() {
          _dominantColor = palette.dominantColor?.color ??
              AppTheme.darkSurface;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final currentSong = ref.watch(currentSongProvider);
    final likedSongs = ref.watch(likedSongsProvider);

    return currentSong.when(
      data: (song) {
        if (song == null) return const SizedBox();

        // Update color when song changes
        if (_lastSong?.id != song.id) {
          _lastSong = song;
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => _updateColor(song.thumbnailUrl));
        }

        final isLiked = likedSongs.any((s) => s.id == song.id);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _dominantColor.withOpacity(0.9),
                  AppTheme.darkBg,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Top Bar ──────────────────────────
                  _buildTopBar(context, song),

                  // ── Artwork / Lyrics Toggle ───────────
                  Expanded(
                    child: _isLyricsVisible
                        ? LyricsView(song: song)
                        : _buildArtwork(song),
                  ),

                  // ── Song Info ───────────────────────
                  _buildSongInfo(song, isLiked),

                  // ── Progress Bar ────────────────────
                  _buildProgressBar(handler),

                  // ── Controls ───────────────────────
                  _buildControls(handler, song),

                  // ── Bottom Row ──────────────────────
                  _buildBottomRow(handler, song),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildTopBar(BuildContext context, SongModel song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 32),
          ),
          Column(
            children: [
              const Text('NOW PLAYING',
                  style: TextStyle(
                      color: Color(0xFF8A8A8A),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600)),
              Text(
                song.album.isEmpty ? 'Single' : song.album,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppTheme.darkCard,
            onSelected: (value) => _handleMenuAction(value, song),
            itemBuilder: (_) => [
              _menuItem('add_to_playlist', Icons.playlist_add,
                  'Add to Playlist'),
              _menuItem(
                  'share', Icons.share_outlined, 'Share'),
              _menuItem('download', Icons.download_outlined,
                  'Download'),
              _menuItem('view_artist', Icons.person_outline,
                  'View Artist'),
              _menuItem('sleep_timer', Icons.timer_outlined,
                  'Sleep Timer'),
              _menuItem(
                  'speed', Icons.speed_outlined, 'Playback Speed'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildArtwork(SongModel song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AspectRatio(
        aspectRatio: 1,
        child: StreamBuilder(
          stream: ref.read(audioHandlerProvider).playerStateStream,
          builder: (_, snapshot) {
            final isPlaying =
                snapshot.data?.playing ?? false;
            return AnimatedScale(
              scale: isPlaying ? 1.0 : 0.88,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _dominantColor.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppTheme.darkCard,
                      child: const Icon(
                          Icons.music_note_rounded,
                          color: Color(0xFF6B6B6B),
                          size: 80),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.darkCard,
                      child: const Icon(
                          Icons.music_note_rounded,
                          color: Color(0xFF6B6B6B),
                          size: 80),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSongInfo(SongModel song, bool isLiked) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                song.title.length > 25
                    ? SizedBox(
                        height: 26,
                        child: Marquee(
                          text: song.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                          scrollAxis: Axis.horizontal,
                          blankSpace: 40,
                          velocity: 40,
                        ),
                      )
                    : Text(song.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(song.artist,
                    style: const TextStyle(
                        color: Color(0xFFB3B3B3), fontSize: 14)),
              ],
            ),
          ),
          // Like button
          IconButton(
            onPressed: () => ref
                .read(likedSongsProvider.notifier)
                .toggleLike(song),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isLiked),
                color: isLiked ? AppTheme.accentPink : Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(MelodixAudioHandler handler) {
    return StreamBuilder<PositionData>(
      stream: handler.positionDataStream,
      builder: (_, snapshot) {
        final posData = snapshot.data;
        final position = posData?.position ?? Duration.zero;
        final duration = posData?.duration ?? Duration.zero;
        final buffered =
            posData?.bufferedPosition ?? Duration.zero;

        final maxMs =
            duration.inMilliseconds.toDouble().clamp(0.0, double.infinity);
        final posMs = position.inMilliseconds
            .toDouble()
            .clamp(0.0, maxMs);
        final bufMs =
            buffered.inMilliseconds.toDouble().clamp(0.0, maxMs);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Stack(
                children: [
                  // Buffered progress
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: SliderComponentShape.noThumb,
                      trackHeight: 3,
                      activeTrackColor:
                          Colors.white.withOpacity(0.2),
                      inactiveTrackColor:
                          Colors.white.withOpacity(0.08),
                    ),
                    child: Slider(
                      value: bufMs,
                      min: 0,
                      max: maxMs == 0 ? 1 : maxMs,
                      onChanged: null,
                    ),
                  ),
                  // Playback progress
                  Slider(
                    value: posMs,
                    min: 0,
                    max: maxMs == 0 ? 1 : maxMs,
                    onChanged: (v) => handler
                        .seek(Duration(milliseconds: v.toInt())),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position),
                        style: const TextStyle(
                            color: Color(0xFFB3B3B3), fontSize: 12)),
                    Text(_formatDuration(duration),
                        style: const TextStyle(
                            color: Color(0xFFB3B3B3), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(
      MelodixAudioHandler handler, SongModel song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle
          StreamBuilder(
            stream: Stream.value(handler.shuffleMode),
            builder: (_, __) => IconButton(
              onPressed: () {
                handler.toggleShuffle();
                setState(() {});
              },
              icon: Icon(
                Icons.shuffle_rounded,
                color: handler.shuffleMode
                    ? AppTheme.primaryGreen
                    : Colors.white,
                size: 24,
              ),
            ),
          ),

          // Previous
          IconButton(
            onPressed: handler.skipToPrevious,
            icon: const Icon(Icons.skip_previous_rounded,
                color: Colors.white, size: 40),
          ),

          // Play/Pause
          StreamBuilder(
            stream: handler.playerStateStream,
            builder: (_, snapshot) {
              final state = snapshot.data;
              final isPlaying = state?.playing ?? false;
              final isLoading = state?.processingState ==
                  ProcessingState.loading ||
                  state?.processingState ==
                      ProcessingState.buffering;

              return GestureDetector(
                onTap: isPlaying ? handler.pause : handler.play,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.white.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: AppTheme.darkBg,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppTheme.darkBg,
                          size: 40,
                        ),
                ),
              );
            },
          ),

          // Next
          IconButton(
            onPressed: handler.skipToNext,
            icon: const Icon(Icons.skip_next_rounded,
                color: Colors.white, size: 40),
          ),

          // Repeat
          IconButton(
            onPressed: () {
              handler.cycleRepeatMode();
              setState(() {});
            },
            icon: Icon(
              handler.repeatMode == RepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: handler.repeatMode == RepeatMode.none
                  ? Colors.white
                  : AppTheme.primaryGreen,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow(
      MelodixAudioHandler handler, SongModel song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Lyrics toggle
          IconButton(
            onPressed: () =>
                setState(() => _isLyricsVisible = !_isLyricsVisible),
            icon: Icon(
              Icons.lyrics_outlined,
              color: _isLyricsVisible
                  ? AppTheme.primaryGreen
                  : Colors.white,
            ),
          ),

          // Volume
          IconButton(
            onPressed: () => _showVolumeDialog(handler),
            icon: const Icon(Icons.volume_up_outlined,
                color: Colors.white),
          ),

          // Queue
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QueueScreen()),
            ),
            icon: const Icon(Icons.queue_music_outlined,
                color: Colors.white),
          ),

          // Share
          IconButton(
            onPressed: () => _shareSong(song),
            icon: const Icon(Icons.share_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showVolumeDialog(MelodixAudioHandler handler) {
    double volume = 1.0;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Volume',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.volume_mute_outlined,
                      color: Colors.white),
                  Expanded(
                    child: Slider(
                      value: volume,
                      min: 0,
                      max: 1,
                      onChanged: (v) {
                        setModalState(() => volume = v);
                        handler.setVolume(v);
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up_outlined,
                      color: Colors.white),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Playback Speed',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                    .map((speed) => ActionChip(
                          label: Text('${speed}x'),
                          onPressed: () => handler.setSpeed(speed),
                          backgroundColor: AppTheme.darkElevated,
                          labelStyle: const TextStyle(
                              color: Colors.white),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _shareSong(SongModel song) {
    // Share.share(
    //   'Listening to ${song.title} by ${song.artist} on Melodix!\nhttps://youtu.be/${song.videoId}',
    // );
  }

  void _handleMenuAction(String action, SongModel song) {
    switch (action) {
      case 'sleep_timer':
        _showSleepTimerDialog();
        break;
      case 'speed':
        _showVolumeDialog(ref.read(audioHandlerProvider));
        break;
    }
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Sleep Timer',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [15, 30, 45, 60, 90]
              .map((minutes) => ListTile(
                    title: Text('$minutes minutes',
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      ref
                          .read(audioHandlerProvider)
                          .setSleepTimer(Duration(minutes: minutes));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Sleep timer set for $minutes minutes'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../providers/music_providers.dart';
import '../../models/song_model.dart';
import '../../services/music_api_service.dart';
import '../../widgets/song_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/genre_chip.dart';
import '../player/player_screen.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _selectedGenre = 'All';
  final List<String> _genres = [
    'All', 'Bollywood', 'Pop', 'Hip-Hop', 'Lo-Fi',
    'Rock', 'Jazz', 'Classical', 'K-Pop', 'EDM'
  ];

  final Map<String, AsyncValue<List<SongModel>>> _playlistCache = {};

  @override
  Widget build(BuildContext context) {
    final trending = ref.watch(trendingProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: AppTheme.darkBg,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.darkSurface, AppTheme.darkBg],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              title: const Text(
                'Melodix',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.accentPurple,
                  child: const Text('M',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),

          // ── Genre Chips ─────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _genres.length,
                itemBuilder: (_, i) => GenreChip(
                  label: _genres[i],
                  isSelected: _selectedGenre == _genres[i],
                  onTap: () =>
                      setState(() => _selectedGenre = _genres[i]),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Trending / Featured Banner ─────────
          SliverToBoxAdapter(
            child: trending.when(
              data: (songs) => songs.isEmpty
                  ? const SizedBox()
                  : _FeaturedBanner(songs: songs.take(5).toList()),
              loading: () => _shimmerBanner(),
              error: (_, __) => const SizedBox(),
            ),
          ),

          // ── Trending Section ───────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                    title: '🔥 Trending Now', showAll: true),
                SizedBox(
                  height: 200,
                  child: trending.when(
                    data: (songs) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: songs.length.clamp(0, 10),
                      itemBuilder: (_, i) => SongCard(
                        song: songs[i],
                        onTap: () => _playSong(songs[i], songs),
                      ),
                    ),
                    loading: () =>
                        _shimmerList(height: 200),
                    error: (e, _) => Center(
                        child: Text('Error: $e',
                            style: const TextStyle(
                                color: Colors.redAccent))),
                  ),
                ),
              ],
            ),
          ),

          // ── Curated Playlists ──────────────────
          ...MelodixApiService.curatedPlaylists.keys
              .take(4)
              .map((name) => SliverToBoxAdapter(
                    child: _CuratedPlaylistSection(
                      name: name,
                      onSongTap: _playSong,
                    ),
                  )),

          // ── Quick Picks (Recently Played) ──────
          SliverToBoxAdapter(
            child: Consumer(
              builder: (_, ref, __) {
                final recent = ref.watch(recentSongsProvider);
                if (recent.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                        title: '⏱ Recently Played'),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        itemCount: recent.length.clamp(0, 10),
                        itemBuilder: (_, i) => SongCard(
                          song: recent[i],
                          onTap: () =>
                              _playSong(recent[i], recent),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ],
      ),
    );
  }

  void _playSong(SongModel song, List<SongModel> queue) {
    final handler = ref.read(audioHandlerProvider);
    handler.playSong(song, queue: queue);
    ref.read(recentSongsProvider.notifier).addRecent(song);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PlayerScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
              parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  Widget _shimmerBanner() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _shimmerList({required double height}) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Featured Banner (auto-scrolling)
// ──────────────────────────────────────────────────────────────────────────────

class _FeaturedBanner extends StatefulWidget {
  final List<SongModel> songs;
  const _FeaturedBanner({required this.songs});

  @override
  State<_FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<_FeaturedBanner> {
  final PageController _pageController = PageController();
  int _current = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    final next = (_current + 1) % widget.songs.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.songs.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final song = widget.songs[i];
              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image:
                        CachedNetworkImageProvider(song.thumbnailUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('FEATURED',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 6),
                      Text(song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text(song.artist,
                          style: const TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.songs.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == _current ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _current
                    ? AppTheme.primaryGreen
                    : const Color(0xFF444444),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Curated Playlist Section
// ──────────────────────────────────────────────────────────────────────────────

class _CuratedPlaylistSection extends ConsumerStatefulWidget {
  final String name;
  final Function(SongModel, List<SongModel>) onSongTap;

  const _CuratedPlaylistSection({
    required this.name,
    required this.onSongTap,
  });

  @override
  ConsumerState<_CuratedPlaylistSection> createState() =>
      _CuratedPlaylistSectionState();
}

class _CuratedPlaylistSectionState
    extends ConsumerState<_CuratedPlaylistSection> {
  List<SongModel>? _songs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(musicApiProvider);
      final songs = await api.getCuratedPlaylist(widget.name);
      if (mounted) setState(() {
        _songs = songs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: widget.name),
        SizedBox(
          height: 200,
          child: _loading
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (_, __) => Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : _songs == null || _songs!.isEmpty
                  ? const Center(
                      child: Text('No songs found',
                          style: TextStyle(color: Color(0xFF6B6B6B))))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _songs!.length.clamp(0, 10),
                      itemBuilder: (_, i) => SongCard(
                        song: _songs![i],
                        onTap: () =>
                            widget.onSongTap(_songs![i], _songs!),
                      ),
                    ),
        ),
      ],
    );
  }
}

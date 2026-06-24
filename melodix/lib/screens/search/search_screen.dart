import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/music_providers.dart';
import '../../models/song_model.dart';
import '../../widgets/song_list_tile.dart';
import '../player/player_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;

  final List<String> _quickCategories = [
    '🔥 Trending', '🎵 Pop', '🎸 Rock', '🎤 Hip-Hop',
    '🎼 Classical', '😌 Lo-Fi', '💃 Dance', '🌙 Sleep',
    '💪 Workout', '🎧 K-Pop', '🎶 Bollywood', '🌟 Top Charts',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      ref.read(searchProvider.notifier).clear();
      setState(() => _isSearching = false);
      return;
    }
    setState(() => _isSearching = true);
    ref.read(searchProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Search',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _focusNode.hasFocus
                              ? AppTheme.primaryGreen
                              : AppTheme.darkBorder),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (v) {
                        if (v.isEmpty) {
                          setState(() => _isSearching = false);
                          ref.read(searchProvider.notifier).clear();
                        }
                      },
                      onSubmitted: _search,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Search songs, artists, albums...',
                        hintStyle: const TextStyle(
                            color: Color(0xFF6B6B6B)),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Color(0xFF6B6B6B)),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Color(0xFF6B6B6B), size: 18),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _isSearching = false);
                                  ref
                                      .read(searchProvider.notifier)
                                      .clear();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────
            Expanded(
              child: _isSearching
                  ? _buildSearchResults(searchResults)
                  : _buildBrowse(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowse() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Browse Categories',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _quickCategories.length,
            itemBuilder: (_, i) {
              final colors = [
                [AppTheme.primaryGreen, const Color(0xFF148040)],
                [AppTheme.accentPurple, const Color(0xFF6340C8)],
                [AppTheme.accentBlue, const Color(0xFF2563EB)],
                [AppTheme.accentPink, const Color(0xFFDB2777)],
                [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                [const Color(0xFF10B981), const Color(0xFF059669)],
              ];
              final colorPair = colors[i % colors.length];

              return GestureDetector(
                onTap: () {
                  final query = _quickCategories[i]
                      .replaceAll(RegExp(r'[^\w\s]'), '')
                      .trim();
                  _controller.text = query;
                  _search(query);
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colorPair,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Text(
                    _quickCategories[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
      AsyncValue<List<SongModel>> results) {
    return results.when(
      data: (songs) {
        if (songs.isEmpty && _isSearching) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded,
                    color: Color(0xFF6B6B6B), size: 64),
                SizedBox(height: 12),
                Text('No results found',
                    style: TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: songs.length,
          itemBuilder: (_, i) => SongListTile(
            song: songs[i],
            onTap: () => _playSong(songs[i], songs),
          ),
        );
      },
      loading: () => ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => const _ShimmerTile(),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: Color(0xFF6B6B6B), size: 48),
            const SizedBox(height: 12),
            Text('Error: $e',
                style: const TextStyle(
                    color: Color(0xFF6B6B6B), fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _search(_controller.text),
              child: const Text('Retry'),
            ),
          ],
        ),
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
}

class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 14,
                    width: 160,
                    decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(
                    height: 11,
                    width: 100,
                    decoration: BoxDecoration(
                        color: AppTheme.darkElevated,
                        borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

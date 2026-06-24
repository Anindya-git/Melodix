import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/song_model.dart';
import '../../providers/music_providers.dart';
import '../../services/music_api_service.dart';

class LyricsView extends ConsumerStatefulWidget {
  final SongModel song;
  const LyricsView({super.key, required this.song});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  String? _lyrics;
  bool _loading = true;
  List<_LrcLine>? _syncedLines;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void didUpdateWidget(LyricsView old) {
    super.didUpdateWidget(old);
    if (old.song.id != widget.song.id) {
      _lyrics = null;
      _syncedLines = null;
      setState(() => _loading = true);
      _fetchLyrics();
    }
  }

  Future<void> _fetchLyrics() async {
    try {
      final api = ref.read(musicApiProvider);
      final lyrics =
          await api.getLyrics(widget.song.title, widget.song.artist);

      if (mounted) {
        setState(() {
          _loading = false;
          _lyrics = lyrics;
          if (lyrics != null && lyrics.contains('[')) {
            _syncedLines = _parseLrc(lyrics);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_LrcLine> _parseLrc(String lrc) {
    final lines = <_LrcLine>[];
    for (final line in lrc.split('\n')) {
      final match =
          RegExp(r'\[(\d+):(\d+)\.?(\d*)\](.*)').firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final ms = int.tryParse(match.group(3) ?? '0') ?? 0;
        final text = match.group(4)!.trim();
        final timestamp =
            Duration(minutes: minutes, seconds: seconds, milliseconds: ms);
        lines.add(_LrcLine(timestamp: timestamp, text: text));
      }
    }
    return lines;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text('Fetching lyrics...',
                style: TextStyle(color: Color(0xFF8A8A8A))),
          ],
        ),
      );
    }

    if (_lyrics == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lyrics_outlined,
                color: Color(0xFF6B6B6B), size: 64),
            SizedBox(height: 12),
            Text('No lyrics found',
                style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 16)),
            SizedBox(height: 4),
            Text('Try another source',
                style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
          ],
        ),
      );
    }

    // Synced lyrics
    if (_syncedLines != null && _syncedLines!.isNotEmpty) {
      return StreamBuilder<Duration>(
        stream: ref.read(audioHandlerProvider).positionStream,
        builder: (_, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          int activeIndex = 0;
          for (int i = 0; i < _syncedLines!.length; i++) {
            if (_syncedLines![i].timestamp <= position) {
              activeIndex = i;
            }
          }

          // Auto-scroll
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final target = activeIndex * 52.0;
              _scrollController.animateTo(
                (target - 100).clamp(0.0, double.infinity),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: _syncedLines!.length,
            itemBuilder: (_, i) {
              final isActive = i == activeIndex;
              return AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF6B6B6B),
                  fontSize: isActive ? 18 : 15,
                  fontWeight: isActive
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _syncedLines![i].text.isEmpty
                        ? '♪'
                        : _syncedLines![i].text,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          );
        },
      );
    }

    // Plain lyrics
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        _lyrics!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.8,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _LrcLine {
  final Duration timestamp;
  final String text;
  _LrcLine({required this.timestamp, required this.text});
}

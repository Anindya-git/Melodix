import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';

/// MelodixApiService
/// Uses youtube_explode_dart + Piped public API instances as backends.
/// No API key needed — works like ViMusic / Bloomee / ArchiveTune.
class MelodixApiService {
  static final MelodixApiService _instance = MelodixApiService._internal();
  factory MelodixApiService() => _instance;
  MelodixApiService._internal();

  final YoutubeExplode _yt = YoutubeExplode();
  final Dio _dio = Dio();

  // Piped API instances (public, no auth required)
  static const List<String> _pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://piped-api.garudalinux.org',
    'https://api.piped.projectsegfau.lt',
    'https://piped.video/api',
  ];

  int _currentInstanceIndex = 0;

  String get _pipedBase => _pipedInstances[_currentInstanceIndex];

  /// Rotate to next Piped instance on failure
  void _rotateInstance() {
    _currentInstanceIndex =
        (_currentInstanceIndex + 1) % _pipedInstances.length;
  }

  // ─────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────

  Future<List<SongModel>> search(String query,
      {String filter = 'music_songs'}) async {
    try {
      final resp = await _dio.get(
        '$_pipedBase/search',
        queryParameters: {'q': query, 'filter': filter},
      );
      final List items = resp.data['items'] ?? [];
      return items
          .where((i) => i['type'] == 'stream')
          .map((i) => _parsePipedItem(i))
          .toList();
    } catch (e) {
      _rotateInstance();
      // Fallback: youtube_explode
      return await _searchYtExplode(query);
    }
  }

  Future<List<SongModel>> _searchYtExplode(String query) async {
    final results = await _yt.search.search(query);
    return results
        .whereType<Video>()
        .map((v) => SongModel(
              id: v.id.value,
              title: v.title,
              artist: v.author,
              album: '',
              thumbnailUrl:
                  v.thumbnails.highResUrl,
              duration: v.duration?.inSeconds ?? 0,
              source: 'youtube',
              videoId: v.id.value,
              viewCount: v.engagement.viewCount,
            ))
        .toList();
  }

  SongModel _parsePipedItem(Map<String, dynamic> item) {
    final url = item['url'] as String? ?? '';
    final videoId = url.replaceAll('/watch?v=', '');
    return SongModel(
      id: videoId,
      title: item['title'] ?? 'Unknown',
      artist: item['uploaderName'] ?? 'Unknown Artist',
      album: '',
      thumbnailUrl: item['thumbnail'] ?? '',
      duration: item['duration'] ?? 0,
      source: 'youtube',
      videoId: videoId,
      viewCount: item['views'],
    );
  }

  // ─────────────────────────────────────────────
  // GET STREAM URL (audio only)
  // ─────────────────────────────────────────────

  Future<String?> getAudioStreamUrl(String videoId,
      {AudioQuality quality = AudioQuality.high}) async {
    try {
      // Try Piped streams endpoint first (faster)
      final resp = await _dio.get('$_pipedBase/streams/$videoId');
      final audioStreams =
          (resp.data['audioStreams'] as List?) ?? [];

      // Filter for audio-only streams
      final streams = audioStreams
          .where((s) =>
              s['mimeType'] != null &&
              s['mimeType'].toString().contains('audio'))
          .toList();

      if (streams.isEmpty) throw Exception('No audio streams');

      // Sort by bitrate
      streams.sort((a, b) =>
          (b['bitrate'] ?? 0).compareTo(a['bitrate'] ?? 0));

      // Pick quality
      final index = quality == AudioQuality.high
          ? 0
          : quality == AudioQuality.medium
              ? streams.length ~/ 2
              : streams.length - 1;

      return streams[index]['url'] as String?;
    } catch (e) {
      _rotateInstance();
      // Fallback: youtube_explode
      return await _getStreamUrlYtExplode(videoId);
    }
  }

  Future<String?> _getStreamUrlYtExplode(String videoId) async {
    try {
      final manifest =
          await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.sortByBitrate();
      if (audioStreams.isEmpty) return null;
      return audioStreams.last.url.toString();
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // TRENDING / CHARTS
  // ─────────────────────────────────────────────

  Future<List<SongModel>> getTrending({String region = 'IN'}) async {
    try {
      final resp = await _dio.get('$_pipedBase/trending',
          queryParameters: {'region': region});
      final List items = resp.data ?? [];
      return items
          .where((i) => i['type'] == 'stream' || i['duration'] != null)
          .map((i) => _parsePipedItem(i))
          .take(30)
          .toList();
    } catch (e) {
      _rotateInstance();
      return await search('top hits 2024 India');
    }
  }

  // ─────────────────────────────────────────────
  // CHANNEL / ARTIST INFO
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getChannelInfo(String channelId) async {
    try {
      final resp = await _dio.get('$_pipedBase/channel/$channelId');
      return resp.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // PLAYLIST
  // ─────────────────────────────────────────────

  Future<List<SongModel>> getYouTubePlaylist(String playlistId) async {
    try {
      final resp =
          await _dio.get('$_pipedBase/playlists/$playlistId');
      final relatedStreams =
          (resp.data['relatedStreams'] as List?) ?? [];
      return relatedStreams.map((i) => _parsePipedItem(i)).toList();
    } catch (e) {
      // fallback yt_explode
      final playlist =
          await _yt.playlists.getVideos(playlistId).toList();
      return playlist
          .map((v) => SongModel(
                id: v.id.value,
                title: v.title,
                artist: v.author,
                album: '',
                thumbnailUrl: v.thumbnails.highResUrl,
                duration: v.duration?.inSeconds ?? 0,
                source: 'youtube',
                videoId: v.id.value,
              ))
          .toList();
    }
  }

  // ─────────────────────────────────────────────
  // RECOMMENDATIONS (next up)
  // ─────────────────────────────────────────────

  Future<List<SongModel>> getRecommendations(String videoId) async {
    try {
      final resp = await _dio.get('$_pipedBase/streams/$videoId');
      final related =
          (resp.data['relatedStreams'] as List?) ?? [];
      return related
          .where((i) => i['type'] == 'stream')
          .map((i) => _parsePipedItem(i))
          .take(20)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // VIDEO INFO
  // ─────────────────────────────────────────────

  Future<SongModel?> getVideoInfo(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      return SongModel(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        album: '',
        thumbnailUrl: video.thumbnails.highResUrl,
        duration: video.duration?.inSeconds ?? 0,
        source: 'youtube',
        videoId: video.id.value,
        viewCount: video.engagement.viewCount,
      );
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // LYRICS (via lyrics.ovh or LRCLIB)
  // ─────────────────────────────────────────────

  Future<String?> getLyrics(String title, String artist) async {
    try {
      // Try lrclib first (has synced lyrics)
      final resp = await _dio.get(
        'https://lrclib.net/api/get',
        queryParameters: {
          'track_name': title,
          'artist_name': artist,
        },
      );
      if (resp.data != null) {
        return resp.data['syncedLyrics'] ?? resp.data['plainLyrics'];
      }
    } catch (_) {}

    try {
      // Fallback: lyrics.ovh
      final resp = await _dio.get(
        'https://api.lyrics.ovh/v1/$artist/$title',
      );
      return resp.data['lyrics'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // CURATED MUSIC PLAYLISTS (pre-set YouTube IDs)
  // ─────────────────────────────────────────────

  static const Map<String, String> curatedPlaylists = {
    'Top Hits India':
        'PLDIoUOhQQPlXr63I_vwF06Dq80eKq-uhy',
    'Bollywood Hits':
        'PLFgquLnL59alCl_2TQvOiD5Vgm1hCaGSI',
    'Lo-Fi Beats':
        'PLofht4DuCBf9LTmpBjMi2fJlTipUkRFBr',
    'Chill Vibes':
        'PLGBuKfnErZlADCJRHzqbUU90K0bhv1c7A',
    'Hip Hop Mix':
        'PLH6pfBXQXHEC2uDmDy5oi3tHW6X8kZ2Jo',
    'Rock Classics':
        'PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG',
    'Pop Hits 2024':
        'PLDIoUOhQQPlXvU3Kt1sGmXv3bGJRx_yRF',
    'K-Pop Hits':
        'PLzCxunOM5WFJ7ukdpqHUmjnV2z7xWvJ4o',
  };

  Future<List<SongModel>> getCuratedPlaylist(String name) async {
    final id = curatedPlaylists[name];
    if (id == null) return [];
    return getYouTubePlaylist(id);
  }

  void dispose() {
    _yt.close();
  }
}

enum AudioQuality { low, medium, high }

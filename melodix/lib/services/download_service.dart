import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song_model.dart';
import 'music_api_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  final MelodixApiService _api = MelodixApiService();
  final Map<String, double> _progressMap = {};
  final Map<String, CancelToken> _cancelTokens = {};

  // Active download progress streams (using callbacks)
  final Map<String, Function(double)> _progressCallbacks = {};

  void addProgressCallback(String id, Function(double) callback) {
    _progressCallbacks[id] = callback;
  }

  void removeProgressCallback(String id) {
    _progressCallbacks.remove(id);
  }

  double getProgress(String id) => _progressMap[id] ?? 0.0;

  bool isDownloading(String id) => _cancelTokens.containsKey(id);

  Future<String> get _downloadsDir async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/melodix_downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<SongModel?> downloadSong(SongModel song) async {
    if (song.isDownloaded) return song;

    final videoId = song.videoId ?? song.id;
    final cancelToken = CancelToken();
    _cancelTokens[videoId] = cancelToken;

    try {
      // Get stream URL
      final streamUrl = await _api.getAudioStreamUrl(videoId);
      if (streamUrl == null) throw Exception('No stream URL');

      final dir = await _downloadsDir;
      final filePath = '$dir/$videoId.mp3';

      // Download file
      await _dio.download(
        streamUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            _progressMap[videoId] = progress;
            _progressCallbacks[videoId]?.call(progress);
          }
        },
      );

      // Save to Hive
      final box = Hive.box('downloads');
      final updatedSong = song.copyWith(
        isDownloaded: true,
        localPath: filePath,
      );
      await box.put(videoId, updatedSong.toJson());

      _progressMap.remove(videoId);
      _cancelTokens.remove(videoId);

      return updatedSong;
    } catch (e) {
      _progressMap.remove(videoId);
      _cancelTokens.remove(videoId);
      if (e is DioException && CancelToken.isCancel(e)) {
        return null; // Cancelled
      }
      rethrow;
    }
  }

  void cancelDownload(String videoId) {
    _cancelTokens[videoId]?.cancel('User cancelled');
    _cancelTokens.remove(videoId);
    _progressMap.remove(videoId);
  }

  Future<List<SongModel>> getDownloadedSongs() async {
    final box = Hive.box('downloads');
    return box.values
        .map((v) => SongModel.fromJson(Map<String, dynamic>.from(v)))
        .where((s) => s.isDownloaded)
        .toList();
  }

  Future<void> deleteDownload(String videoId) async {
    final box = Hive.box('downloads');
    final data = box.get(videoId);
    if (data != null) {
      final song = SongModel.fromJson(Map<String, dynamic>.from(data));
      if (song.localPath != null) {
        final file = File(song.localPath!);
        if (await file.exists()) await file.delete();
      }
      await box.delete(videoId);
    }
  }

  Future<int> getTotalDownloadSize() async {
    final songs = await getDownloadedSongs();
    int totalBytes = 0;
    for (final song in songs) {
      if (song.localPath != null) {
        final file = File(song.localPath!);
        if (await file.exists()) {
          totalBytes += await file.length();
        }
      }
    }
    return totalBytes;
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

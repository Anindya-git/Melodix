import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../services/audio_handler.dart';
import '../services/music_api_service.dart';

// ─────────────────────────────────────────────
// AUDIO HANDLER
// ─────────────────────────────────────────────

final audioHandlerProvider = Provider<MelodixAudioHandler>((ref) {
  final handler = MelodixAudioHandler();
  ref.onDispose(() => handler.dispose());
  return handler;
});

// ─────────────────────────────────────────────
// MUSIC API
// ─────────────────────────────────────────────

final musicApiProvider = Provider<MelodixApiService>((ref) {
  final api = MelodixApiService();
  ref.onDispose(() => api.dispose());
  return api;
});

// ─────────────────────────────────────────────
// CURRENT SONG
// ─────────────────────────────────────────────

final currentSongProvider =
    StreamProvider<SongModel?>((ref) {
  return ref.read(audioHandlerProvider).currentSongStream;
});

// ─────────────────────────────────────────────
// SEARCH
// ─────────────────────────────────────────────

class SearchNotifier extends StateNotifier<AsyncValue<List<SongModel>>> {
  final MelodixApiService _api;

  SearchNotifier(this._api) : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final results = await _api.search(query);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data([]);
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, AsyncValue<List<SongModel>>>(
  (ref) => SearchNotifier(ref.read(musicApiProvider)),
);

// ─────────────────────────────────────────────
// TRENDING
// ─────────────────────────────────────────────

final trendingProvider =
    FutureProvider<List<SongModel>>((ref) async {
  return ref.read(musicApiProvider).getTrending();
});

// ─────────────────────────────────────────────
// LIKED SONGS
// ─────────────────────────────────────────────

class LikedSongsNotifier extends StateNotifier<List<SongModel>> {
  LikedSongsNotifier() : super([]) {
    _loadLikedSongs();
  }

  void _loadLikedSongs() {
    final box = Hive.box<SongModel>('liked_songs');
    state = box.values.toList();
  }

  Future<void> toggleLike(SongModel song) async {
    final box = Hive.box<SongModel>('liked_songs');
    if (box.containsKey(song.id)) {
      await box.delete(song.id);
      state = state.where((s) => s.id != song.id).toList();
    } else {
      final liked = song.copyWith(isLiked: true);
      await box.put(song.id, liked);
      state = [...state, liked];
    }
  }

  bool isLiked(String songId) => state.any((s) => s.id == songId);
}

final likedSongsProvider =
    StateNotifierProvider<LikedSongsNotifier, List<SongModel>>(
  (ref) => LikedSongsNotifier(),
);

// ─────────────────────────────────────────────
// PLAYLISTS
// ─────────────────────────────────────────────

class PlaylistNotifier extends StateNotifier<List<PlaylistModel>> {
  PlaylistNotifier() : super([]) {
    _loadPlaylists();
  }

  void _loadPlaylists() {
    final box = Hive.box<PlaylistModel>('playlists');
    state = box.values.toList();
  }

  Future<PlaylistModel> createPlaylist(String name,
      {String? description}) async {
    final box = Hive.box<PlaylistModel>('playlists');
    final playlist = PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
    );
    await box.put(playlist.id, playlist);
    state = [...state, playlist];
    return playlist;
  }

  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    final box = Hive.box<PlaylistModel>('playlists');
    final playlist = box.get(playlistId);
    if (playlist == null) return;
    if (!playlist.songs.any((s) => s.id == song.id)) {
      playlist.songs.add(song);
      await playlist.save();
      state = state.map((p) => p.id == playlistId ? playlist : p).toList();
    }
  }

  Future<void> removeSongFromPlaylist(
      String playlistId, String songId) async {
    final box = Hive.box<PlaylistModel>('playlists');
    final playlist = box.get(playlistId);
    if (playlist == null) return;
    playlist.songs.removeWhere((s) => s.id == songId);
    await playlist.save();
    state = state.map((p) => p.id == playlistId ? playlist : p).toList();
  }

  Future<void> deletePlaylist(String playlistId) async {
    final box = Hive.box<PlaylistModel>('playlists');
    await box.delete(playlistId);
    state = state.where((p) => p.id != playlistId).toList();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final box = Hive.box<PlaylistModel>('playlists');
    final playlist = box.get(playlistId);
    if (playlist == null) return;
    playlist.name = newName;
    await playlist.save();
    state = state.map((p) => p.id == playlistId ? playlist : p).toList();
  }
}

final playlistProvider =
    StateNotifierProvider<PlaylistNotifier, List<PlaylistModel>>(
  (ref) => PlaylistNotifier(),
);

// ─────────────────────────────────────────────
// RECENT SONGS
// ─────────────────────────────────────────────

class RecentSongsNotifier extends StateNotifier<List<SongModel>> {
  static const int maxRecent = 50;

  RecentSongsNotifier() : super([]) {
    _load();
  }

  void _load() {
    final box = Hive.box<SongModel>('recent_songs');
    state = box.values.toList().reversed.toList();
  }

  Future<void> addRecent(SongModel song) async {
    final box = Hive.box<SongModel>('recent_songs');
    // Remove if exists
    await box.delete(song.id);
    // Add to top
    await box.put(song.id, song);
    // Trim to max
    if (box.length > maxRecent) {
      final keys = box.keys.toList();
      await box.delete(keys.first);
    }
    state = box.values.toList().reversed.toList();
  }

  Future<void> clearRecent() async {
    final box = Hive.box<SongModel>('recent_songs');
    await box.clear();
    state = [];
  }
}

final recentSongsProvider =
    StateNotifierProvider<RecentSongsNotifier, List<SongModel>>(
  (ref) => RecentSongsNotifier(),
);

// ─────────────────────────────────────────────
// QUEUE
// ─────────────────────────────────────────────

final queueProvider = StreamProvider<List<SongModel>>((ref) {
  return ref.read(audioHandlerProvider).queueStream;
});

// ─────────────────────────────────────────────
// SETTINGS
// ─────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  SettingsNotifier()
      : super({
          'audioQuality': 'high',
          'downloadQuality': 'high',
          'crossfade': true,
          'crossfadeDuration': 3,
          'normalizeVolume': true,
          'showLyrics': true,
          'lastFmEnabled': false,
          'lastFmUsername': '',
          'region': 'IN',
          'autoPlay': true,
          'wifiOnly': false,
        }) {
    _load();
  }

  void _load() {
    final box = Hive.box('settings');
    final saved = box.toMap().cast<String, dynamic>();
    if (saved.isNotEmpty) state = {...state, ...saved};
  }

  Future<void> set(String key, dynamic value) async {
    final box = Hive.box('settings');
    await box.put(key, value);
    state = {...state, key: value};
  }

  T get<T>(String key) => state[key] as T;
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>(
  (ref) => SettingsNotifier(),
);

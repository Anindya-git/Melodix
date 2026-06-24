import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import '../models/song_model.dart';
import 'music_api_service.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class MelodixAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _api = MelodixApiService();

  List<SongModel> _queue = [];
  int _currentIndex = 0;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _shuffleMode = false;
  List<int> _shuffledIndices = [];

  // Stream controllers
  final _currentSongController =
      BehaviorSubject<SongModel?>.seeded(null);
  final _queueController =
      BehaviorSubject<List<SongModel>>.seeded([]);
  final _isLoadingController = BehaviorSubject<bool>.seeded(false);

  Stream<SongModel?> get currentSongStream => _currentSongController.stream;
  Stream<List<SongModel>> get queueStream => _queueController.stream;
  Stream<bool> get isLoadingStream => _isLoadingController.stream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream =>
      _player.bufferedPositionStream;

  SongModel? get currentSong => _currentSongController.value;
  List<SongModel> get currentQueue => _queueController.value;
  bool get isPlaying => _player.playing;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffleMode => _shuffleMode;
  int get currentIndex => _currentIndex;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  MelodixAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  // ─────────────────────────────────────────────
  // PLAYBACK CONTROLS
  // ─────────────────────────────────────────────

  Future<void> playSong(SongModel song,
      {List<SongModel>? queue, int index = 0}) async {
    if (queue != null) {
      _queue = queue;
      _currentIndex = index;
      _queueController.add(_queue);
      if (_shuffleMode) _generateShuffledIndices();
    } else if (!_queue.contains(song)) {
      _queue.add(song);
      _currentIndex = _queue.length - 1;
      _queueController.add(_queue);
    } else {
      _currentIndex = _queue.indexOf(song);
    }

    await _loadAndPlay(song);
  }

  Future<void> _loadAndPlay(SongModel song) async {
    _isLoadingController.add(true);
    _currentSongController.add(song);

    // Update media item for notification
    mediaItem.add(MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      artUri: Uri.parse(song.thumbnailUrl),
      duration: Duration(seconds: song.duration),
    ));

    try {
      String? url;

      // Use local file if downloaded
      if (song.isDownloaded && song.localPath != null) {
        url = song.localPath;
        await _player.setFilePath(url!);
      } else {
        // Fetch stream URL
        url = await _api.getAudioStreamUrl(song.videoId ?? song.id);
        if (url == null) throw Exception('No stream URL available');
        await _player.setUrl(url);
      }

      await _player.play();
    } catch (e) {
      _isLoadingController.add(false);
      rethrow;
    }

    _isLoadingController.add(false);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final next = _getNextIndex();
    if (next != null) {
      _currentIndex = next;
      await _loadAndPlay(_queue[_currentIndex]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // If > 3 seconds played, restart current song
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    final prev = _getPrevIndex();
    if (prev != null) {
      _currentIndex = prev;
      await _loadAndPlay(_queue[_currentIndex]);
    }
  }

  Future<void> skipToIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _loadAndPlay(_queue[_currentIndex]);
  }

  // ─────────────────────────────────────────────
  // QUEUE MANAGEMENT
  // ─────────────────────────────────────────────

  void addToQueue(SongModel song) {
    _queue.add(song);
    _queueController.add(_queue);
  }

  void addNextInQueue(SongModel song) {
    _queue.insert(_currentIndex + 1, song);
    _queueController.add(_queue);
  }

  void removeFromQueue(int index) {
    if (index == _currentIndex) return;
    _queue.removeAt(index);
    if (index < _currentIndex) _currentIndex--;
    _queueController.add(_queue);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);
    _queueController.add(_queue);
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = 0;
    _queueController.add(_queue);
    stop();
  }

  // ─────────────────────────────────────────────
  // SHUFFLE & REPEAT
  // ─────────────────────────────────────────────

  void toggleShuffle() {
    _shuffleMode = !_shuffleMode;
    if (_shuffleMode) _generateShuffledIndices();
  }

  void cycleRepeatMode() {
    _repeatMode = RepeatMode
        .values[(_repeatMode.index + 1) % RepeatMode.values.length];
  }

  void _generateShuffledIndices() {
    _shuffledIndices = List.generate(_queue.length, (i) => i);
    _shuffledIndices.shuffle();
    // Ensure current song is first
    _shuffledIndices.remove(_currentIndex);
    _shuffledIndices.insert(0, _currentIndex);
  }

  int? _getNextIndex() {
    if (_queue.isEmpty) return null;
    if (_repeatMode == RepeatMode.one) return _currentIndex;

    if (_shuffleMode && _shuffledIndices.isNotEmpty) {
      final currentPos = _shuffledIndices.indexOf(_currentIndex);
      if (currentPos < _shuffledIndices.length - 1) {
        return _shuffledIndices[currentPos + 1];
      }
      if (_repeatMode == RepeatMode.all) return _shuffledIndices[0];
      return null;
    }

    if (_currentIndex < _queue.length - 1) return _currentIndex + 1;
    if (_repeatMode == RepeatMode.all) return 0;
    return null;
  }

  int? _getPrevIndex() {
    if (_queue.isEmpty) return null;
    if (_shuffleMode && _shuffledIndices.isNotEmpty) {
      final currentPos = _shuffledIndices.indexOf(_currentIndex);
      if (currentPos > 0) return _shuffledIndices[currentPos - 1];
      return null;
    }
    if (_currentIndex > 0) return _currentIndex - 1;
    if (_repeatMode == RepeatMode.all) return _queue.length - 1;
    return null;
  }

  Future<void> _handleSongCompletion() async {
    final next = _getNextIndex();
    if (next != null) {
      _currentIndex = next;
      await _loadAndPlay(_queue[_currentIndex]);
    }
  }

  // ─────────────────────────────────────────────
  // EQUALIZER / SPEED / PITCH
  // ─────────────────────────────────────────────

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
  Future<void> setPitch(double pitch) => _player.setPitch(pitch);
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  // ─────────────────────────────────────────────
  // SLEEP TIMER
  // ─────────────────────────────────────────────

  void setSleepTimer(Duration duration) {
    Future.delayed(duration, () async {
      await pause();
    });
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _currentSongController.close();
    await _queueController.close();
    await _isLoadingController.close();
  }
}

enum RepeatMode { none, all, one }

import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class SongModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String album;

  @HiveField(4)
  final String thumbnailUrl;

  @HiveField(5)
  final String? audioUrl;

  @HiveField(6)
  final int duration; // in seconds

  @HiveField(7)
  final String source; // 'youtube', 'local', 'piped'

  @HiveField(8)
  final String? videoId;

  @HiveField(9)
  final int? viewCount;

  @HiveField(10)
  bool isLiked;

  @HiveField(11)
  bool isDownloaded;

  @HiveField(12)
  String? localPath;

  @HiveField(13)
  final String? genre;

  @HiveField(14)
  final String? year;

  @HiveField(15)
  final double? rating;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.thumbnailUrl,
    this.audioUrl,
    required this.duration,
    required this.source,
    this.videoId,
    this.viewCount,
    this.isLiked = false,
    this.isDownloaded = false,
    this.localPath,
    this.genre,
    this.year,
    this.rating,
  });

  String get durationString {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? thumbnailUrl,
    String? audioUrl,
    int? duration,
    String? source,
    String? videoId,
    int? viewCount,
    bool? isLiked,
    bool? isDownloaded,
    String? localPath,
    String? genre,
    String? year,
    double? rating,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      source: source ?? this.source,
      videoId: videoId ?? this.videoId,
      viewCount: viewCount ?? this.viewCount,
      isLiked: isLiked ?? this.isLiked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'thumbnailUrl': thumbnailUrl,
        'audioUrl': audioUrl,
        'duration': duration,
        'source': source,
        'videoId': videoId,
        'viewCount': viewCount,
        'isLiked': isLiked,
        'isDownloaded': isDownloaded,
        'localPath': localPath,
        'genre': genre,
        'year': year,
        'rating': rating,
      };

  factory SongModel.fromJson(Map<String, dynamic> json) => SongModel(
        id: json['id'],
        title: json['title'],
        artist: json['artist'],
        album: json['album'] ?? '',
        thumbnailUrl: json['thumbnailUrl'] ?? '',
        audioUrl: json['audioUrl'],
        duration: json['duration'] ?? 0,
        source: json['source'] ?? 'youtube',
        videoId: json['videoId'],
        viewCount: json['viewCount'],
        isLiked: json['isLiked'] ?? false,
        isDownloaded: json['isDownloaded'] ?? false,
        localPath: json['localPath'],
        genre: json['genre'],
        year: json['year'],
        rating: json['rating']?.toDouble(),
      );
}

import 'package:hive/hive.dart';
import 'song_model.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 1)
class PlaylistModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? coverUrl;

  @HiveField(4)
  List<SongModel> songs;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  bool isPublic;

  PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    List<SongModel>? songs,
    DateTime? createdAt,
    this.isPublic = false,
  })  : songs = songs ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get songCount => songs.length;

  int get totalDuration =>
      songs.fold(0, (sum, song) => sum + song.duration);

  String get totalDurationString {
    final total = totalDuration;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    if (hours > 0) return '$hours hr $minutes min';
    return '$minutes min';
  }

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    List<SongModel>? songs,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      songs: songs ?? this.songs,
      createdAt: createdAt,
      isPublic: isPublic,
    );
  }
}

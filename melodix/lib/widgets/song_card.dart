import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';

class SongCard extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final double width;

  const SongCard({
    super.key,
    required this.song,
    required this.onTap,
    this.width = 140,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: width,
                height: width,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.darkCard,
                  child: const Center(
                    child: Icon(Icons.music_note_rounded,
                        color: Color(0xFF6B6B6B), size: 40),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.darkCard,
                  child: const Center(
                    child: Icon(Icons.music_note_rounded,
                        color: Color(0xFF6B6B6B), size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8A8A8A),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

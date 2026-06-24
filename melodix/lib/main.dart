import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'models/song_model.dart';
import 'models/playlist_model.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize audio background service
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.melodix.app.channel.audio',
    androidNotificationChannelName: 'Melodix Audio',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
    androidNotificationIcon: 'drawable/ic_notification',
    notificationColor: const Color(0xFF1DB954),
  );

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(SongModelAdapter());
  Hive.registerAdapter(PlaylistModelAdapter());
  await Hive.openBox<SongModel>('liked_songs');
  await Hive.openBox<SongModel>('recent_songs');
  await Hive.openBox<PlaylistModel>('playlists');
  await Hive.openBox('settings');
  await Hive.openBox('downloads');

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: MelodixApp()));
}

class MelodixApp extends ConsumerWidget {
  const MelodixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Melodix',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

# 🎵 Melodix — Complete Build Guide

## What You're Building

**Melodix** is a full-featured Android music player with:
- 🎶 YouTube Music streaming (no API key needed — uses public Piped instances)
- 🔥 Trending charts + curated playlists (Bollywood, Lo-Fi, Hip-Hop, K-Pop, etc.)
- 🔍 Real-time search across millions of songs
- ❤️ Like songs, create playlists, manage your library
- 📥 Offline downloads with progress tracking
- 🎤 Synced + plain lyrics (via LRCLib & lyrics.ovh)
- 🔀 Shuffle, repeat modes (all / one / off)
- ⏱ Sleep timer, playback speed control, volume normalization
- 📳 Background playback + lock-screen controls + notification player
- 🎨 Dynamic color theming from album art
- 🌙 Dark / Light / System theme

---

## Prerequisites

### 1. Install Flutter SDK

```bash
# Linux / macOS
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Windows — download from:
# https://docs.flutter.dev/get-started/install/windows
```

Verify:
```bash
flutter --version   # should show Flutter 3.10+
flutter doctor      # fix any issues it reports
```

### 2. Install Android Studio + SDK

- Download: https://developer.android.com/studio
- During setup, install:
  - **Android SDK Platform 34**
  - **Android SDK Build-Tools 34.0.0**
  - **Android Emulator** (optional, for testing)

After install, set path:
```bash
# Add to ~/.bashrc or ~/.zshrc
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### 3. Accept Android Licenses
```bash
flutter doctor --android-licenses
# Press 'y' for all prompts
```

---

## Build Steps

### Step 1 — Get the Project

The `melodix/` folder contains all source code. Place it wherever you like:

```bash
cd ~/Desktop
# (copy the melodix folder here)
cd melodix
```

### Step 2 — Install Dependencies

```bash
flutter pub get
```

This downloads all packages (~50 MB). Wait for it to complete.

### Step 3 — Generate Hive Adapters

The Hive database adapters are already pre-generated in the repo (the `.g.dart` files), so you can **skip** running `build_runner`. But if you ever modify the models:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 4 — Add App Icons (Optional but recommended)

Replace the placeholder icons with a real icon:
```bash
# Put your 1024x1024 PNG icon at:  assets/icons/app_icon.png
# Then run:
flutter pub add flutter_launcher_icons
# Add to pubspec.yaml under flutter_icons: ... then:
flutter pub run flutter_launcher_icons
```

Or skip this — the app will use the default Flutter icon.

### Step 5 — Build the APK

#### Debug APK (for testing — larger file, no signing needed):
```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

#### Release APK (smaller, optimized — recommended):
```bash
flutter build apk --release --split-per-abi
```
Output files:
```
build/app/outputs/flutter-apk/
  app-armeabi-v7a-release.apk   ← 32-bit ARM (older phones)
  app-arm64-v8a-release.apk     ← 64-bit ARM (most modern phones ✓)
  app-x86_64-release.apk        ← 64-bit x86 (emulators)
```

**For most Android phones → use `app-arm64-v8a-release.apk`**

#### Universal APK (one file works on all devices):
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk` (~35–50 MB)

---

## Install on Your Phone

### Method A — Direct USB Transfer
1. Enable **Developer Options** on your phone:
   - Go to `Settings → About Phone`
   - Tap **Build Number** 7 times
2. Enable **USB Debugging** in Developer Options
3. Connect phone via USB
4. Run:
   ```bash
   flutter install
   # OR
   adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```

### Method B — File Transfer (no USB debugging needed)
1. Copy the APK to your phone (via USB, Google Drive, Telegram, email, etc.)
2. On phone: `Settings → Security → Install Unknown Apps` → Allow your file manager
3. Open the APK file → Install

### Method C — Wireless ADB (same Wi-Fi)
```bash
adb connect <your-phone-ip>:5555
adb install path/to/app.apk
```

---

## Signing the APK (for permanent install / sharing)

The release build uses debug signing by default which is fine for personal use. For proper release signing:

### Create a Keystore
```bash
keytool -genkey -v \
  -keystore ~/melodix-key.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias melodix
```

### Create `android/key.properties`
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=melodix
storeFile=/home/yourname/melodix-key.jks
```

### Update `android/app/build.gradle` — add before `buildTypes`:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

Then rebuild:
```bash
flutter build apk --release
```

---

## Project Structure

```
melodix/
├── lib/
│   ├── main.dart                    ← App entry point
│   ├── theme/
│   │   └── app_theme.dart           ← Colors, typography, dark theme
│   ├── models/
│   │   ├── song_model.dart          ← Song data model (Hive)
│   │   └── playlist_model.dart      ← Playlist data model (Hive)
│   ├── services/
│   │   ├── music_api_service.dart   ← YouTube/Piped API (search, stream, lyrics)
│   │   ├── audio_handler.dart       ← Playback engine (just_audio + audio_service)
│   │   └── download_service.dart    ← Offline download manager
│   ├── providers/
│   │   ├── music_providers.dart     ← Riverpod state (search, liked, playlists, queue)
│   │   └── theme_provider.dart      ← Theme mode state
│   ├── screens/
│   │   ├── splash_screen.dart       ← Animated splash
│   │   ├── home/home_screen.dart    ← Bottom nav shell
│   │   ├── discover/                ← Home feed, trending, featured
│   │   ├── search/                  ← Search + browse categories
│   │   ├── library/                 ← Playlists, liked songs, downloads
│   │   ├── player/                  ← Full-screen player with dynamic colors
│   │   ├── queue/                   ← Reorderable play queue
│   │   ├── lyrics/                  ← Synced + plain lyrics view
│   │   └── settings/                ← All app settings
│   └── widgets/
│       ├── mini_player.dart         ← Persistent bottom mini player
│       ├── song_card.dart           ← Horizontal card for carousels
│       ├── song_list_tile.dart      ← Vertical list row with actions
│       ├── section_header.dart      ← "See all" section titles
│       └── genre_chip.dart          ← Filter chips
└── android/
    ├── app/
    │   ├── build.gradle             ← App-level Gradle config
    │   ├── proguard-rules.pro       ← Release build rules
    │   └── src/main/
    │       ├── AndroidManifest.xml  ← Permissions + services
    │       ├── kotlin/.../MainActivity.kt
    │       └── res/
    │           ├── drawable/        ← Notification icon, splash bg
    │           └── values/          ← Styles
    ├── build.gradle                 ← Project-level Gradle
    ├── gradle.properties
    └── settings.gradle
```

---

## How the Streaming Works

Melodix uses **no paid APIs** and **no official YouTube API key**:

1. **Primary**: [Piped](https://github.com/TeamPiped/Piped) — an open-source YouTube frontend with a public API. Multiple instances are used as fallbacks.
2. **Fallback**: [youtube_explode_dart](https://pub.dev/packages/youtube_explode_dart) — extracts audio streams directly from YouTube.
3. **Lyrics**: [LRCLib](https://lrclib.net) (synced .lrc format) → [lyrics.ovh](https://lyrics.ovh) (plain text fallback).

This is the same approach used by ViMusic, Bloomee, and ArchiveTune.

---

## Common Issues & Fixes

### "SDK not found"
```bash
flutter config --android-sdk /path/to/Android/Sdk
```

### Build fails with "Gradle version"
Edit `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.3-all.zip
```

### "minSdkVersion" error
The app requires Android 5.0+ (API 21). Check `android/app/build.gradle`.

### No sound / crashes on old devices
Switch from release to debug build for testing. Some MIUI/OneUI variants need battery optimization disabled for the app.

### "App not installed" error
- Uninstall any previous version first
- Make sure you picked the right ABI APK (arm64-v8a for most phones)

### Piped API down / no results
The app automatically rotates between 4 Piped instances. If all are down, the youtube_explode fallback kicks in.

---

## Customization Tips

### Change the App Name
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
android:label="Your App Name"
```

### Change Colors / Theme
Edit `lib/theme/app_theme.dart` — change `primaryGreen`, `accentPurple`, etc.

### Add More Curated Playlists
In `lib/services/music_api_service.dart`, add YouTube playlist IDs to `curatedPlaylists`:
```dart
'My Custom Playlist': 'PLxxxxxxxxxxxxxxxxxxxxxxxx',
```

### Change Default Region
In `lib/providers/music_providers.dart`, change `'region': 'IN'` to `'US'`, `'GB'`, etc.

---

## Requirements Summary

| Requirement | Minimum |
|-------------|---------|
| Flutter SDK | 3.10+ |
| Dart SDK | 3.0+ |
| Android SDK | API 34 (compile) |
| Android Device | API 21 (Android 5.0+) |
| Java | 11+ |
| RAM (build machine) | 8 GB recommended |
| Disk space | ~4 GB (SDK + build cache) |
| Internet | Required for streaming |

---

*Melodix is built for personal use. YouTube content is subject to YouTube's Terms of Service.*

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/music_providers.dart';
import '../../providers/theme_provider.dart';
import '../../services/download_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        title: const Text('Settings',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Profile Section ──────────────────────
          _buildSection('ACCOUNT', [
            ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.accentPurple,
                child: const Text('M',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ),
              title: const Text('Melodix User',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Free Plan',
                  style: TextStyle(color: Color(0xFF8A8A8A))),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('UPGRADE',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ]),

          // ── Audio Quality ────────────────────────
          _buildSection('AUDIO QUALITY', [
            _buildDropdownTile(
              icon: Icons.high_quality_outlined,
              title: 'Streaming Quality',
              value: settings['audioQuality'] as String,
              options: const ['low', 'medium', 'high'],
              labels: const ['Low (128kbps)', 'Medium (256kbps)', 'High (320kbps)'],
              onChanged: (v) => notifier.set('audioQuality', v),
            ),
            _buildDropdownTile(
              icon: Icons.download_outlined,
              title: 'Download Quality',
              value: settings['downloadQuality'] as String,
              options: const ['low', 'medium', 'high'],
              labels: const ['Low', 'Medium', 'High'],
              onChanged: (v) => notifier.set('downloadQuality', v),
            ),
            _buildSwitchTile(
              icon: Icons.volume_up_outlined,
              title: 'Volume Normalization',
              subtitle: 'Consistent volume across songs',
              value: settings['normalizeVolume'] as bool,
              onChanged: (v) => notifier.set('normalizeVolume', v),
            ),
            _buildSwitchTile(
              icon: Icons.wifi_outlined,
              title: 'Wi-Fi Only Downloads',
              subtitle: 'Save mobile data',
              value: settings['wifiOnly'] as bool,
              onChanged: (v) => notifier.set('wifiOnly', v),
            ),
          ]),

          // ── Crossfade ────────────────────────────
          _buildSection('PLAYBACK', [
            _buildSwitchTile(
              icon: Icons.merge_type_outlined,
              title: 'Crossfade',
              subtitle: 'Smooth transition between songs',
              value: settings['crossfade'] as bool,
              onChanged: (v) => notifier.set('crossfade', v),
            ),
            if (settings['crossfade'] as bool)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crossfade Duration: ${settings['crossfadeDuration']}s',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Slider(
                      value: (settings['crossfadeDuration'] as int).toDouble(),
                      min: 1,
                      max: 12,
                      divisions: 11,
                      label: '${settings['crossfadeDuration']}s',
                      onChanged: (v) =>
                          notifier.set('crossfadeDuration', v.toInt()),
                    ),
                  ],
                ),
              ),
            _buildSwitchTile(
              icon: Icons.play_circle_outline,
              title: 'Auto Play',
              subtitle: 'Continue playing similar songs',
              value: settings['autoPlay'] as bool,
              onChanged: (v) => notifier.set('autoPlay', v),
            ),
            _buildSwitchTile(
              icon: Icons.lyrics_outlined,
              title: 'Show Lyrics',
              subtitle: 'Display synced lyrics when available',
              value: settings['showLyrics'] as bool,
              onChanged: (v) => notifier.set('showLyrics', v),
            ),
          ]),

          // ── Appearance ───────────────────────────
          _buildSection('APPEARANCE', [
            Consumer(builder: (_, ref, __) {
              final themeMode = ref.watch(themeModeProvider);
              return ListTile(
                leading: const Icon(Icons.dark_mode_outlined,
                    color: Color(0xFF6B6B6B)),
                title: const Text('Theme',
                    style: TextStyle(color: Colors.white)),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.dark, label: Text('Dark')),
                    ButtonSegment(
                        value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(
                        value: ThemeMode.system, label: Text('Auto')),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (v) => ref
                      .read(themeModeProvider.notifier)
                      .setTheme(v.first),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppTheme.primaryGreen;
                      }
                      return AppTheme.darkCard;
                    }),
                  ),
                ),
              );
            }),
          ]),

          // ── Region ──────────────────────────────
          _buildSection('CONTENT', [
            _buildDropdownTile(
              icon: Icons.public_outlined,
              title: 'Region',
              value: settings['region'] as String,
              options: const ['IN', 'US', 'GB', 'JP', 'KR', 'DE', 'FR'],
              labels: const [
                'India', 'United States', 'United Kingdom',
                'Japan', 'South Korea', 'Germany', 'France'
              ],
              onChanged: (v) => notifier.set('region', v),
            ),
          ]),

          // ── Storage ──────────────────────────────
          _buildSection('STORAGE', [
            FutureBuilder<int>(
              future: DownloadService().getTotalDownloadSize(),
              builder: (_, snap) {
                final size = DownloadService()
                    .formatSize(snap.data ?? 0);
                return ListTile(
                  leading: const Icon(Icons.storage_outlined,
                      color: Color(0xFF6B6B6B)),
                  title: const Text('Downloaded Music',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('$size used',
                      style: const TextStyle(
                          color: Color(0xFF8A8A8A))),
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('Manage',
                        style: TextStyle(color: AppTheme.primaryGreen)),
                  ),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Color(0xFF6B6B6B)),
              title: const Text('Clear Cache',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
            ),
          ]),

          // ── About ───────────────────────────────
          _buildSection('ABOUT', [
            const ListTile(
              leading: Icon(Icons.info_outline, color: Color(0xFF6B6B6B)),
              title: Text('Version',
                  style: TextStyle(color: Colors.white)),
              trailing: Text('1.0.0',
                  style: TextStyle(color: Color(0xFF8A8A8A))),
            ),
            const ListTile(
              leading: Icon(Icons.code_outlined, color: Color(0xFF6B6B6B)),
              title: Text('Open Source Licenses',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B6B6B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...children,
        const Divider(color: AppTheme.darkBorder, height: 1),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: const Color(0xFF6B6B6B)),
      title:
          Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style:
                  const TextStyle(color: Color(0xFF8A8A8A), fontSize: 12))
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryGreen,
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required List<String> labels,
    required Function(String) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B6B6B)),
      title:
          Text(title, style: const TextStyle(color: Colors.white)),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppTheme.darkCard,
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        items: List.generate(
          options.length,
          (i) => DropdownMenuItem(
            value: options[i],
            child: Text(labels[i]),
          ),
        ),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

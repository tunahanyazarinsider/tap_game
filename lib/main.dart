import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const TapCityApp());
}

class TapCityApp extends StatelessWidget {
  const TapCityApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapCity',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const GameScreen(),
    );
  }
}

// ─── GAME STYLE WIDGETS ──────────────────────────────────────

/// Game-style button with gradient fill + 3D bottom bevel
class GameButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color color;
  final double fontSize;
  final EdgeInsets padding;

  const GameButton({
    super.key, required this.text, this.onTap,
    this.color = const Color(0xFF4CAF50),
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final darkColor = HSLColor.fromColor(color).withLightness((HSLColor.fromColor(color).lightness - 0.15).clamp(0, 1)).toColor();
    final lightColor = HSLColor.fromColor(color).withLightness((HSLColor.fromColor(color).lightness + 0.08).clamp(0, 1)).toColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: enabled ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [lightColor, color]) : null,
          color: enabled ? null : const Color(0xFF1A1A2A),
          borderRadius: BorderRadius.circular(5),
          border: enabled ? null : Border.all(color: Colors.white.withAlpha(10)),
          boxShadow: enabled ? [
            BoxShadow(color: darkColor, offset: const Offset(0, 3), blurRadius: 0), // bevel
            BoxShadow(color: color.withAlpha(40), blurRadius: 6), // glow
          ] : null,
        ),
        child: Text(text, style: TextStyle(
          color: enabled ? Colors.white : Colors.white24,
          fontSize: fontSize, fontWeight: FontWeight.w800,
          shadows: enabled ? [Shadow(color: Colors.black.withAlpha(80), blurRadius: 2, offset: const Offset(0, 1))] : null,
        )),
      ),
    );
  }
}

/// Game-style container — dark with subtle border, slightly raised
class GamePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  const GamePanel({super.key, required this.child, this.padding = const EdgeInsets.all(10), this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF141828), Color(0xFF0D1520)]),
        border: Border.all(color: borderColor ?? Colors.white.withAlpha(12)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Color(0x20000000), offset: Offset(0, 2), blurRadius: 4)],
      ),
      child: child,
    );
  }
}

// ─── SOUND ENGINE ────────────────────────────────────────────

class SoundEngine {
  final _players = <String, AudioPlayer>{};
  final _files = <String, String>{}; // key -> file path
  AudioPlayer? _ambientPlayer;
  String? _tempDir;
  bool ready = false;

  Future<void> init() async {
    try {
      final dir = await getTemporaryDirectory();
      _tempDir = dir.path;

      // Pre-generate all sound files to disk
      for (final name in ['tap', 'coin', 'buy', 'upgrade', 'golden', 'combo5', 'combo10', 'combo20', 'prestige']) {
        _players[name] = AudioPlayer();
      }

      // Generate and save each sound as a WAV file
      await _saveWav('tap', _genTap(0.06));
      await _saveWav('coin', _genCoinClink(0.15));
      await _saveWav('buy', _genKaChing(0.35));
      await _saveWav('upgrade', _genChime(1200, 0.25));
      await _saveWav('golden', _genSparkle(1500, 0.4));
      await _saveWav('prestige', _genPrestige(0.8));
      await _saveWav('combo5', _genChime(880, 0.2));
      await _saveWav('combo10', _genChime(1100, 0.25));
      await _saveWav('combo20', _genChime(1400, 0.3));
      await _saveWav('ambient', _genAmbientV2(12.0));

      // Start ambient loop
      _ambientPlayer = AudioPlayer();
      await _ambientPlayer!.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer!.setVolume(0.15);
      await _ambientPlayer!.play(DeviceFileSource(_files['ambient']!));

      ready = true;
    } catch (e) {
      debugPrint('SoundEngine init error: $e');
    }
  }

  Future<void> _saveWav(String name, Uint8List data) async {
    final path = '$_tempDir/tapcity_$name.wav';
    await File(path).writeAsBytes(data);
    _files[name] = path;
  }

  void _play(String key, {double volume = 0.5, double rate = 1.0}) {
    if (!ready) return;
    final path = _files[key];
    if (path == null) return;
    try {
      final player = _players[key];
      player?.setVolume(volume);
      player?.setPlaybackRate(rate);
      player?.play(DeviceFileSource(path));
    } catch (_) {}
  }

  void playTap(int combo) {
    final rate = 0.9 + combo.clamp(0, 25) * 0.04;
    _play('tap', volume: 0.5, rate: rate);
    _play('coin', volume: 0.3, rate: 0.9 + combo.clamp(0, 20) * 0.03); // coin clink layered

    if (combo == 5) _play('combo5', volume: 0.5);
    if (combo == 10) _play('combo10', volume: 0.5);
    if (combo == 20) _play('combo20', volume: 0.6);
    if (combo == 50) _play('combo20', volume: 0.7, rate: 1.3);
  }

  void playBuy() => _play('buy', volume: 0.5);
  void playUpgrade() => _play('upgrade', volume: 0.5);
  void playGolden() => _play('golden', volume: 0.7);
  void playPrestige() => _play('prestige', volume: 0.8);

  // ─── WAV generation ─────────────────────────────────────────

  // 3-layer tap click: transient snap + tonal body + sub thud
  Uint8List _genTap(double dur) {
    const sr = 22050;
    final n = (sr * dur).toInt();
    final d = ByteData(44 + n * 2);
    _hdr(d, n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      // Layer 1: Transient click (3500→800Hz sweep in 5ms)
      final clickFreq = 3500 * (1 - (t / 0.005).clamp(0, 1)) + 800;
      final clickEnv = (1 - t / 0.008).clamp(0, 1);
      final click = sin(2 * pi * clickFreq * t) * clickEnv * 0.3;
      // Layer 2: Tonal body (1000Hz + harmonics, 50ms decay)
      final bodyEnv = (1 - t / 0.05).clamp(0, 1);
      final body = (sin(2 * pi * 1000 * t) * 0.7 + sin(2 * pi * 2000 * t) * 0.2 + sin(2 * pi * 3000 * t) * 0.1) * bodyEnv * 0.5;
      // Layer 3: Sub bass thud (80Hz, 30ms)
      final thudEnv = (1 - t / 0.03).clamp(0, 1);
      final thud = sin(2 * pi * 80 * t) * thudEnv * 0.2;
      final s = ((click + body + thud) * 16000).toInt().clamp(-32768, 32767);
      d.setInt16(44 + i * 2, s, Endian.little);
    }
    return d.buffer.asUint8List();
  }

  // Metallic coin clink with inharmonic partials
  Uint8List _genCoinClink(double dur) {
    const sr = 22050;
    final n = (sr * dur).toInt();
    final d = ByteData(44 + n * 2);
    _hdr(d, n);
    final rng = Random(42);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      // Noise burst transient (first 2ms)
      final noiseBurst = t < 0.002 ? (rng.nextDouble() - 0.5) * (1 - t / 0.002) : 0.0;
      // Inharmonic partials (metallic ring)
      final env = (1 - t / dur).clamp(0, 1) * (1 - t / dur).clamp(0, 1); // squared decay
      final base = 4200.0;
      final ring = sin(2 * pi * base * t) * 0.4 +
          sin(2 * pi * base * 1.65 * t) * 0.25 +
          sin(2 * pi * base * 2.76 * t) * 0.2 +
          sin(2 * pi * base * 3.52 * t) * 0.15;
      final s = ((noiseBurst * 0.4 + ring * env * 0.6) * 10000).toInt().clamp(-32768, 32767);
      d.setInt16(44 + i * 2, s, Endian.little);
    }
    return d.buffer.asUint8List();
  }

  // Ka-Ching purchase sound: mechanical clunk then bell ring
  Uint8List _genKaChing(double dur) {
    const sr = 22050;
    final n = (sr * dur).toInt();
    final d = ByteData(44 + n * 2);
    _hdr(d, n);
    final rng = Random(77);
    final mid = (sr * 0.08).toInt(); // 80ms split
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      double wave;
      if (i < mid) {
        // Phase 1: "Ka" — mechanical clunk
        final clunkEnv = (1 - t / 0.08).clamp(0, 1);
        wave = (sin(2 * pi * 200 * t) * 0.5 + (rng.nextDouble() - 0.5) * 0.3) * clunkEnv;
      } else {
        // Phase 2: "Ching" — bell ring
        final t2 = t - 0.08;
        final bellEnv = (1 - t2 / (dur - 0.08)).clamp(0, 1);
        wave = (sin(2 * pi * 3000 * t2) * 0.5 + sin(2 * pi * 6000 * t2) * 0.25 + sin(2 * pi * 9000 * t2) * 0.15) * bellEnv;
      }
      final s = (wave * 10000).toInt().clamp(-32768, 32767);
      d.setInt16(44 + i * 2, s, Endian.little);
    }
    return d.buffer.asUint8List();
  }

  Uint8List _genChime(double baseFreq, double dur) {
    const sr = 22050;
    final n = (sr * dur).toInt();
    final d = ByteData(44 + n * 2);
    _hdr(d, n);
    final mid = n ~/ 2;
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final freq = i < mid ? baseFreq : baseFreq * 1.25;
      final localT = i < mid ? i / mid : (i - mid) / (n - mid);
      final env = (1 - localT) * 0.8 + 0.2;
      final atk = (i / (sr * 0.003)).clamp(0, 1);
      final wave = sin(2 * pi * freq * t) * 0.7 + sin(2 * pi * freq * 2 * t) * 0.3;
      final s = (wave * 10000 * env * atk).toInt().clamp(-32768, 32767);
      d.setInt16(44 + i * 2, s, Endian.little);
    }
    return d.buffer.asUint8List();
  }

  Uint8List _genSparkle(double baseFreq, double dur) {
    const sr = 22050;
    final n = (sr * dur).toInt();
    final d = ByteData(44 + n * 2);
    _hdr(d, n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final env = (1 - t / dur);
      final atk = (i / (sr * 0.002)).clamp(0, 1);
      final sweep = baseFreq + sin(t * 20) * 400;
      final wave = sin(2 * pi * sweep * t) * 0.5 + sin(2 * pi * sweep * 1.5 * t) * 0.3 + sin(2 * pi * sweep * 3 * t) * 0.2;
      final s = (wave * 8000 * env * atk).toInt().clamp(-32768, 32767);
      d.setInt16(44 + i * 2, s, Endian.little);
    }
    return d.buffer.asUint8List();
  }

  // City ambient: traffic hum + pink noise + periodic events (horns, birds, wind)
  Uint8List _genAmbientV2(double dur) {
    const sr = 22050;
    final n = (sr * dur).toInt();
    final d = ByteData(44 + n * 2);
    _hdr(d, n);
    final rng = Random(99);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      // Traffic hum with slow modulation
      final mod = 0.7 + 0.3 * sin(2 * pi * 0.15 * t);
      final hum = (sin(2 * pi * 60 * t) * 0.25 + sin(2 * pi * 95 * t) * 0.2 + sin(2 * pi * 140 * t) * 0.15 + sin(2 * pi * 200 * t) * 0.1) * mod;
      // Pink noise (filtered random)
      final noise = (rng.nextDouble() - 0.5) * 0.1;
      // Car horn (every ~5.7s, brief honk)
      final hornP = (t % 5.7) / 5.7;
      final horn = hornP < 0.015 ? sin(2 * pi * 440 * t) * (0.015 - hornP) * 30 * 0.15 : 0.0;
      // Bird chirp (every ~3.1s)
      final birdP = (t % 3.1) / 3.1;
      final bird = birdP < 0.02 ? sin(2 * pi * (2500 + sin(t * 40) * 500) * t) * (0.02 - birdP) * 25 * 0.12 : 0.0;
      // Second bird (every ~4.7s, different pitch)
      final bird2P = (t % 4.7) / 4.7;
      final bird2 = bird2P < 0.015 ? sin(2 * pi * 3200 * t) * (0.015 - bird2P) * 20 * 0.08 : 0.0;
      // Wind gust (every ~8.3s)
      final windP = (t % 8.3) / 8.3;
      final wind = windP < 0.1 ? (rng.nextDouble() - 0.5) * sin(windP / 0.1 * pi) * 0.15 : 0.0;
      final wave = hum + noise + horn + bird + bird2 + wind;
      // Crossfade loop
      double env = 1.0;
      if (t < 0.8) env = t / 0.8;
      if (t > dur - 0.8) env = (dur - t) / 0.8;
      final s = (wave * 4000 * env).toInt().clamp(-32768, 32767);
      d.setInt16(44 + i * 2, s, Endian.little);
    }
    return d.buffer.asUint8List();
  }

  Uint8List _genPrestige(double dur) {
    const sr = 22050;
    final n = (sr * dur).toInt();
    final d = ByteData(44 + n * 2);
    _hdr(d, n);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final env = (1 - t / dur).clamp(0, 1);
      final atk = (i / (sr * 0.005)).clamp(0, 1);
      final freqs = [523.25, 659.25, 783.99, 1046.5];
      final phase = (t / dur * freqs.length).floor().clamp(0, 3);
      final freq = freqs[phase];
      final wave = sin(2 * pi * freq * t) * 0.6 + sin(2 * pi * freq * 2 * t) * 0.25 + sin(2 * pi * freq * 3 * t) * 0.15;
      final s = (wave * 10000 * env * atk).toInt().clamp(-32768, 32767);
      d.setInt16(44 + i * 2, s, Endian.little);
    }
    return d.buffer.asUint8List();
  }

  void _hdr(ByteData d, int n) {
    const sr = 22050;
    void ws(int o, String s) { for (int i = 0; i < s.length; i++) d.setUint8(o + i, s.codeUnitAt(i)); }
    ws(0, 'RIFF');
    d.setUint32(4, 36 + n * 2, Endian.little);
    ws(8, 'WAVE'); ws(12, 'fmt ');
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little); d.setUint16(22, 1, Endian.little);
    d.setUint32(24, sr, Endian.little); d.setUint32(28, sr * 2, Endian.little);
    d.setUint16(32, 2, Endian.little); d.setUint16(34, 16, Endian.little);
    ws(36, 'data');
    d.setUint32(40, n * 2, Endian.little);
  }

  void dispose() {
    _ambientPlayer?.dispose();
    for (final p in _players.values) p.dispose();
  }
}

// ─── DATA ────────────────────────────────────────────────────

enum BShape { box, wide, tapered, dome }

class BuildingInfo {
  final String id, name;
  final IconData icon;
  final double baseCost, baseIncome, tapBonus;
  final double prodTime; // seconds per production cycle
  final int unlockAt;
  final List<Color> colors;
  final BShape shape;
  final double minH, maxH;
  final int row; // 0 = back (behind road), 1 = front (in front of road)
  const BuildingInfo({
    required this.id, required this.name, required this.icon,
    required this.baseCost, required this.baseIncome, required this.tapBonus,
    required this.prodTime,
    required this.unlockAt, required this.colors, this.shape = BShape.box,
    required this.minH, required this.maxH, this.row = 0,
  });
}

const allBuildings = [
  // Back row (behind road, taller buildings)
  BuildingInfo(id: 'lemonade', name: 'Lemonade', icon: Icons.local_drink, baseCost: 50, baseIncome: 1, tapBonus: 0.5, prodTime: 1, unlockAt: 0, shape: BShape.box, minH: 0.05, maxH: 0.13, row: 0, colors: [Color(0xFFFFF176), Color(0xFFFFEE58), Color(0xFFFDD835), Color(0xFFFBC02D), Color(0xFFF9A825)]),
  BuildingInfo(id: 'barber', name: 'Barber', icon: Icons.content_cut, baseCost: 300, baseIncome: 3, tapBonus: 1, prodTime: 2, unlockAt: 150, shape: BShape.box, minH: 0.06, maxH: 0.15, row: 0, colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9), Color(0xFF64B5F6), Color(0xFF42A5F5)]),
  BuildingInfo(id: 'coffee', name: 'Coffee', icon: Icons.coffee, baseCost: 1500, baseIncome: 8, tapBonus: 2, prodTime: 3, unlockAt: 800, shape: BShape.box, minH: 0.08, maxH: 0.20, row: 0, colors: [Color(0xFFBCAAA4), Color(0xFFA1887F), Color(0xFF8D6E63), Color(0xFF795548), Color(0xFF6D4C41)]),
  BuildingInfo(id: 'restaurant', name: 'Restaurant', icon: Icons.restaurant, baseCost: 8000, baseIncome: 30, tapBonus: 8, prodTime: 5, unlockAt: 4000, shape: BShape.wide, minH: 0.10, maxH: 0.26, row: 0, colors: [Color(0xFFEF9A9A), Color(0xFFE57373), Color(0xFFEF5350), Color(0xFFF44336), Color(0xFFD32F2F)]),
  BuildingInfo(id: 'mall', name: 'Mall', icon: Icons.shopping_bag, baseCost: 50000, baseIncome: 150, tapBonus: 30, prodTime: 8, unlockAt: 25000, shape: BShape.wide, minH: 0.09, maxH: 0.24, row: 0, colors: [Color(0xFF90CAF9), Color(0xFF64B5F6), Color(0xFF42A5F5), Color(0xFF2196F3), Color(0xFF1E88E5)]),
  BuildingInfo(id: 'hotel', name: 'Hotel', icon: Icons.hotel, baseCost: 500000, baseIncome: 800, tapBonus: 100, prodTime: 15, unlockAt: 250000, shape: BShape.dome, minH: 0.16, maxH: 0.48, row: 0, colors: [Color(0xFFCE93D8), Color(0xFFBA68C8), Color(0xFFAB47BC), Color(0xFF1A237E), Color(0xFF8E24AA)]),
  // Front row (in front of road, shorter/wider buildings)
  BuildingInfo(id: 'salon', name: 'Nails', icon: Icons.spa, baseCost: 5000, baseIncome: 20, tapBonus: 5, prodTime: 4, unlockAt: 2500, shape: BShape.wide, minH: 0.04, maxH: 0.10, row: 1, colors: [Color(0xFFF8BBD0), Color(0xFFF48FB1), Color(0xFFEC407A), Color(0xFFE91E63), Color(0xFFC2185B)]),
  BuildingInfo(id: 'gym', name: 'Gym', icon: Icons.fitness_center, baseCost: 30000, baseIncome: 100, tapBonus: 20, prodTime: 6, unlockAt: 15000, shape: BShape.wide, minH: 0.05, maxH: 0.12, row: 1, colors: [Color(0xFFFFCC80), Color(0xFFFFB74D), Color(0xFFFFA726), Color(0xFFFF9800), Color(0xFFEF6C00)]),
  BuildingInfo(id: 'cinema', name: 'Cinema', icon: Icons.movie, baseCost: 200000, baseIncome: 500, tapBonus: 60, prodTime: 10, unlockAt: 100000, shape: BShape.box, minH: 0.06, maxH: 0.14, row: 1, colors: [Color(0xFFCE93D8), Color(0xFFAB47BC), Color(0xFF8E24AA), Color(0xFF6A1B9A), Color(0xFF0D1B3E)]),
  BuildingInfo(id: 'hospital', name: 'Hospital', icon: Icons.local_hospital, baseCost: 2000000, baseIncome: 2000, tapBonus: 150, prodTime: 20, unlockAt: 1000000, shape: BShape.box, minH: 0.07, maxH: 0.16, row: 1, colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFF9E9E9E), Color(0xFF757575)]),
  BuildingInfo(id: 'stadium', name: 'Stadium', icon: Icons.stadium, baseCost: 20000000, baseIncome: 10000, tapBonus: 500, prodTime: 60, unlockAt: 10000000, shape: BShape.wide, minH: 0.05, maxH: 0.12, row: 1, colors: [Color(0xFFA5D6A7), Color(0xFF81C784), Color(0xFF66BB6A), Color(0xFF4CAF50), Color(0xFF388E3C)]),
  BuildingInfo(id: 'space', name: 'Space', icon: Icons.rocket_launch, baseCost: 200000000, baseIncome: 50000, tapBonus: 2000, prodTime: 120, unlockAt: 100000000, shape: BShape.tapered, minH: 0.10, maxH: 0.22, row: 1, colors: [Color(0xFFB0BEC5), Color(0xFF90A4AE), Color(0xFF78909C), Color(0xFF607D8B), Color(0xFF546E7A)]),
];

// Milestone thresholds: at N owned, income gets multiplied (stacks)
const milestoneThresholds = [
  (count: 25, multiplier: 3),
  (count: 50, multiplier: 3),
  (count: 100, multiplier: 3),
  (count: 200, multiplier: 9),
  (count: 300, multiplier: 9),
];

class AchievementReward {
  final double incomeMultPercent;
  final double coins;
  final double tapPower;
  const AchievementReward({this.incomeMultPercent = 0, this.coins = 0, this.tapPower = 0});
}

// Star shop removed — replaced by Reputation Level system

class PrestigeRank {
  final int tier;
  final String name;
  final int minPrestiges;
  final Color color;
  final IconData icon;
  const PrestigeRank({required this.tier, required this.name, required this.minPrestiges, required this.color, required this.icon});
}

const prestigeRanks = [
  PrestigeRank(tier: 0, name: 'Resident', minPrestiges: 0, color: Color(0xFF9E9E9E), icon: Icons.home_outlined),
  PrestigeRank(tier: 1, name: 'Planner', minPrestiges: 1, color: Color(0xFF66BB6A), icon: Icons.map_outlined),
  PrestigeRank(tier: 2, name: 'Contractor', minPrestiges: 3, color: Color(0xFF42A5F5), icon: Icons.construction),
  PrestigeRank(tier: 3, name: 'Architect', minPrestiges: 6, color: Color(0xFF5C6BC0), icon: Icons.architecture),
  PrestigeRank(tier: 4, name: 'Commissioner', minPrestiges: 10, color: Color(0xFF1A237E), icon: Icons.badge_outlined),
  PrestigeRank(tier: 5, name: 'Mayor', minPrestiges: 15, color: Color(0xFFFFB300), icon: Icons.account_balance),
  PrestigeRank(tier: 6, name: 'Governor', minPrestiges: 25, color: Color(0xFFFF8F00), icon: Icons.gavel),
  PrestigeRank(tier: 7, name: 'Magnate', minPrestiges: 40, color: Color(0xFFFFD600), icon: Icons.domain),
  PrestigeRank(tier: 8, name: 'Tycoon', minPrestiges: 60, color: Color(0xFFFFAB00), icon: Icons.corporate_fare),
  PrestigeRank(tier: 9, name: 'Visionary', minPrestiges: 100, color: Color(0xFFFFD600), icon: Icons.location_city),
];

class OwnedBuilding {
  final BuildingInfo info;
  int count;
  double constructionProgress;
  double craneProgress;
  double productionTimer = 0;   // counts up from 0 to prodTime
  double pendingMoney = 0;      // money waiting to be collected
  bool readyToCollect = false;  // true when timer fills
  OwnedBuilding(this.info, {this.count = 1, this.constructionProgress = 0.0, this.craneProgress = 0.0});

  int get tier {
    if (count >= 100) return 5;
    if (count >= 50) return 4;
    if (count >= 25) return 3;
    if (count >= 10) return 2;
    return 1;
  }

  Color get color => info.colors[(tier - 1).clamp(0, 4)];

  double get heightFraction {
    final t = (tier - 1) / 4.0;
    return (info.minH + (info.maxH - info.minH) * t) * constructionProgress;
  }

  bool get isBuilding => constructionProgress < 1.0;

  double get nextCost => info.baseCost * pow(1.15, count);

  // Diminishing returns: 100 buildings = ~50x income, not 100x
  double get baseIncomeTotal => info.baseIncome * pow(count, 0.9);

  double get milestoneMultiplier {
    double m = 1.0;
    for (final ms in milestoneThresholds) {
      if (count >= ms.count) m *= ms.multiplier;
    }
    return m;
  }

  double incomeWith(double globalMult) => baseIncomeTotal * milestoneMultiplier * globalMult;

  // Income per production cycle
  double incomePerCycle(double globalMult) => info.baseIncome * info.prodTime * pow(count, 0.9) * milestoneMultiplier * globalMult;

  // Timer progress 0→1
  double get timerProgress => (productionTimer / info.prodTime).clamp(0.0, 1.0);
}

// ─── EFFECTS ─────────────────────────────────────────────────

class FloatingCoin {
  Offset pos;
  double opacity = 1.0, scale = 0.3;
  final String text;
  final Color color;
  final double dx;
  FloatingCoin(this.pos, this.text, this.color) : dx = (Random().nextDouble() - 0.5) * 50;
}

class TapParticle {
  Offset pos, vel;
  double life = 1.0, size;
  Color color;
  TapParticle(this.pos, this.vel, this.color, this.size);
}

class TapRing {
  Offset pos;
  double radius = 0, opacity = 0.7;
  Color color;
  TapRing(this.pos, this.color);
}

class GoldenCoin {
  Offset pos;
  double life; // seconds remaining
  double bobPhase = 0;
  double glowPhase = 0;
  bool collected = false;
  GoldenCoin(this.pos, this.life);
}

class ComboRing {
  Offset pos;
  int comboNum;
  double life = 1.0;
  Color color;
  ComboRing(this.pos, this.comboNum, this.color);
}

class TapGlow {
  Offset pos;
  double life = 1.0;
  Color color;
  TapGlow(this.pos, this.color);
}

class BurstText {
  Offset pos;
  String text;
  double life = 1.0;
  Color color;
  double scale = 0.2;
  BurstText(this.pos, this.text, this.color);
}

class GroundRipple {
  double x;
  double life = 1.0;
  GroundRipple(this.x);
}

// ─── GAME SCREEN ─────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  double money = 0, totalEarned = 0, tapPower = 1;
  int playerLevel = 1;
  int combo = 0, totalTaps = 0, highestCombo = 0;
  double comboTimer = 0, displayedMoney = 0, flashOpacity = 0, playTime = 0;
  List<OwnedBuilding> ownedBuildings = [];
  List<FloatingCoin> floatingCoins = [];
  List<TapParticle> particles = [];
  List<TapRing> rings = [];
  List<ComboRing> comboRings = [];
  List<TapGlow> tapGlows = [];
  List<BurstText> burstTexts = [];
  GoldenCoin? goldenCoin;
  double goldenCoinTimer = 0;
  int selectedTab = 0;
  bool _showWelcomeBack = false;
  double _offlineEarnings = 0;
  Timer? _saveTimer;
  Set<int> claimedAchievements = {};
  Map<String, int> highestNotifiedMilestone = {};
  double achievementTapBonus = 0;

  // Prestige
  int totalRP = 0, totalPrestiges = 0; // Reputation Points — never spent, only accumulates
  double allTimeEarned = 0;
  int allTimeTaps = 0, allTimeHighestCombo = 0;
  // Star shop removed — replaced by reputation level milestones
  bool _showPrestigePreview = false, _prestigeNotified = false;

  // Managers: set of building IDs that have managers (auto-collect at full rate)
  Set<String> managers = {};

  // Daily rewards
  int dailyStreak = 0;
  String lastDailyClaimDate = '';
  bool _showDailyReward = false;

  // Onboarding
  int onboardingStep = 0; // 0=not started, 1=tap prompt, 2=buy building, 3=level up, 99=done
  bool panelExpanded = false;
  // Skills (time-based active buffs, reset on prestige)
  // Each skill: remaining duration in seconds (0 = inactive), times purchased (for cost scaling)
  double skillTapPowerTimer = 0, skillTapIncomeTimer = 0, skillComboDurationTimer = 0, skillSpeedBoostTimer = 0;
  int skillTapPowerBuys = 0, skillTapIncomeBuys = 0, skillComboDurationBuys = 0, skillSpeedBoostBuys = 0;
  static const double skillDuration = 60.0; // seconds each activation lasts
  bool get skillTapPowerActive => skillTapPowerTimer > 0;
  bool get skillTapIncomeActive => skillTapIncomeTimer > 0;
  bool get skillComboDurationActive => skillComboDurationTimer > 0;
  bool get skillSpeedBoostActive => skillSpeedBoostTimer > 0;
  double edgeGlowIntensity = 0; // 0-1, based on combo
  double moneyPopScale = 1.0; // briefly scales up on tap
  List<GroundRipple> groundRipples = [];

  late AnimationController _tapCtrl;
  late Animation<double> _tapAnim;
  late AnimationController _shakeCtrl;
  double _shakeDx = 0, _shakeDy = 0;
  Timer? _tickTimer;
  final _rng = Random();
  final _sound = SoundEngine();
  Size _screenSize = Size.zero;

  double get achievementIncomeMultiplier {
    double mult = 1.0;
    final achs = _achievements;
    for (int i = 0; i < achs.length; i++) {
      if (claimedAchievements.contains(i)) {
        mult += achs[i].$4.incomeMultPercent;
      }
    }
    return mult;
  }

  double get totalIncome {
    double t = 0;
    final gm = achievementIncomeMultiplier * reputationIncomeMultiplier;
    for (final b in ownedBuildings) {
      // With manager: 100% income. Without: 25% (still earns, but managers are a 4x boost)
      final managerMult = managers.contains(b.info.id) ? 1.0 : 0.20;
      t += b.incomeWith(gm) * managerMult;
    }
    return t;
  }

  // Level is purchased with coins — trade-off: tap power vs buildings
  // Cost mirrors building tiers: lv1-5 = lemonade/coffee, lv6-10 = restaurant/mall, etc.
  // Max level 50 — deep endgame after multiple prestiges
  double get levelUpCost => 50.0 * pow(2.5, playerLevel - 1);
  int get levelTapPowerGainInt => (1 + playerLevel * 1.5).floor();
  double get levelTapPowerGain => levelTapPowerGainInt.toDouble();

  double get baseTapPower {
    double tap = 1.0;
    for (int i = 1; i < playerLevel; i++) {
      tap += (1 + i * 1.5).floorToDouble();
    }
    return tap;
  }

  bool get canLevelUp => money >= levelUpCost && playerLevel < 50;

  void _levelUp() {
    if (!canLevelUp) return;
    setState(() {
      money -= levelUpCost;
      playerLevel++;
    });
    _sound.playUpgrade();
    if (onboardingStep == 3) onboardingStep = 99; // Onboarding complete
    if (_screenSize.width > 0) {
      burstTexts.add(BurstText(Offset(_screenSize.width / 2, _screenSize.height * 0.3), 'LEVEL ${playerLevel}!', _levelColor));
      flashOpacity = 0.2;
    }
  }

  double get comboMultiplier {
    // Ramps from 1x to 3x over 20 combo hits
    return 1.0 + (combo / 20.0 * 2.0).clamp(0.0, 2.0);
  }

  double get currentTapPower => (baseTapPower + achievementTapBonus + (skillTapPowerActive ? 4.0 : 0.0)) * comboMultiplier * (1.0 + (skillTapIncomeActive ? 0.5 : 0.0)) * reputationTapMultiplier;

  int get cityLevel {
    if (totalEarned >= 5000000) return 5;
    if (totalEarned >= 500000) return 4;
    if (totalEarned >= 50000) return 3;
    if (totalEarned >= 5000) return 2;
    return 1;
  }

  String get cityName => ['Village', 'Town', 'City', 'Metropolis', 'Megacity'][cityLevel - 1];
  List<BuildingInfo> get unlockedBuildings => allBuildings.where((b) => totalEarned >= b.unlockAt).toList();

  BuildingInfo? get nextLocked {
    for (final b in allBuildings) {
      if (totalEarned < b.unlockAt) return b;
    }
    return null;
  }

  // Prestige getters
  // Reputation Points earned on prestige
  int get pendingRP => (50 * sqrt(totalEarned / prestigeThreshold)).floor();

  // Reputation Level — exponential scaling, infinite
  // Level 1: 50 RP, Level 2: 100, Level 3: 200, Level 5: ~800, Level 10: ~25K
  int get reputationLevel {
    if (totalRP <= 0) return 0;
    return (log(totalRP / 25 + 1) / log(2)).floor();
  }

  int get rpForNextLevel => (25 * pow(2, reputationLevel + 1) - 25).toInt();
  double get rpProgress => reputationLevel == 0 ? (totalRP / 50).clamp(0.0, 1.0) : ((totalRP - (25 * pow(2, reputationLevel) - 25)) / (25 * pow(2, reputationLevel))).clamp(0.0, 1.0);

  // Each reputation level: +10% income, +5% tap power
  double get reputationIncomeMultiplier => 1.0 + reputationLevel * 0.10;
  double get reputationTapMultiplier => 1.0 + reputationLevel * 0.05;

  // Milestone rewards based on reputation level
  double get startingCash {
    if (reputationLevel >= 30) return 50000;
    if (reputationLevel >= 15) return 10000;
    if (reputationLevel >= 8) return 2000;
    if (reputationLevel >= 3) return 500;
    return 0;
  }
  double get offlineCapSeconds {
    if (reputationLevel >= 20) return 86400;
    if (reputationLevel >= 12) return 28800;
    if (reputationLevel >= 5) return 14400;
    return 7200;
  }
  double get goldenCoinBaseInterval {
    if (reputationLevel >= 50) return 15;
    if (reputationLevel >= 20) return 20;
    if (reputationLevel >= 8) return 25;
    return 30;
  }
  // Old star shop getters removed — reputation milestones above handle these
  // Prestige threshold
  double get prestigeThreshold => 5e6 * pow(2.5, totalPrestiges);
  bool get canPrestige => totalEarned >= prestigeThreshold;

  PrestigeRank get currentPrestigeRank {
    for (int i = prestigeRanks.length - 1; i >= 0; i--) {
      if (totalPrestiges >= prestigeRanks[i].minPrestiges) return prestigeRanks[i];
    }
    return prestigeRanks[0];
  }

  PrestigeRank? get nextPrestigeRank {
    final c = currentPrestigeRank;
    return c.tier >= 9 ? null : prestigeRanks[c.tier + 1];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sound.init();
    _loadGame(); // Load saved state

    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _tapAnim = Tween(begin: 1.0, end: 0.95).chain(CurveTween(curve: Curves.easeOut)).animate(_tapCtrl);
    _tapCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _tapCtrl.reverse();
    });

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _shakeCtrl.addListener(() {
      setState(() {
        final i = (2.0 + combo.clamp(0, 30) * 0.6) * (1 - _shakeCtrl.value);
        _shakeDx = (_rng.nextDouble() - 0.5) * i;
        _shakeDy = (_rng.nextDouble() - 0.5) * i;
      });
    });

    goldenCoinTimer = goldenCoinBaseInterval + _rng.nextDouble() * goldenCoinBaseInterval;
    _tickTimer = Timer.periodic(const Duration(milliseconds: 16), _tick);

    // Check daily reward + onboarding after load
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkDailyReward();
      if (onboardingStep == 0 && totalTaps == 0 && ownedBuildings.isEmpty) {
        setState(() => onboardingStep = 1);
      }
    });

    // Auto-save every 5 seconds
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveGame());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveGame();
    }
    if (state == AppLifecycleState.resumed) {
      _loadGame();
    }
  }

  // ─── SAVE/LOAD ──────────────────────────────────────────────

  Future<void> _saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('saveVersion', 3);
      prefs.setDouble('money', money);
      prefs.setDouble('totalEarned', totalEarned);
      prefs.setInt('totalTaps', totalTaps);
      prefs.setInt('highestCombo', highestCombo);
      prefs.setDouble('playTime', playTime);
      prefs.setInt('playerLevel', playerLevel);
      prefs.setDouble('achievementTapBonus', achievementTapBonus);
      prefs.setInt('lastSaveTime', DateTime.now().millisecondsSinceEpoch);

      final buildingData = ownedBuildings.map((b) => {
        'id': b.info.id,
        'count': b.count,
      }).toList();
      prefs.setString('buildings', jsonEncode(buildingData));
      prefs.setString('claimedAchievements', jsonEncode(claimedAchievements.toList()));
      prefs.setString('notifiedMilestones', jsonEncode(highestNotifiedMilestone));

      // Prestige data
      prefs.setInt('totalRP', totalRP);
      prefs.setInt('totalPrestiges', totalPrestiges);
      prefs.setDouble('allTimeEarned', allTimeEarned);
      prefs.setInt('allTimeTaps', allTimeTaps);
      prefs.setInt('allTimeHighestCombo', allTimeHighestCombo);
      // Star shop keys removed — reputation system
      prefs.setString('managers', jsonEncode(managers.toList()));
      prefs.setInt('dailyStreak', dailyStreak);
      prefs.setString('lastDailyClaimDate', lastDailyClaimDate);
      prefs.setInt('onboardingStep', onboardingStep);
      prefs.setDouble('skillTapPowerTimer', skillTapPowerTimer);
      prefs.setDouble('skillTapIncomeTimer', skillTapIncomeTimer);
      prefs.setDouble('skillComboDurationTimer', skillComboDurationTimer);
      prefs.setDouble('skillSpeedBoostTimer', skillSpeedBoostTimer);
      prefs.setInt('skillTapPowerBuys', skillTapPowerBuys);
      prefs.setInt('skillTapIncomeBuys', skillTapIncomeBuys);
      prefs.setInt('skillComboDurationBuys', skillComboDurationBuys);
      prefs.setInt('skillSpeedBoostBuys', skillSpeedBoostBuys);
    } catch (_) {}
  }

  Future<void> _loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMoney = prefs.getDouble('money');
      if (savedMoney == null) return;

      setState(() {
        money = savedMoney;
        totalEarned = prefs.getDouble('totalEarned') ?? 0;
        totalTaps = prefs.getInt('totalTaps') ?? 0;
        highestCombo = prefs.getInt('highestCombo') ?? 0;
        playTime = prefs.getDouble('playTime') ?? 0;
        playerLevel = prefs.getInt('playerLevel') ?? 1;
        achievementTapBonus = prefs.getDouble('achievementTapBonus') ?? 0;
        displayedMoney = money;

        final version = prefs.getInt('saveVersion') ?? 1;
        final buildingJson = prefs.getString('buildings');
        if (buildingJson != null) {
          final List<dynamic> data = jsonDecode(buildingJson);
          ownedBuildings = data.map((b) {
            final info = allBuildings.firstWhere((i) => i.id == b['id']);
            final cnt = version == 1 ? (b['level'] ?? 1) : (b['count'] ?? 1);
            return OwnedBuilding(info, count: cnt, constructionProgress: 1.0, craneProgress: 1.0);
          }).toList();
        }

        final achJson = prefs.getString('claimedAchievements');
        if (achJson != null) claimedAchievements = Set<int>.from(jsonDecode(achJson));

        final msJson = prefs.getString('notifiedMilestones');
        if (msJson != null) highestNotifiedMilestone = Map<String, int>.from(jsonDecode(msJson));

        // Prestige data
        totalRP = prefs.getInt('totalRP') ?? (prefs.getInt('cityStars') ?? 0) + (prefs.getInt('totalStarsEarned') ?? 0); // migrate from stars
        totalPrestiges = prefs.getInt('totalPrestiges') ?? 0;
        allTimeEarned = prefs.getDouble('allTimeEarned') ?? 0;
        allTimeTaps = prefs.getInt('allTimeTaps') ?? 0;
        allTimeHighestCombo = prefs.getInt('allTimeHighestCombo') ?? 0;
        // Star shop keys removed — reputation handles all bonuses
        final mgrJson = prefs.getString('managers');
        if (mgrJson != null) managers = Set<String>.from(jsonDecode(mgrJson));
        dailyStreak = prefs.getInt('dailyStreak') ?? 0;
        lastDailyClaimDate = prefs.getString('lastDailyClaimDate') ?? '';
        onboardingStep = prefs.getInt('onboardingStep') ?? 0;
        skillTapPowerTimer = prefs.getDouble('skillTapPowerTimer') ?? 0;
        skillTapIncomeTimer = prefs.getDouble('skillTapIncomeTimer') ?? 0;
        skillComboDurationTimer = prefs.getDouble('skillComboDurationTimer') ?? 0;
        skillSpeedBoostTimer = prefs.getDouble('skillSpeedBoostTimer') ?? 0;
        skillTapPowerBuys = prefs.getInt('skillTapPowerBuys') ?? 0;
        skillTapIncomeBuys = prefs.getInt('skillTapIncomeBuys') ?? 0;
        skillComboDurationBuys = prefs.getInt('skillComboDurationBuys') ?? 0;
        skillSpeedBoostBuys = prefs.getInt('skillSpeedBoostBuys') ?? 0;
        if (version < 3) { allTimeEarned = totalEarned; allTimeTaps = totalTaps; allTimeHighestCombo = highestCombo; }

        // Offline earnings
        final lastSave = prefs.getInt('lastSaveTime');
        if (lastSave != null && totalIncome > 0) {
          final elapsed = (DateTime.now().millisecondsSinceEpoch - lastSave) / 1000;
          if (elapsed > 10) {
            final cappedTime = elapsed.clamp(0, offlineCapSeconds);
            // Diminishing returns: first hour ~100%, decays over time
            // 2h: ~85%, 4h: ~70%, 8h: ~55% — incentivizes checking in often
            final hours = cappedTime / 3600;
            final offlineMult = 1.0 - 0.3 * (1 - 1.0 / (1 + hours * 0.5));
            _offlineEarnings = totalIncome * cappedTime * offlineMult;
            money += _offlineEarnings;
            totalEarned += _offlineEarnings;
            _showWelcomeBack = true;
          }
        }
      });
    } catch (_) {}
  }

  void _tick(Timer _) {
    setState(() {
      const dt = 0.016;

      // Timer-based building production (Adventure Capitalist style)
      final gm = achievementIncomeMultiplier * reputationIncomeMultiplier;
      for (final b in ownedBuildings) {
        if (b.readyToCollect) continue; // timer paused until collected
        b.productionTimer += dt * (skillSpeedBoostActive ? 1.43 : 1.0); // 30% faster when active
        if (b.productionTimer >= b.info.prodTime) {
          final earned = b.incomePerCycle(gm);
          if (managers.contains(b.info.id)) {
            // Manager auto-collects
            money += earned;
            totalEarned += earned;
            b.productionTimer = 0;
          } else {
            // Waiting for player to tap
            b.readyToCollect = true;
            b.pendingMoney = earned;
            b.productionTimer = b.info.prodTime; // stays at max
          }
        }
      }

      // Tick down active skill timers
      if (skillTapPowerTimer > 0) skillTapPowerTimer = (skillTapPowerTimer - dt).clamp(0, skillDuration);
      if (skillTapIncomeTimer > 0) skillTapIncomeTimer = (skillTapIncomeTimer - dt).clamp(0, skillDuration);
      if (skillComboDurationTimer > 0) skillComboDurationTimer = (skillComboDurationTimer - dt).clamp(0, skillDuration);
      if (skillSpeedBoostTimer > 0) skillSpeedBoostTimer = (skillSpeedBoostTimer - dt).clamp(0, skillDuration);

      displayedMoney += (money - displayedMoney) * 0.15;
      playTime += dt;

      if (combo > 0) {
        comboTimer -= dt;
        if (comboTimer <= 0) combo = 0;
      }

      if (flashOpacity > 0) flashOpacity = (flashOpacity - dt * 3).clamp(0, 1);

      for (final c in floatingCoins) {
        c.pos = Offset(c.pos.dx + c.dx * dt, c.pos.dy - 120 * dt);
        c.opacity = (c.opacity - dt * 1.8).clamp(0, 1);
        c.scale = (c.scale + dt * 3).clamp(0, 1.2);
      }
      floatingCoins.removeWhere((c) => c.opacity <= 0);

      for (final p in particles) {
        p.pos = Offset(p.pos.dx + p.vel.dx * dt, p.pos.dy + p.vel.dy * dt);
        p.vel = Offset(p.vel.dx * 0.97, p.vel.dy + 500 * dt);
        p.life -= dt * 2.0;
        p.size *= 0.985;
      }
      particles.removeWhere((p) => p.life <= 0);

      for (final r in rings) {
        r.radius += 200 * dt;
        r.opacity = (r.opacity - dt * 2.5).clamp(0, 1);
      }
      rings.removeWhere((r) => r.opacity <= 0);

      // Combo rings
      for (final cr in comboRings) {
        cr.life -= dt * 2.5;
      }
      comboRings.removeWhere((cr) => cr.life <= 0);

      // Tap glows
      for (final g in tapGlows) {
        g.life -= dt * 3.0;
      }
      tapGlows.removeWhere((g) => g.life <= 0);

      // Burst texts
      for (final bt in burstTexts) {
        bt.life -= dt * 2.0;
        bt.scale = (bt.scale + dt * 6).clamp(0, 2.0);
        bt.pos = Offset(bt.pos.dx, bt.pos.dy - 80 * dt);
      }
      burstTexts.removeWhere((bt) => bt.life <= 0);

      // Construction + crane animation
      for (final b in ownedBuildings) {
        if (b.craneProgress < 1.0) {
          b.craneProgress = (b.craneProgress + dt * 1.2).clamp(0, 1);
          // Building starts rising after crane is halfway
          if (b.craneProgress > 0.4) {
            b.constructionProgress = ((b.craneProgress - 0.4) / 0.6).clamp(0, 1);
            // Bounce at the end
            if (b.constructionProgress >= 0.95) {
              b.constructionProgress = 1.0;
            }
          }
        }
      }

      // Check achievements
      final achs = _achievements;
      for (int i = 0; i < achs.length; i++) {
        if (!claimedAchievements.contains(i) && achs[i].$3) {
          claimedAchievements.add(i);
          final reward = achs[i].$4;
          if (reward.coins > 0) { money += reward.coins; totalEarned += reward.coins; }
          if (reward.tapPower > 0) { achievementTapBonus += reward.tapPower; }
          if (_screenSize.width > 0) {
            burstTexts.add(BurstText(Offset(_screenSize.width / 2, _screenSize.height * 0.3), '${achs[i].$2}!', const Color(0xFFFFD600)));
            flashOpacity = 0.3;
          }
        }
      }

      // Check milestone notifications
      for (final b in ownedBuildings) {
        for (final ms in milestoneThresholds) {
          if (b.count >= ms.count) {
            final prev = highestNotifiedMilestone[b.info.id] ?? 0;
            if (ms.count > prev) {
              highestNotifiedMilestone[b.info.id] = ms.count;
              if (_screenSize.width > 0) {
                burstTexts.add(BurstText(Offset(_screenSize.width / 2, _screenSize.height * 0.35), 'x${ms.multiplier} ${b.info.name.toUpperCase()}!', const Color(0xFF00E5FF)));
                flashOpacity = 0.35;
              }
            }
          }
        }
      }

      // Edge glow — ramps with combo, decays when combo drops
      final targetGlow = (combo / 15.0).clamp(0.0, 1.0);
      edgeGlowIntensity += (targetGlow - edgeGlowIntensity) * 0.1;
      if (combo == 0) edgeGlowIntensity = (edgeGlowIntensity - dt * 2).clamp(0, 1);

      // Money pop decay
      moneyPopScale += (1.0 - moneyPopScale) * 0.15;

      // Ground ripples
      for (final gr in groundRipples) { gr.life -= dt * 3.0; }
      groundRipples.removeWhere((gr) => gr.life <= 0);

      // Prestige availability notification
      if (!_prestigeNotified && canPrestige) {
        _prestigeNotified = true;
        if (_screenSize.width > 0) {
          burstTexts.add(BurstText(Offset(_screenSize.width / 2, _screenSize.height * 0.25), 'NEW ERA AVAILABLE!', const Color(0xFFFFB300)));
          flashOpacity = 0.3;
        }
      }

      // Golden coin logic
      if (goldenCoin == null) {
        goldenCoinTimer -= dt;
        if (goldenCoinTimer <= 0 && _screenSize.width > 0) {
          // Spawn golden coin
          final gx = 40 + _rng.nextDouble() * (_screenSize.width - 80);
          final gy = _screenSize.height * 0.2 + _rng.nextDouble() * _screenSize.height * 0.3;
          goldenCoin = GoldenCoin(Offset(gx, gy), 6.0);
        }
      } else {
        final gc = goldenCoin!;
        gc.life -= dt;
        gc.bobPhase += dt * 3;
        gc.glowPhase += dt * 5;
        if (gc.life <= 0 || gc.collected) {
          goldenCoin = null;
          goldenCoinTimer = goldenCoinBaseInterval + _rng.nextDouble() * goldenCoinBaseInterval;
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveGame();
    _tapCtrl.dispose();
    _shakeCtrl.dispose();
    _tickTimer?.cancel();
    _saveTimer?.cancel();
    _sound.dispose();
    super.dispose();
  }

  Color get _comboColor {
    if (combo >= 20) return const Color(0xFFFFD600);
    if (combo >= 10) return const Color(0xFFFF6D00);
    if (combo >= 5) return const Color(0xFFFFEB3B);
    return Colors.white;
  }

  void _onTap(TapDownDetails details) {
    final pos = details.localPosition;

    // Check building collection tap (tap on a ready building to collect)
    final gY = _screenSize.height * 0.62;
    final frontY = gY + 38;
    for (final b in ownedBuildings) {
      if (!b.readyToCollect) continue;
      final rowBuildings = allBuildings.where((i) => i.row == b.info.row).toList();
      final slotIndex = rowBuildings.indexWhere((i) => i.id == b.info.id);
      if (slotIndex < 0) continue;
      final slotW = _screenSize.width / 6;
      final cx = slotW * slotIndex + slotW / 2;
      final baseY = b.info.row == 0 ? gY : frontY;
      final bh = _screenSize.height * b.heightFraction;
      // Check if tap is near this building
      if ((pos.dx - cx).abs() < slotW * 0.5 && pos.dy > baseY - bh - 20 && pos.dy < baseY + 15) {
        _collectBuilding(b);
        return;
      }
    }

    // Check golden coin tap
    if (goldenCoin != null && !goldenCoin!.collected) {
      final gc = goldenCoin!;
      final dist = (pos - gc.pos).distance;
      if (dist < 35) {
        _collectGoldenCoin(gc, pos);
        return;
      }
    }

    final earned = currentTapPower;
    money += earned;
    totalEarned += earned;
    combo++;
    comboTimer = 1.5 + (skillComboDurationActive ? 1.5 : 0.0);
    totalTaps++;
    // Onboarding: after enough taps to afford first building
    if (onboardingStep == 1 && money >= 50) onboardingStep = 2;
    if (combo > highestCombo) highestCombo = combo;

    // Floating money text — SIZE SCALES WITH EARNED AMOUNT
    floatingCoins.add(FloatingCoin(pos + const Offset(0, -30), '+\$${_fmt(earned)}', _comboColor));

    // Trail copies at high combo
    if (combo >= 10) {
      floatingCoins.add(FloatingCoin(pos + Offset(-15 + _rng.nextDouble() * 30, -20), '+\$${_fmt(earned)}', _comboColor.withAlpha(100)));
    }
    if (combo >= 25) {
      floatingCoins.add(FloatingCoin(pos + Offset(-20 + _rng.nextDouble() * 40, -15), '+\$${_fmt(earned)}', _comboColor.withAlpha(70)));
    }

    // Green banknote particles
    final noteCount = 2 + combo.clamp(0, 6);
    for (int i = 0; i < noteCount; i++) {
      final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * pi * 0.8;
      final speed = 100 + _rng.nextDouble() * 130;
      particles.add(TapParticle(pos, Offset(cos(angle) * speed, sin(angle) * speed), const Color(0xFF4CAF50), 3.5 + _rng.nextDouble() * 2));
    }

    // Regular particles — more + bigger at higher combo
    final pCount = 4 + combo.clamp(0, 15);
    final pSize = 1.5 + (combo / 10.0).clamp(0, 2);
    for (int i = 0; i < pCount; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 180 + combo * 3;
      particles.add(TapParticle(pos, Offset(cos(angle) * speed, sin(angle) * speed - 80), _comboColor.withAlpha(180), pSize + _rng.nextDouble() * 1.5));
    }

    // Shockwave ring
    rings.add(TapRing(pos, _comboColor));

    // Combo ring with number (shows at 3+ combo)
    if (combo >= 3) comboRings.add(ComboRing(pos, combo, _comboColor));

    // Afterglow at high combo
    if (combo >= 8) tapGlows.add(TapGlow(pos, _comboColor));

    // Money counter pop
    moneyPopScale = 1.15 + (combo / 30.0).clamp(0, 0.15);

    // Ground ripple
    groundRipples.add(GroundRipple(pos.dx));

    // Milestone burst text at tap point
    if (combo == 5) {
      burstTexts.add(BurstText(pos + const Offset(0, -50), 'NICE!', const Color(0xFFFFEB3B)));
    } else if (combo == 10) {
      burstTexts.add(BurstText(pos + const Offset(0, -50), 'FIRE!', const Color(0xFFFF6D00)));
      flashOpacity = 0.25;
    } else if (combo == 20) {
      burstTexts.add(BurstText(pos + const Offset(0, -50), 'SUPER!', const Color(0xFFFFD600)));
      flashOpacity = 0.35;
    } else if (combo == 50) {
      burstTexts.add(BurstText(pos + const Offset(0, -50), 'INSANE!', const Color(0xFFFFB300)));
      flashOpacity = 0.4;
    } else if (combo == 100) {
      burstTexts.add(BurstText(pos + const Offset(0, -50), 'GODLIKE!', const Color(0xFF00E5FF)));
      flashOpacity = 0.5;
    }

    _tapCtrl.forward(from: 0);
    _shakeCtrl.forward(from: 0);
    HapticFeedback.lightImpact();
    _sound.playTap(combo);
  }

  void _collectGoldenCoin(GoldenCoin gc, Offset pos) {
    gc.collected = true;
    final earned = currentTapPower * 10;
    money += earned;
    totalEarned += earned;

    // Big celebration
    floatingCoins.add(FloatingCoin(pos + const Offset(0, -40), '🌟 +\$${_fmt(earned)}!', const Color(0xFFFFD600)));
    floatingCoins.add(FloatingCoin(pos + const Offset(20, -30), 'GOLDEN!', const Color(0xFFFFD600)));
    flashOpacity = 0.4;

    // Extra particles
    for (int i = 0; i < 25; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 150 + _rng.nextDouble() * 250;
      particles.add(TapParticle(pos, Offset(cos(angle) * speed, sin(angle) * speed - 100), const Color(0xFFFFD600), 3.0 + _rng.nextDouble() * 4));
    }
    for (int i = 0; i < 3; i++) {
      rings.add(TapRing(pos, const Color(0xFFFFD600)));
    }

    _shakeCtrl.forward(from: 0);
    HapticFeedback.heavyImpact();
    _sound.playGolden();
  }

  // Calculate cost to buy N more of a building
  double _bulkCost(BuildingInfo info, int currentCount, int amount) {
    double total = 0;
    for (int i = 0; i < amount; i++) {
      total += info.baseCost * pow(1.15, currentCount + i);
    }
    return total;
  }

  // How many can we afford?
  int _maxAffordable(BuildingInfo info, int currentCount) {
    double budget = money;
    int n = 0;
    while (n < 100) { // cap at 100
      final cost = info.baseCost * pow(1.15, currentCount + n);
      if (budget < cost) break;
      budget -= cost;
      n++;
    }
    return n;
  }

  void _buyBuilding(BuildingInfo info, {int amount = 1}) {
    final existing = ownedBuildings.where((b) => b.info.id == info.id).toList();
    final currentCount = existing.isEmpty ? 0 : existing.first.count;
    final cost = _bulkCost(info, currentCount, amount);
    if (money < cost) return;
    money -= cost;
    if (existing.isEmpty) {
      ownedBuildings.add(OwnedBuilding(info, count: amount, constructionProgress: 0.0, craneProgress: 0.0));
    } else {
      existing.first.count += amount;
    }
    _sound.playBuy();
    if (onboardingStep == 2) onboardingStep = 3;
    setState(() {});
  }

  void _collectBuilding(OwnedBuilding b) {
    if (!b.readyToCollect) return;
    setState(() {
      money += b.pendingMoney;
      totalEarned += b.pendingMoney;
      b.readyToCollect = false;
      b.pendingMoney = 0;
      b.productionTimer = 0;
    });
    _sound.playBuy(); // ka-ching
    if (_screenSize.width > 0) {
      burstTexts.add(BurstText(Offset(_screenSize.width / 2, _screenSize.height * 0.4), '+\$${_fmt(b.pendingMoney > 0 ? b.pendingMoney : b.incomePerCycle(achievementIncomeMultiplier * reputationIncomeMultiplier))}', const Color(0xFF4CAF50)));
    }
  }

  // Collect ALL ready buildings
  void _collectAll() {
    double total = 0;
    for (final b in ownedBuildings) {
      if (b.readyToCollect) {
        total += b.pendingMoney;
        b.readyToCollect = false;
        b.pendingMoney = 0;
        b.productionTimer = 0;
      }
    }
    if (total > 0) {
      money += total;
      totalEarned += total;
      _sound.playBuy();
      setState(() {});
    }
  }

  double managerCost(BuildingInfo info) => info.baseCost * 50;

  void _buyManager(BuildingInfo info) {
    final cost = managerCost(info);
    if (money < cost || managers.contains(info.id)) return;
    setState(() {
      money -= cost;
      managers.add(info.id);
    });
    _sound.playUpgrade();
    if (_screenSize.width > 0) {
      burstTexts.add(BurstText(Offset(_screenSize.width / 2, _screenSize.height * 0.3), 'MANAGER HIRED!', const Color(0xFF4CAF50)));
    }
  }

  // Daily rewards
  static const dailyRewards = [
    (coins: 500.0, stars: 0),    // Day 1
    (coins: 2000.0, stars: 0),   // Day 2
    (coins: 0.0, stars: 1),      // Day 3
    (coins: 10000.0, stars: 0),  // Day 4
    (coins: 0.0, stars: 3),      // Day 5
    (coins: 50000.0, stars: 0),  // Day 6
    (coins: 0.0, stars: 10),     // Day 7
  ];

  void _claimDailyReward() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastDailyClaimDate == today) return;

    setState(() {
      // Check streak
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      if (lastDailyClaimDate == yesterday) {
        dailyStreak = (dailyStreak + 1) % 7;
      } else if (lastDailyClaimDate != today) {
        dailyStreak = 0; // Reset streak
      }

      final reward = dailyRewards[dailyStreak];
      if (reward.coins > 0) { money += reward.coins; totalEarned += reward.coins; }
      if (reward.coins > 0) {} // stars removed — RP only from prestige

      lastDailyClaimDate = today;
      _showDailyReward = false;
    });
    _sound.playGolden();
    if (_screenSize.width > 0) {
      final reward = dailyRewards[dailyStreak > 0 ? dailyStreak - 1 : 6];
      final text = reward.coins > 0 ? '+\$${_fmt(reward.coins)}' : '+${reward.stars} STARS';
      burstTexts.add(BurstText(Offset(_screenSize.width / 2, _screenSize.height * 0.3), text, const Color(0xFFFFD600)));
      flashOpacity = 0.3;
    }
    _saveGame();
  }

  void _checkDailyReward() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastDailyClaimDate != today && !_showDailyReward) {
      setState(() => _showDailyReward = true);
    }
  }

  void _executePrestige() {
    final rpEarned = pendingRP;
    setState(() {
      totalRP += rpEarned;
      totalPrestiges++;
      allTimeEarned += totalEarned;
      allTimeTaps += totalTaps;
      if (highestCombo > allTimeHighestCombo) allTimeHighestCombo = highestCombo;

      // Reset per-run state
      money = startingCash;
      playerLevel = 1;
      managers = {};
      skillTapPowerTimer = 0; skillTapIncomeTimer = 0; skillComboDurationTimer = 0; skillSpeedBoostTimer = 0;
      skillTapPowerBuys = 0; skillTapIncomeBuys = 0; skillComboDurationBuys = 0; skillSpeedBoostBuys = 0;
      totalEarned = 0;
      ownedBuildings = [];
      combo = 0; comboTimer = 0; totalTaps = 0; highestCombo = 0;
      claimedAchievements = {};
      achievementTapBonus = 0;
      highestNotifiedMilestone = {};
      displayedMoney = money;
      _prestigeNotified = false;

      // Clear effects
      floatingCoins.clear(); particles.clear(); rings.clear();
      comboRings.clear(); tapGlows.clear(); burstTexts.clear();
      goldenCoin = null;
      goldenCoinTimer = goldenCoinBaseInterval + _rng.nextDouble() * goldenCoinBaseInterval;
      _showPrestigePreview = false;

      // Celebration
      flashOpacity = 0.6;
      if (_screenSize.width > 0) {
        burstTexts.add(BurstText(Offset(_screenSize.width / 2, _screenSize.height * 0.25), 'NEW ERA!', const Color(0xFFFFB300)));
        burstTexts.add(BurstText(Offset(_screenSize.width / 2, _screenSize.height * 0.32), '+$rpEarned RP', const Color(0xFFFFD600)));
      }
    });
    HapticFeedback.heavyImpact();
    _sound.playPrestige();
    _saveGame();
  }

  // Star shop removed — reputation level milestones replace it

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Transform.translate(
        offset: Offset(_shakeDx, _shakeDy),
        child: AnimatedBuilder(
          animation: _tapAnim,
          builder: (_, child) => Transform.scale(scale: _tapAnim.value, child: child),
          child: Stack(
            children: [
              GestureDetector(
                onTapDown: _onTap,
                child: CustomPaint(
                  painter: CityPainter(cityLevel: cityLevel, buildings: ownedBuildings, particles: particles, rings: rings, comboRings: comboRings, tapGlows: tapGlows, groundRipples: groundRipples, goldenCoin: goldenCoin, totalEarned: totalEarned),
                  size: Size.infinite,
                ),
              ),

              for (final c in floatingCoins)
                Positioned(
                  left: c.pos.dx - 60, top: c.pos.dy,
                  child: IgnorePointer(child: Opacity(
                    opacity: c.opacity,
                    child: Transform.scale(scale: c.scale, child: Text(c.text, style: TextStyle(
                      color: c.color, fontSize: 24, fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: const Offset(1, 2)), Shadow(color: c.color.withAlpha(100), blurRadius: 16)],
                    ))),
                  )),
                ),

              // Burst milestone texts at tap point
              for (final bt in burstTexts)
                Positioned(
                  left: bt.pos.dx - 60, top: bt.pos.dy - 15,
                  child: IgnorePointer(child: Opacity(
                    opacity: bt.life.clamp(0, 1),
                    child: Transform.scale(scale: bt.scale, child: Text(bt.text, style: TextStyle(
                      color: bt.color, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 6, offset: const Offset(2, 2)),
                        Shadow(color: bt.color.withAlpha(150), blurRadius: 20),
                      ],
                    ))),
                  )),
                ),

              if (flashOpacity > 0) IgnorePointer(child: Container(color: Colors.white.withAlpha((flashOpacity * 255).toInt()))),

              // Edge glow vignette during combo
              if (edgeGlowIntensity > 0.05)
                IgnorePointer(child: CustomPaint(
                  size: Size.infinite,
                  painter: _EdgeGlowPainter(edgeGlowIntensity, _comboColor),
                )),

              _buildHud(context),

              Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomUI(context)),

              // Welcome back overlay
              if (_showWelcomeBack) _buildWelcomeBack(),
              if (_showPrestigePreview) _buildPrestigePreview(),
              if (_showDailyReward) _buildDailyRewardOverlay(),
              if (onboardingStep >= 1 && onboardingStep <= 3) _buildOnboarding(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBack() {
    return GestureDetector(
      onTap: () => setState(() => _showWelcomeBack = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1A237E), Color(0xFF0D1B3E)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD600), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFFFFD600).withAlpha(40), blurRadius: 30, spreadRadius: 5)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.wb_sunny, size: 48, color: Color(0xFFFFD600)),
              const SizedBox(height: 12),
              const Text('WELCOME BACK!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 16),
              const Text('Your city earned while you were away:', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD600).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD600).withAlpha(80)),
                ),
                child: Text('+\$${_fmt(_offlineEarnings)}', style: const TextStyle(color: Color(0xFFFFD600), fontSize: 32, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF388E3C)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('COLLECT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── HUD ────────────────────────────────────────────────────

  // Level badge colors: bronze → silver → gold → emerald → diamond → legendary
  // Level color tiers — no names, just visual progression
  Color get _levelColor {
    final l = playerLevel;
    if (l >= 40) return const Color(0xFFFFB300); // mythic purple
    if (l >= 30) return const Color(0xFFFF1744); // red
    if (l >= 22) return const Color(0xFFFFD600); // gold
    if (l >= 15) return const Color(0xFFAB47BC); // purple
    if (l >= 10) return const Color(0xFF42A5F5); // blue
    if (l >= 5) return const Color(0xFF66BB6A);  // green
    return const Color(0xFF9E9E9E);               // grey
  }

  double get _levelProgress {
    if (playerLevel >= 50) return 1.0;
    return (money / levelUpCost).clamp(0.0, 1.0);
  }

  Widget _buildHud(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xDD000000), Color(0x00000000)])),
        child: SafeArea(bottom: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
          child: Column(children: [
            // Level badge - centered, prominent
            _buildLevelBadge(),
            const SizedBox(height: 8),
            // Money row
            // Clean money display — no icons, just numbers
            Transform.scale(
              scale: moneyPopScale,
              child: Row(children: [
                Flexible(child: Text('\$${_fmt(displayedMoney)}', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 18, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                Text('\$${_fmt(totalIncome)}/s', style: const TextStyle(color: Colors.white30, fontSize: 9)),
                const Spacer(),
                if (totalPrestiges > 0)
                  Padding(padding: const EdgeInsets.only(right: 4), child: Text('R$reputationLevel', style: const TextStyle(color: Color(0xFFFFB300), fontSize: 9, fontWeight: FontWeight.w800))),
                Text(cityName, style: const TextStyle(color: Colors.white30, fontSize: 9)),
              ]),
            ),
            if (nextLocked != null) Padding(padding: const EdgeInsets.only(top: 6), child: _buildUnlockProgress()),
          ]),
        )),
      ),
    );
  }

  Widget _buildLevelBadge() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      // Circular level badge with ring progress
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1.0),
        duration: const Duration(milliseconds: 300),
        key: ValueKey(playerLevel),
        builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
        child: SizedBox(
          width: 44, height: 44,
          child: Stack(alignment: Alignment.center, children: [
            // Progress ring
            SizedBox(
              width: 44, height: 44,
              child: CircularProgressIndicator(
                value: _levelProgress,
                strokeWidth: 3,
                backgroundColor: Colors.white.withAlpha(20),
                valueColor: AlwaysStoppedAnimation(_levelColor),
              ),
            ),
            // Inner circle with level number
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A3A),
                border: Border.all(color: _levelColor.withAlpha(150), width: 1.5),
                boxShadow: [BoxShadow(color: _levelColor.withAlpha(playerLevel >= 20 ? 80 : 30), blurRadius: playerLevel >= 20 ? 12 : 6)],
              ),
              child: Center(
                child: Text('$playerLevel', style: TextStyle(
                  color: _levelColor, fontSize: playerLevel >= 10 ? 12 : 14,
                  fontWeight: FontWeight.w900,
                )),
              ),
            ),
          ]),
        ),
      ),
      // Prestige rank badge
      if (totalPrestiges > 0)
        Padding(padding: const EdgeInsets.only(left: 6), child: _buildPrestigeRankBadge()),
    ]);
  }

  Widget _buildPrestigeRankBadge() {
    final rank = currentPrestigeRank;
    final glow = rank.tier >= 7;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 300),
      key: ValueKey(rank.tier),
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [rank.color.withAlpha(200), rank.color.withAlpha(120), rank.color.withAlpha(200)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: rank.color.withAlpha(180), width: 1.5),
          boxShadow: [BoxShadow(color: rank.color.withAlpha(glow ? 120 : 60), blurRadius: glow ? 18 : 10, spreadRadius: glow ? 2 : 1)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(rank.icon, size: 12, color: Colors.black87),
          const SizedBox(width: 3),
          Text(rank.name.toUpperCase(), style: const TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ]),
      ),
    );
  }

  Widget _buildUnlockProgress() {
    final next = nextLocked!;
    final progress = (totalEarned / next.unlockAt).clamp(0.0, 1.0);
    return Row(children: [
      Icon(next.icon, size: 14, color: Colors.white38),
      const SizedBox(width: 4),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)), minHeight: 5))),
      const SizedBox(width: 6),
      Text('\$${_fmt(next.unlockAt.toDouble())}', style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
    ]);
  }

  // ─── BOTTOM UI ──────────────────────────────────────────────

  Widget _buildBottomUI(BuildContext context) {
    // Max panel height = 24% of screen (stays below buildings)
    final maxPanelHeight = _screenSize.height * 0.24;

    return GestureDetector(
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity != null) {
          if (d.primaryVelocity! < -100) setState(() => panelExpanded = true);
          if (d.primaryVelocity! > 100) setState(() => panelExpanded = false);
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFA0F0F25), Color(0xF00F0F25), Color(0x000F0F25)], stops: [0.0, 0.9, 1.0]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle bar — tap to toggle
          GestureDetector(
            onTap: () => setState(() => panelExpanded = !panelExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(children: [
                Container(width: 24, height: 2, color: Colors.white.withAlpha(30)),
                const Spacer(),
                Text(panelExpanded ? '▼' : '▲', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                const Spacer(),
                Container(width: 24, height: 2, color: Colors.white.withAlpha(30)),
              ]),
            ),
          ),
          // Expanded: tabs + scrollable content
          if (panelExpanded) ...[
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
              _tabButton(0, Icons.person, 'PLAYER'),
              _tabButton(1, Icons.location_city, 'BUILD'),
              _tabButton(2, Icons.bolt, 'SKILLS'),
              _tabButton(3, Icons.shopping_cart, 'MARKET'),
            ])),
            const SizedBox(height: 6),
            // Scrollable tab content with max height
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxPanelHeight),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (selectedTab == 0) _buildPlayerTab(),
                  if (selectedTab == 1) _buildBuildingsTab(),
                  if (selectedTab == 2) _buildSkillsTab(),
                  if (selectedTab == 3) _buildMarketTab(),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ],
        ])),
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final active = selectedTab == index;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A2744) : Colors.transparent,
          border: Border(bottom: BorderSide(color: active ? const Color(0xFF4CAF50) : Colors.transparent, width: 2)),
        ),
        child: Center(child: Text(label, style: TextStyle(
          color: active ? Colors.white : Colors.white30,
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5,
        ))),
      ),
    ));
  }

  Widget _buildCityTab() {
    if (ownedBuildings.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Tap to earn coins, then visit SHOP to build!', style: TextStyle(color: Colors.white38, fontSize: 13)));
    return SizedBox(height: 80, child: ListView.separated(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: ownedBuildings.length, separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final b = ownedBuildings[i];
        final hasManager = managers.contains(b.info.id);
        final mgrCost = managerCost(b.info);
        final canHire = money >= mgrCost && !hasManager;
        return Container(width: 120, padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: b.color.withAlpha(30), borderRadius: BorderRadius.circular(12), border: Border.all(color: b.color.withAlpha(80))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(children: [
              Icon(b.info.icon, size: 16, color: b.color),
              const SizedBox(width: 4),
              Text('x${b.count}', style: TextStyle(color: b.color, fontSize: 12, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (hasManager) const Icon(Icons.person, size: 12, color: Color(0xFF4CAF50))
              else Text('20%', style: TextStyle(color: Colors.redAccent.withAlpha(150), fontSize: 9, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 2),
            Text('\$${_fmt(b.incomeWith(achievementIncomeMultiplier * reputationIncomeMultiplier) * (hasManager ? 1.0 : 0.20))}/s', style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            if (!hasManager)
              GestureDetector(
                onTap: canHire ? () => _buyManager(b.info) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: canHire ? const Color(0xFF4CAF50) : Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('HIRE \$${_fmt(mgrCost)}', style: TextStyle(color: canHire ? Colors.white : Colors.white24, fontSize: 8, fontWeight: FontWeight.w700)),
                ),
              )
            else
              const Text('AUTO', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 9, fontWeight: FontWeight.w700)),
          ]),
        );
      },
    ));
  }

  Widget _buildShopTab() {
    final unlocked = unlockedBuildings;
    return SizedBox(height: 100, child: ListView.separated(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: unlocked.length, separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final info = unlocked[i];
        final existing = ownedBuildings.where((b) => b.info.id == info.id).toList();
        final count = existing.isEmpty ? 0 : existing.first.count;
        final cost = existing.isEmpty ? info.baseCost : existing.first.nextCost;
        final canBuy = money >= cost;
        return GestureDetector(
          onTap: canBuy ? () => _buyBuilding(info) : null,
          child: Container(width: 95, padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: canBuy ? LinearGradient(colors: [const Color(0xFF2A2A4A), info.colors[0].withAlpha(40)]) : null,
              color: canBuy ? null : const Color(0xFF151530),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: canBuy ? const Color(0xFFFFD600) : Colors.white10),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(info.icon, size: 20, color: info.colors[0]),
                if (count > 0) ...[const SizedBox(width: 3), Text('x$count', style: TextStyle(color: info.colors[0], fontSize: 11, fontWeight: FontWeight.w900))],
              ]),
              const SizedBox(height: 2),
              Text(info.name, style: TextStyle(color: canBuy ? Colors.white : Colors.white30, fontSize: 9, fontWeight: FontWeight.w700), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('\$${_fmt(cost)}', style: TextStyle(color: canBuy ? const Color(0xFFFFD600) : Colors.white24, fontSize: 12, fontWeight: FontWeight.w900)),
              Text('+\$${_fmt(info.baseIncome)}/s', style: TextStyle(color: canBuy ? Colors.greenAccent.withAlpha(180) : Colors.white10, fontSize: 9, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      },
    ));
  }

  Widget _buildMilestonesTab() {
    if (ownedBuildings.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Buy buildings to unlock milestones!', style: TextStyle(color: Colors.white38, fontSize: 13)));
    return SizedBox(height: 90, child: ListView.separated(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: ownedBuildings.length, separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final b = ownedBuildings[i];
        int? nextMs;
        for (final ms in milestoneThresholds) {
          if (b.count < ms.count) { nextMs = ms.count; break; }
        }
        final allReached = nextMs == null;
        final progress = allReached ? 1.0 : (b.count / nextMs!).clamp(0.0, 1.0);
        return Container(width: 155, padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E3A), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: allReached ? const Color(0xFFFFD600) : Colors.white10),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(children: [
              Icon(b.info.icon, size: 16, color: b.color),
              const SizedBox(width: 5),
              Text('x${b.count}', style: TextStyle(color: b.color, fontSize: 12, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('x${b.milestoneMultiplier.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFFFD600), fontSize: 12, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
              value: progress, backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(allReached ? const Color(0xFFFFD600) : const Color(0xFF4CAF50)), minHeight: 5,
            )),
            const SizedBox(height: 4),
            if (!allReached)
              Text('Next: $nextMs → more bonus', style: const TextStyle(color: Colors.white38, fontSize: 9))
            else
              const Text('ALL MILESTONES!', style: TextStyle(color: Color(0xFFFFD600), fontSize: 9, fontWeight: FontWeight.w800)),
          ]),
        );
      },
    ));
  }
  // ─── PLAYER TAB ────────────────────────────────────────────

  String _fmtTime(double secs) {
    final m = (secs / 60).floor();
    final h = (m / 60).floor();
    if (h > 0) return '${h}h ${m % 60}m';
    return '${m}m ${(secs % 60).floor()}s';
  }

  // Achievements
  List<(IconData, String, bool, AchievementReward)> get _achievements => [
    (Icons.touch_app, 'First Tap', totalTaps >= 1, const AchievementReward(coins: 50)),
    (Icons.local_drink, 'First Building', ownedBuildings.isNotEmpty, const AchievementReward(incomeMultPercent: 0.10)),
    (Icons.bolt, '10x Combo', highestCombo >= 10, const AchievementReward(coins: 500)),
    (Icons.whatshot, '20x Combo', highestCombo >= 20, const AchievementReward(tapPower: 1)),
    (Icons.star, 'Level 10', playerLevel >= 10, const AchievementReward(incomeMultPercent: 0.25)),
    (Icons.diamond, 'Level 30', playerLevel >= 30, const AchievementReward(incomeMultPercent: 0.50)),
    (Icons.savings, 'Earn \$10K', totalEarned >= 10000, const AchievementReward(coins: 5000)),
    (Icons.account_balance, 'Earn \$1M', totalEarned >= 1000000, const AchievementReward(coins: 100000)),
    (Icons.military_tech, 'All Buildings', ownedBuildings.length >= 12, const AchievementReward(tapPower: 3)),
    (Icons.emoji_events, '50x Combo', highestCombo >= 50, const AchievementReward(incomeMultPercent: 1.0)),
  ];

  Widget _buildPlayerTab() {
    final achievements = _achievements;
    final unlocked = achievements.where((a) => a.$3).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Level + Tap Power row
        GamePanel(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(children: [
            // Level section
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LEVEL $playerLevel', style: TextStyle(color: _levelColor, fontSize: 16, fontWeight: FontWeight.w900)),
              Text('\$${_fmt(currentTapPower)} per tap', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ]),
            const Spacer(),
            // Level up button
            if (playerLevel < 50)
              GameButton(text: 'LEVEL UP  \$${_fmt(levelUpCost)}', onTap: canLevelUp ? _levelUp : null)
            else
              const Text('MAX', style: TextStyle(color: Color(0xFFFFD600), fontSize: 12, fontWeight: FontWeight.w900)),
          ]),
        ),
        const SizedBox(height: 6),
        // Prestige section
        GamePanel(borderColor: canPrestige ? const Color(0xFFFFB300).withAlpha(50) : null, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Rank + era count
            Row(children: [
              Text(currentPrestigeRank.name.toUpperCase(), style: TextStyle(color: currentPrestigeRank.color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
              if (totalPrestiges > 0) Text('  ×$totalPrestiges', style: const TextStyle(color: Colors.white30, fontSize: 10)),
              const Spacer(),
              if (totalPrestiges > 0) Text('Rep $reputationLevel  +${reputationLevel * 10}%', style: const TextStyle(color: Color(0xFFFFD600), fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            // Progress to next era
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (canPrestige)
                  Text('Ready! Earn $pendingRP reputation', style: const TextStyle(color: Color(0xFFFFB300), fontSize: 10, fontWeight: FontWeight.w700))
                else ...[
                  Text('Earn \$${_fmt(prestigeThreshold)} to start new era', style: const TextStyle(color: Colors.white30, fontSize: 9)),
                  const SizedBox(height: 3),
                  ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(
                    value: (totalEarned / prestigeThreshold).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withAlpha(10),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB300)),
                    minHeight: 4,
                  )),
                ],
              ])),
              const SizedBox(width: 10),
              if (canPrestige)
                GameButton(text: 'NEW ERA', onTap: () => setState(() => _showPrestigePreview = true), color: const Color(0xFFFFB300)),
            ]),
            // Reputation progress + milestones
            if (totalPrestiges > 0) ...[
              const SizedBox(height: 6),
              // Rep level + progress bar
              Row(children: [
                Text('REP LEVEL $reputationLevel', style: const TextStyle(color: Color(0xFFFFB300), fontSize: 10, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                Text('$totalRP / ${rpForNextLevel} RP', style: const TextStyle(color: Colors.white30, fontSize: 8)),
              ]),
              const SizedBox(height: 3),
              ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(
                value: rpProgress, backgroundColor: Colors.white.withAlpha(8),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB300)), minHeight: 4,
              )),
              const SizedBox(height: 4),
              // Current bonuses
              _textRow('Income bonus', '+${reputationLevel * 10}%'),
              _textRow('Tap bonus', '+${reputationLevel * 5}%'),
              _textRow('Start cash', '\$${_fmt(startingCash)}'),
              _textRow('Offline cap', '${(offlineCapSeconds / 3600).toStringAsFixed(0)}h'),
            ],
          ]),
        ),
        const SizedBox(height: 6),
        // Stats + Achievements row
        Row(children: [
          // Stats
          Expanded(child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1520),
              border: Border.all(color: Colors.white.withAlpha(15)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _textRow('Taps', _fmt(totalTaps.toDouble())),
              _textRow('Best combo', '${highestCombo}x'),
              _textRow('Play time', _fmtTime(playTime)),
              _textRow('Earned', '\$${_fmt(totalEarned)}'),
            ]),
          )),
          const SizedBox(width: 6),
          // Achievements
          Expanded(child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1520),
              border: Border.all(color: Colors.white.withAlpha(15)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$unlocked/${achievements.length} completed', style: const TextStyle(color: Colors.white38, fontSize: 9)),
              const SizedBox(height: 4),
              Wrap(spacing: 3, runSpacing: 3, children: achievements.map((a) {
                return Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: a.$3 ? const Color(0xFF1B5E20) : const Color(0xFF0A0A18),
                    border: Border.all(color: a.$3 ? const Color(0xFF4CAF50).withAlpha(120) : Colors.white.withAlpha(8)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: a.$3 ? const Center(child: Text('✓', style: TextStyle(color: Color(0xFF81C784), fontSize: 10, fontWeight: FontWeight.w900))) : null,
                );
              }).toList()),
            ]),
          )),
        ]),
      ]),
    );
  }

  Widget _textRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 9)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  // ─── BUILDINGS TAB (v2 — timer bars, collect, level, manager) ─

  Widget _buildBuildingsTab() {
    final unlocked = unlockedBuildings;
    if (unlocked.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('Tap to earn, then buy buildings!', style: TextStyle(color: Colors.white38, fontSize: 12)));

    final gm = achievementIncomeMultiplier * reputationIncomeMultiplier;
    final readyCount = ownedBuildings.where((b) => b.readyToCollect).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        // Collect All
        if (readyCount > 0)
          Padding(padding: const EdgeInsets.only(bottom: 6), child: GameButton(text: 'COLLECT ALL ($readyCount)', onTap: _collectAll, fontSize: 11)),
        // Building rows — vertical list
        ...unlocked.map((info) {
          final existing = ownedBuildings.where((b) => b.info.id == info.id).toList();
          final owned = existing.isNotEmpty;
          final b = owned ? existing.first : null;
          final count = b?.count ?? 0;
          final cost = owned ? b!.nextCost : info.baseCost;
          final canBuy = money >= cost;
          final hasManager = managers.contains(info.id);
          final mgrCost = managerCost(info);
          final canHireMgr = money >= mgrCost && !hasManager && owned;
          final income = b?.incomePerCycle(gm) ?? (info.baseIncome * info.prodTime).toDouble();
          final isReady = b != null && b.readyToCollect;

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF141828), Color(0xFF0D1520)]),
              border: Border.all(color: isReady ? const Color(0xFF4CAF50).withAlpha(80) : Colors.white.withAlpha(10)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              // Left: building icon + name + count + timer
              SizedBox(width: 28, height: 28, child: Container(
                decoration: BoxDecoration(color: info.colors[0].withAlpha(30), borderRadius: BorderRadius.circular(4)),
                child: Icon(info.icon, size: 16, color: info.colors[0]),
              )),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(info.name, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                  if (owned) Text('  x$count', style: TextStyle(color: info.colors[0], fontSize: 9, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  if (owned) Text('\$${_fmt(income)}/${info.prodTime.toInt()}s', style: const TextStyle(color: Colors.white30, fontSize: 8)),
                ]),
                if (owned) ...[
                  const SizedBox(height: 3),
                  // Timer bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: isReady ? 1.0 : b!.timerProgress,
                      backgroundColor: Colors.white.withAlpha(8),
                      valueColor: AlwaysStoppedAnimation(isReady ? const Color(0xFF4CAF50) : const Color(0xFF42A5F5)),
                      minHeight: 4,
                    ),
                  ),
                ] else
                  Text('\$${_fmt(info.baseCost)} to unlock', style: TextStyle(color: Colors.white.withAlpha(50), fontSize: 8)),
              ])),
              const SizedBox(width: 6),
              // Right: action buttons
              if (isReady)
                GameButton(text: 'COLLECT', onTap: () => _collectBuilding(b!), fontSize: 8, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5))
              else if (owned && hasManager)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('AUTO ', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 8, fontWeight: FontWeight.w700)),
                  GameButton(text: '+1', onTap: canBuy ? () => _buyBuilding(info) : null, color: const Color(0xFF42A5F5), fontSize: 7, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3)),
                  if (money >= _bulkCost(info, count, 10))
                    Padding(padding: const EdgeInsets.only(left: 2), child: GameButton(text: '+10', onTap: () => _buyBuilding(info, amount: 10), color: const Color(0xFF1565C0), fontSize: 7, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3))),
                ])
              else ...[
                GameButton(text: owned ? '+1' : 'BUY', onTap: canBuy ? () => _buyBuilding(info) : null, color: const Color(0xFF42A5F5), fontSize: 8, padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5)),
                if (owned && money >= _bulkCost(info, count, 10))
                  Padding(padding: const EdgeInsets.only(left: 2), child: GameButton(text: '+10', onTap: () => _buyBuilding(info, amount: 10), color: const Color(0xFF1565C0), fontSize: 8, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5))),
                if (owned && !hasManager)
                  Padding(padding: const EdgeInsets.only(left: 2), child: GameButton(text: 'MGR', onTap: canHireMgr ? () => _buyManager(info) : null, color: const Color(0xFFFF9800), fontSize: 8, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5))),
              ],
            ]),
          );
        }),
      ]),
    );
  }

  // ─── SKILLS TAB ─────────────────────────────────────────────

  Widget _buildSkillsTab() {
    final skills = [
      ('Tap Damage', '+4 tap power for 60s', skillTapPowerTimer, skillTapPowerActive, 100.0 * pow(1.8, skillTapPowerBuys)),
      ('Tap Boost', '+50% tap income for 60s', skillTapIncomeTimer, skillTapIncomeActive, 200.0 * pow(2.0, skillTapIncomeBuys)),
      ('Combo Frenzy', '+1.5s combo window for 60s', skillComboDurationTimer, skillComboDurationActive, 500.0 * pow(2.2, skillComboDurationBuys)),
      ('Speed Rush', '-30% prod time for 60s', skillSpeedBoostTimer, skillSpeedBoostActive, 2000.0 * pow(2.5, skillSpeedBoostBuys)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(children: [
        const Text('SKILLS  (timed boosts, resets each era)', style: TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 1)),
        const SizedBox(height: 6),
        ...skills.asMap().entries.map((entry) {
          final i = entry.key;
          final (name, desc, timer, active, cost) = entry.value;
          final canBuy = money >= cost;
          final secs = timer.ceil();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF0D1520).withAlpha(230) : const Color(0xFF0D1520),
                border: Border.all(color: active ? const Color(0xFF4CAF50).withAlpha(80) : (canBuy ? const Color(0xFF4CAF50).withAlpha(40) : Colors.white.withAlpha(10))),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(name, style: TextStyle(color: active ? const Color(0xFF4CAF50) : Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                      if (active) ...[
                        const SizedBox(width: 6),
                        Text('${secs}s', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 9, fontWeight: FontWeight.w700)),
                      ],
                    ]),
                    Text(desc, style: const TextStyle(color: Colors.white24, fontSize: 8)),
                  ])),
                  GameButton(
                    text: active ? 'RESET \$${_fmt(cost)}' : '\$${_fmt(cost)}',
                    onTap: canBuy ? () => _buySkill(i) : null,
                    color: active ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
                    fontSize: 9,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ]),
                if (active)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: timer / skillDuration,
                        backgroundColor: Colors.white.withAlpha(15),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                        minHeight: 3,
                      ),
                    ),
                  ),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  void _buySkill(int index) {
    final costs = [100.0 * pow(1.8, skillTapPowerBuys), 200.0 * pow(2.0, skillTapIncomeBuys), 500.0 * pow(2.2, skillComboDurationBuys), 2000.0 * pow(2.5, skillSpeedBoostBuys)];
    if (money < costs[index]) return;
    setState(() {
      money -= costs[index];
      switch (index) {
        case 0: skillTapPowerTimer = skillDuration; skillTapPowerBuys++;
        case 1: skillTapIncomeTimer = skillDuration; skillTapIncomeBuys++;
        case 2: skillComboDurationTimer = skillDuration; skillComboDurationBuys++;
        case 3: skillSpeedBoostTimer = skillDuration; skillSpeedBoostBuys++;
      }
    });
    _sound.playUpgrade();
  }

  // ─── MARKET TAB ─────────────────────────────────────────────

  Widget _buildMarketTab() {
    final items = [
      ('Starter Pack', 'x2 income for 1 hour', '\$0.99', Icons.card_giftcard, const Color(0xFF4CAF50)),
      ('Gem Pack', '500 City Stars', '\$4.99', Icons.star, const Color(0xFFFFD600)),
      ('Ad Free', 'Remove all ads', '\$2.99', Icons.block, const Color(0xFF42A5F5)),
      ('Mega Pack', 'All buildings + stars', '\$9.99', Icons.diamond, const Color(0xFFFF9800)),
    ];

    return SizedBox(height: 90, child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (_, i) {
        final (name, desc, price, icon, color) = items[i];
        return Container(
          width: 110, padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withAlpha(30), const Color(0xFF151530)]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 7), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(5)),
              child: Text('COMING SOON', style: TextStyle(color: Colors.white.withAlpha(40), fontSize: 7, fontWeight: FontWeight.w700)),
            ),
          ]),
        );
      },
    ));
  }

  // Old prestige tab removed — reputation is in PLAYER tab now

  // Old prestige tab helpers removed — reputation in PLAYER tab

  // ─── PRESTIGE PREVIEW ──────────────────────────────────────

  Widget _buildPrestigePreview() {
    final rp = pendingRP;
    final newTotalRP = totalRP + rp;
    final newRepLevel = (log(newTotalRP / 25 + 1) / log(2)).floor();
    final levelGain = newRepLevel - reputationLevel;

    return GestureDetector(
      onTap: () {},
      child: Container(
        color: Colors.black87,
        child: Center(child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A237E), Color(0xFF0D1B3E)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFB300), width: 2),
            boxShadow: [BoxShadow(color: const Color(0xFFFFB300).withAlpha(40), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('A NEW ERA BEGINS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 14),
            // RP earned
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFFB300).withAlpha(20), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFB300).withAlpha(60))),
              child: Text('+$rp REPUTATION', style: const TextStyle(color: Color(0xFFFFB300), fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 10),
            // Level change
            if (levelGain > 0)
              Text('Reputation $reputationLevel → $newRepLevel (+$levelGain levels!)', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.w800))
            else
              Text('Reputation stays at level $reputationLevel', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 6),
            // Bonus summary
            Text('Income: +${reputationLevel * 10}% → +${newRepLevel * 10}%', style: const TextStyle(color: Colors.white38, fontSize: 10)),
            Text('Taps: +${reputationLevel * 5}% → +${newRepLevel * 5}%', style: const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 10),
            const Text('Resets: money, buildings, skills', style: TextStyle(color: Colors.redAccent, fontSize: 9)),
            const Text('Keeps: reputation, lifetime stats', style: TextStyle(color: Colors.greenAccent, fontSize: 9)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GameButton(text: 'NOT YET', onTap: () => setState(() => _showPrestigePreview = false), color: const Color(0xFF455A64), fontSize: 13, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
              const SizedBox(width: 14),
              GameButton(text: 'BEGIN NEW ERA', onTap: _executePrestige, color: const Color(0xFFFFB300), fontSize: 14, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11)),
            ]),
          ]),
        )),
      ),
    );
  }

  // ─── DAILY REWARD OVERLAY ────────────────────────────────

  Widget _buildDailyRewardOverlay() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastDailyClaimDate == today) return const SizedBox.shrink();

    // Figure out which day they're on
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final nextDay = (lastDailyClaimDate == yesterday) ? (dailyStreak + 1) % 7 : 0;
    final reward = dailyRewards[nextDay];
    final rewardText = reward.coins > 0 ? '+\$${_fmt(reward.coins)}' : '+${reward.stars} Stars';

    return GestureDetector(
      onTap: _claimDailyReward,
      child: Container(
        color: Colors.black54,
        child: Center(child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A237E), Color(0xFF0D1B3E)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD600), width: 2),
            boxShadow: [BoxShadow(color: const Color(0xFFFFD600).withAlpha(40), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today, size: 40, color: Color(0xFFFFD600)),
            const SizedBox(height: 10),
            const Text('DAILY REWARD', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 6),
            Text('Day ${nextDay + 1} of 7', style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 12),
            // 7 day indicators
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(7, (i) {
              final claimed = i < nextDay || (lastDailyClaimDate == yesterday && i < dailyStreak + 1);
              final isToday = i == nextDay;
              final r = dailyRewards[i];
              return Container(
                width: 28, height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFFFFD600).withAlpha(40) : (claimed ? const Color(0xFF4CAF50).withAlpha(40) : Colors.white.withAlpha(8)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isToday ? const Color(0xFFFFD600) : (claimed ? const Color(0xFF4CAF50) : Colors.white12)),
                ),
                child: Center(child: claimed
                  ? const Icon(Icons.check, size: 14, color: Color(0xFF4CAF50))
                  : Text(r.stars > 0 ? '${r.stars}' : '\$', style: TextStyle(color: isToday ? const Color(0xFFFFD600) : Colors.white30, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              );
            })),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFFFD600).withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFD600).withAlpha(80))),
              child: Text(rewardText, style: const TextStyle(color: Color(0xFFFFD600), fontSize: 28, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF388E3C)]), borderRadius: BorderRadius.circular(14)),
              child: const Text('CLAIM', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ]),
        )),
      ),
    );
  }

  // ─── ONBOARDING OVERLAY ──────────────────────────────────

  Widget _buildOnboarding() {
    String message;
    IconData icon;
    Alignment align;

    switch (onboardingStep) {
      case 1:
        message = 'Tap the screen to earn coins!';
        icon = Icons.touch_app;
        align = Alignment.center;
      case 2:
        message = 'Go to SHOP tab and buy your first building!';
        icon = Icons.storefront;
        align = Alignment.bottomCenter;
      case 3:
        message = 'Go to YOU tab and level up your tap power!';
        icon = Icons.person;
        align = Alignment.bottomCenter;
      default:
        return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: onboardingStep == 1 ? Alignment.center : const Alignment(0, 0.4),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xEE1A1A3A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD600).withAlpha(120)),
              boxShadow: [BoxShadow(color: const Color(0xFFFFD600).withAlpha(30), blurRadius: 20)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 24, color: const Color(0xFFFFD600)),
              const SizedBox(width: 10),
              Flexible(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── CITY PAINTER ────────────────────────────────────────────

class CityPainter extends CustomPainter {
  final int cityLevel;
  final List<OwnedBuilding> buildings;
  final List<TapParticle> particles;
  final List<TapRing> rings;
  final List<ComboRing> comboRings;
  final List<TapGlow> tapGlows;
  final List<GroundRipple> groundRipples;
  final GoldenCoin? goldenCoin;
  final double totalEarned;

  CityPainter({required this.cityLevel, required this.buildings, required this.particles, required this.rings, required this.comboRings, required this.tapGlows, required this.groundRipples, this.goldenCoin, this.totalEarned = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final gY = size.height * 0.62;
    _drawSky(canvas, size);
    _drawMountains(canvas, size, gY);
    _drawClouds(canvas, size);
    _drawSun(canvas, size);
    _drawBgBuildings(canvas, size, gY, 0.10, 12, 35);
    _drawBgBuildings(canvas, size, gY, 0.18, 8, 60);
    _drawBgBuildings(canvas, size, gY, 0.30, 5, 90);
    _drawGround(canvas, size, gY);
    _drawStreetDetails(canvas, size, gY);
    _drawOwnedBuildings(canvas, size, row: 0); // Back row (behind road)
    _drawOwnedBuildings(canvas, size, row: 1); // Front row (in front of road)
    _drawGroundRipples(canvas, size, gY);
    _drawGoldenCoin(canvas, size);
    _drawTapGlows(canvas);
    _drawRings(canvas);
    _drawComboRings(canvas);
    _drawParticles(canvas);
    _drawTapHint(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    final palettes = [
      [const Color(0xFF87CEEB), const Color(0xFFAED8F0), const Color(0xFFD4E8C2)], // village - warm
      [const Color(0xFF64B5F6), const Color(0xFF90CAF9), const Color(0xFFC5DEB5)], // town
      [const Color(0xFF42A5F5), const Color(0xFF5C6BC0), const Color(0xFF90A4AE)], // city
      [const Color(0xFF1E3A5F), const Color(0xFF283593), const Color(0xFF455A64)], // metropolis
      [const Color(0xFF0D1B3E), const Color(0xFF1A237E), const Color(0xFF1B2838)], // megacity night
    ];
    final c = palettes[(cityLevel - 1).clamp(0, 4)];
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Stars for high city levels (night sky)
    if (cityLevel >= 4) {
      final rng = Random(77);
      final starP = Paint()..color = Colors.white.withAlpha(cityLevel >= 5 ? 120 : 60);
      for (int i = 0; i < 30 + cityLevel * 10; i++) {
        final sx = rng.nextDouble() * size.width;
        final sy = rng.nextDouble() * size.height * 0.35;
        final sr = 0.5 + rng.nextDouble() * 1.5;
        canvas.drawCircle(Offset(sx, sy), sr, starP);
      }
    }
  }

  void _drawMountains(Canvas canvas, Size size, double gY) {
    // Far mountains
    final farP = Paint()..color = Color.fromRGBO(60, 80, 100, cityLevel >= 4 ? 0.3 : 0.15);
    final path1 = Path()..moveTo(0, gY);
    final rng1 = Random(33);
    for (double x = 0; x <= size.width; x += 20) {
      final h = gY - (rng1.nextDouble() * 0.12 + 0.08) * size.height;
      path1.lineTo(x, h);
    }
    path1.lineTo(size.width, gY); path1.close();
    canvas.drawPath(path1, farP);

    // Near hills (more visible)
    if (cityLevel <= 3) {
      final nearP = Paint()..color = Color.fromRGBO(50, 100, 60, 0.25);
      final path2 = Path()..moveTo(0, gY);
      final rng2 = Random(55);
      for (double x = 0; x <= size.width; x += 30) {
        final h = gY - (rng2.nextDouble() * 0.06 + 0.02) * size.height;
        path2.lineTo(x, h);
      }
      path2.lineTo(size.width, gY); path2.close();
      canvas.drawPath(path2, nearP);
    }
  }

  void _drawClouds(Canvas canvas, Size size) {
    final alpha = cityLevel >= 4 ? 18 : 40;
    final rng = Random(7);
    for (int i = 0; i < 7; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = size.height * 0.04 + rng.nextDouble() * size.height * 0.22;
      final w = 50 + rng.nextDouble() * 90;
      final p = Paint()..color = Colors.white.withAlpha(alpha);
      // Multi-blob cloud
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: w * 0.35), p);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + w * 0.25, cy - 6), width: w * 0.65, height: w * 0.3), p);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - w * 0.2, cy + 3), width: w * 0.55, height: w * 0.25), p);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + w * 0.4, cy + 4), width: w * 0.4, height: w * 0.22), p);
    }
  }

  void _drawSun(Canvas canvas, Size size) {
    if (cityLevel >= 5) return; // no sun at night
    final cx = size.width * 0.82, cy = size.height * 0.09;
    // Sun rays
    final rayP = Paint()..color = const Color(0x15FFD54F)..strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      final angle = i * pi / 6;
      canvas.drawLine(Offset(cx + cos(angle) * 30, cy + sin(angle) * 30), Offset(cx + cos(angle) * 65, cy + sin(angle) * 65), rayP);
    }
    canvas.drawCircle(Offset(cx, cy), 50, Paint()..color = const Color(0x20FFD54F));
    canvas.drawCircle(Offset(cx, cy), 32, Paint()..color = const Color(0x50FFE082));
    canvas.drawCircle(Offset(cx, cy), 18, Paint()..color = const Color(0x99FFF176));
  }

  void _drawBgBuildings(Canvas canvas, Size size, double gY, double maxH, int seed, int alpha) {
    if (cityLevel < 2 && seed != 5) return;
    final rng = Random(seed);
    final count = 10 + cityLevel * 3;
    for (int i = 0; i < count; i++) {
      final x = (i / count) * size.width - 3;
      final w = size.width / count;
      final h = (rng.nextDouble() * maxH + 0.02) * size.height;
      final a = (alpha * (0.4 + cityLevel * 0.12)).clamp(0, 255).toInt();
      // Slight color variation per building
      final shade = 30 + rng.nextInt(25);
      canvas.drawRect(Rect.fromLTWH(x, gY - h, w - 1.5, h), Paint()..color = Color.fromRGBO(shade, shade, shade + 30, a / 255));
      // Windows on closer layers
      if (alpha > 55) {
        final wp = Paint()..color = Color.fromRGBO(255, 255, 200, a / 255 * 0.35);
        for (double wy = gY - h + 5; wy < gY - 3; wy += 7) {
          for (double wx = x + 2; wx < x + w - 4; wx += 5) {
            if (rng.nextDouble() > 0.4) canvas.drawRect(Rect.fromLTWH(wx, wy, 2.5, 2.5), wp);
          }
        }
      }
    }
  }

  void _drawGround(Canvas canvas, Size size, double gY) {
    // Grass strip above sidewalk
    if (cityLevel <= 2) {
      canvas.drawRect(Rect.fromLTWH(0, gY - 3, size.width, 6), Paint()..color = const Color(0xFF558B2F));
    }

    // Sidewalk
    final swColor = cityLevel >= 3 ? const Color(0xFF9E9E9E) : const Color(0xFFBCAAA4);
    canvas.drawRect(Rect.fromLTWH(0, gY, size.width, 8), Paint()..color = swColor);
    // Sidewalk edge
    canvas.drawRect(Rect.fromLTWH(0, gY + 7, size.width, 2), Paint()..color = swColor.withAlpha(150));

    // Road
    final roadColors = [
      [const Color(0xFF5D4037), const Color(0xFF4E342E)], // dirt village
      [const Color(0xFF6D4C41), const Color(0xFF5D4037)], // gravel town
      [const Color(0xFF616161), const Color(0xFF424242)], // asphalt city
      [const Color(0xFF546E7A), const Color(0xFF37474F)], // dark metro
      [const Color(0xFF37474F), const Color(0xFF263238)], // night mega
    ];
    final rc = roadColors[(cityLevel - 1).clamp(0, 4)];
    final roadTop = gY + 10;
    canvas.drawRect(Rect.fromLTWH(0, roadTop, size.width, size.height - roadTop),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: rc).createShader(Rect.fromLTWH(0, roadTop, size.width, size.height - roadTop)));

    // Road center line (dashed yellow)
    if (cityLevel >= 2) {
      final lineY = roadTop + 18;
      final lp = Paint()..color = Color.fromRGBO(255, 235, 59, cityLevel >= 3 ? 0.4 : 0.2)..strokeWidth = 2;
      for (double x = 5; x < size.width; x += 28) {
        canvas.drawLine(Offset(x, lineY), Offset(x + 14, lineY), lp);
      }
    }

    // Road edge lines (white)
    if (cityLevel >= 3) {
      final ep = Paint()..color = Colors.white.withAlpha(35)..strokeWidth = 1.5;
      canvas.drawLine(Offset(0, roadTop + 4), Offset(size.width, roadTop + 4), ep);
      canvas.drawLine(Offset(0, roadTop + 32), Offset(size.width, roadTop + 32), ep);
    }
  }

  void _drawStreetDetails(Canvas canvas, Size size, double gY) {
    final rng = Random(66);

    // Trees (village/town) or streetlamps (city+)
    if (cityLevel <= 2) {
      for (int i = 0; i < 6; i++) {
        final tx = 20 + i * (size.width / 6);
        // Trunk
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(tx - 2, gY - 16, 4, 18), const Radius.circular(1)), Paint()..color = const Color(0xFF5D4037));
        // Canopy (layered circles)
        final leafColor = Color.lerp(const Color(0xFF2E7D32), const Color(0xFF43A047), rng.nextDouble())!;
        canvas.drawCircle(Offset(tx, gY - 20), 10 + rng.nextDouble() * 4, Paint()..color = leafColor);
        canvas.drawCircle(Offset(tx - 5, gY - 17), 7, Paint()..color = leafColor.withAlpha(200));
        canvas.drawCircle(Offset(tx + 5, gY - 18), 8, Paint()..color = leafColor.withAlpha(220));
      }
    } else {
      // Streetlamps
      for (int i = 0; i < 5; i++) {
        final lx = 30 + i * (size.width / 5);
        final pole = Paint()..color = const Color(0xFF78909C)..strokeWidth = 2;
        canvas.drawLine(Offset(lx, gY), Offset(lx, gY - 28), pole);
        // Lamp head
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(lx - 5, gY - 30, 10, 5), const Radius.circular(2)), Paint()..color = const Color(0xFF90A4AE));
        // Light glow
        canvas.drawCircle(Offset(lx, gY - 25), 12, Paint()..color = Color.fromRGBO(255, 245, 200, cityLevel >= 4 ? 0.15 : 0.08));
      }
    }

    // Benches (every other spot, on sidewalk)
    if (cityLevel >= 2) {
      for (int i = 0; i < 3; i++) {
        final bx = 60 + i * (size.width / 3);
        final benchP = Paint()..color = const Color(0xFF795548);
        canvas.drawRect(Rect.fromLTWH(bx, gY + 1, 14, 3), benchP); // seat
        canvas.drawRect(Rect.fromLTWH(bx, gY + 4, 2, 3), benchP);  // left leg
        canvas.drawRect(Rect.fromLTWH(bx + 12, gY + 4, 2, 3), benchP); // right leg
      }
    }

    // Fire hydrants
    if (cityLevel >= 3) {
      for (int i = 0; i < 2; i++) {
        final hx = 100.0 + i * (size.width / 2);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(hx, gY - 6, 5, 8), const Radius.circular(1.5)), Paint()..color = const Color(0xFFD32F2F));
        canvas.drawCircle(Offset(hx + 2.5, gY - 6), 3, Paint()..color = const Color(0xFFE53935));
      }
    }

    // Animated cars on road
    final roadY = gY + 22;
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final carAlpha = cityLevel >= 4 ? 90 : 60;
    for (int i = 0; i < 4; i++) {
      final cx1 = ((now * (18 + i * 6) + i * 100) % (size.width + 40)) - 20;
      final carColors = [const Color(0xFFE53935), const Color(0xFF1565C0), const Color(0xFFFFB300), const Color(0xFF4CAF50)];
      final carW = 14.0 + (i % 2) * 4; // vary size
      // Car body
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx1, roadY - 2, carW, 6), const Radius.circular(2)), Paint()..color = carColors[i].withAlpha(carAlpha));
      // Car roof (smaller rect on top)
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx1 + 3, roadY - 4, carW - 6, 3), const Radius.circular(1)), Paint()..color = carColors[i].withAlpha(carAlpha - 15));
      // Headlights
      canvas.drawCircle(Offset(cx1 + carW - 1, roadY + 1), 1, Paint()..color = Colors.yellow.withAlpha(carAlpha));

      // Cars going left
      final cx2 = size.width - ((now * (14 + i * 5) + i * 80) % (size.width + 40)) + 20;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx2, roadY + 10, 12, 5), const Radius.circular(2)), Paint()..color = const Color(0xFF78909C).withAlpha(40));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx2 + 2, roadY + 8, 8, 3), const Radius.circular(1)), Paint()..color = const Color(0xFF78909C).withAlpha(30));
    }

    // Walking people on sidewalk
    for (int i = 0; i < 5; i++) {
      final speed = 8 + i * 3.0;
      final dir = i % 2 == 0 ? 1.0 : -1.0;
      final px = dir > 0
          ? ((now * speed + i * 70) % (size.width + 20)) - 10
          : size.width - ((now * speed + i * 50) % (size.width + 20)) + 10;
      final py = gY + 3;
      final personAlpha = (45 + i * 5).clamp(0, 70);
      // Body (small line)
      final bodyColor = [const Color(0xFF42A5F5), const Color(0xFFEF5350), const Color(0xFF66BB6A), const Color(0xFFFFB74D), const Color(0xFFAB47BC)][i];
      canvas.drawLine(Offset(px, py), Offset(px, py - 5), Paint()..color = bodyColor.withAlpha(personAlpha)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
      // Head
      canvas.drawCircle(Offset(px, py - 6.5), 1.5, Paint()..color = const Color(0xFFFFCCBC).withAlpha(personAlpha));
      // Legs (animated walk cycle)
      final walkPhase = sin(now * 6 + i * 2) * 1.5;
      canvas.drawLine(Offset(px, py), Offset(px + walkPhase, py + 3), Paint()..color = bodyColor.withAlpha(personAlpha - 10)..strokeWidth = 1);
      canvas.drawLine(Offset(px, py), Offset(px - walkPhase, py + 3), Paint()..color = bodyColor.withAlpha(personAlpha - 10)..strokeWidth = 1);
    }

    // Flying birds (high in the sky, occasionally)
    for (int i = 0; i < 3; i++) {
      final birdX = ((now * (12 + i * 4) + i * 150) % (size.width + 60)) - 30;
      final birdY = size.height * 0.15 + sin(now * 2 + i * 3) * 10 + i * 20;
      final birdAlpha = 40 + i * 10;
      final wingPhase = sin(now * 8 + i * 4) * 3;
      final bp = Paint()..color = Colors.black.withAlpha(birdAlpha)..strokeWidth = 1..strokeCap = StrokeCap.round;
      // V-shape wings
      canvas.drawLine(Offset(birdX - 4, birdY + wingPhase), Offset(birdX, birdY), bp);
      canvas.drawLine(Offset(birdX, birdY), Offset(birdX + 4, birdY + wingPhase), bp);
    }
  }

  void _drawOwnedBuildings(Canvas canvas, Size size, {required int row}) {
    if (buildings.isEmpty) return;
    final gY = size.height * 0.62;
    final frontY = gY + 38; // Front row below road
    final baseY = row == 0 ? gY : frontY;

    // Get buildings for this row
    final rowBuildings = buildings.where((b) => b.info.row == row).toList();
    if (rowBuildings.isEmpty) return;

    // 6 slots per row
    final backRowIds = allBuildings.where((b) => b.row == row).toList();
    const totalSlots = 6;
    final slotW = size.width / totalSlots;
    final bw = slotW * 0.72;

    for (final b in rowBuildings) {
      final slotIndex = backRowIds.indexWhere((info) => info.id == b.info.id);
      if (slotIndex < 0) continue;
      final cx = slotW * slotIndex + slotW / 2;
      final bh = size.height * b.heightFraction;

      if (b.isBuilding && row == 0) _drawCrane(canvas, size, cx, baseY, bw, bh, b.craneProgress);
      if (bh < 2) continue;

      final bx = cx - bw / 2;
      final by = baseY - bh;

      // Ground shadow (oval at base)
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, baseY + 2), width: bw * 1.3, height: 8), Paint()..color = Colors.black.withAlpha(40));
      // Building drop shadow
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx + 3, by + 3, bw, bh), const Radius.circular(3)), Paint()..color = Colors.black.withAlpha(30));

      // Draw unique building per type
      switch (b.info.id) {
        case 'lemonade': _drawLemonade(canvas, bx, by, bw, bh, baseY, b);
        case 'barber': _drawBarber(canvas, bx, by, bw, bh, baseY, b);
        case 'coffee': _drawCoffee(canvas, bx, by, bw, bh, baseY, b);
        case 'restaurant': _drawRestaurant(canvas, bx, by, bw, bh, baseY, b);
        case 'mall': _drawMall(canvas, bx, by, bw, bh, baseY, b);
        case 'hotel': _drawHotel(canvas, bx, by, bw, bh, baseY, b);
        case 'salon': _drawSalon(canvas, bx, by, bw, bh, baseY, b);
        case 'gym': _drawGym(canvas, bx, by, bw, bh, baseY, b);
        case 'cinema': _drawCinema(canvas, bx, by, bw, bh, baseY, b);
        case 'hospital': _drawHospital(canvas, bx, by, bw, bh, baseY, b);
        case 'stadium': _drawStadium(canvas, bx, by, bw, bh, baseY, b);
        case 'space': _drawSpace(canvas, bx, by, bw, bh, baseY, b, cx);
      }

      // Count label
      final countTp = TextPainter(
        text: TextSpan(text: 'x${b.count}', style: const TextStyle(color: Color(0xFFFFD600), fontSize: 8, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black87, blurRadius: 3)])),
        textDirection: TextDirection.ltr,
      );
      countTp.layout();
      countTp.paint(canvas, Offset(cx - countTp.width / 2, baseY + 4));

      // Bouncing money indicator when ready to collect
      if (b.readyToCollect) {
        final t = DateTime.now().millisecondsSinceEpoch / 400.0;
        final bob = sin(t) * 6;
        final pulse = 0.7 + sin(t * 2) * 0.3; // 0.4 to 1.0 pulsing
        final noteY = by - 28 + bob;

        // Glowing circle background
        canvas.drawCircle(Offset(cx, noteY + 4), 18 * pulse, Paint()..color = Color.fromRGBO(76, 175, 80, 0.15 * pulse));
        canvas.drawCircle(Offset(cx, noteY + 4), 12, Paint()..color = Color.fromRGBO(76, 175, 80, 0.25 * pulse));

        // Big green banknote
        final noteW = 24.0;
        final noteH = 14.0;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - noteW / 2, noteY - noteH / 2, noteW, noteH), const Radius.circular(3)), Paint()..color = const Color(0xFF2E7D32));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - noteW / 2 + 2, noteY - noteH / 2 + 2, noteW - 4, noteH - 4), const Radius.circular(2)), Paint()..color = const Color(0xFF4CAF50));
        // "$" symbol
        final tp = TextPainter(text: const TextSpan(text: '\$', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, noteY - tp.height / 2));

        // Amount text below
        final amtTp = TextPainter(
          text: TextSpan(text: '\$${_fmt(b.pendingMoney)}', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 8, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 3)])),
          textDirection: TextDirection.ltr,
        );
        amtTp.layout();
        amtTp.paint(canvas, Offset(cx - amtTp.width / 2, noteY + noteH / 2 + 2));
      }
    }
  }

  // ─── UNIQUE BUILDING DRAWINGS ─────────────────────────────

  void _drawLemonade(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b) {
    // Cart body
    final cartH = bh * 0.5;
    final cartY = gY - cartH;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx + 2, cartY, bw - 4, cartH), const Radius.circular(4)), Paint()..color = b.color);
    // Cart darker bottom
    canvas.drawRect(Rect.fromLTWH(bx + 2, cartY + cartH * 0.7, bw - 4, cartH * 0.3), Paint()..color = b.color.withAlpha(180));
    // Wheels
    canvas.drawCircle(Offset(bx + bw * 0.25, gY), 4, Paint()..color = const Color(0xFF5D4037));
    canvas.drawCircle(Offset(bx + bw * 0.75, gY), 4, Paint()..color = const Color(0xFF5D4037));
    canvas.drawCircle(Offset(bx + bw * 0.25, gY), 2, Paint()..color = const Color(0xFF8D6E63));
    canvas.drawCircle(Offset(bx + bw * 0.75, gY), 2, Paint()..color = const Color(0xFF8D6E63));
    // Umbrella pole
    final polePaint = Paint()..color = const Color(0xFF795548)..strokeWidth = 2;
    canvas.drawLine(Offset(bx + bw / 2, cartY), Offset(bx + bw / 2, by), polePaint);
    // Umbrella canopy (scalloped)
    final umbrellaW = bw * 1.1;
    final umbrellaX = bx + bw / 2 - umbrellaW / 2;
    final umbrellaH = bh * 0.3;
    // Alternating stripe colors
    final colors = [b.color, Colors.white, b.color, Colors.white];
    final stripeW = umbrellaW / 4;
    for (int s = 0; s < 4; s++) {
      final path = Path()
        ..moveTo(umbrellaX + s * stripeW, by + umbrellaH)
        ..lineTo(umbrellaX + s * stripeW + stripeW / 2, by)
        ..lineTo(umbrellaX + (s + 1) * stripeW, by + umbrellaH)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[s]);
    }
    // Sign text
    _drawLabel(canvas, bx, cartY + 4, bw, 'LEMON', const Color(0xFF5D4037), 7);
  }

  void _drawCoffee(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b) {
    // Main body
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by + bh * 0.2, bw, bh * 0.8), const Radius.circular(3)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [b.color.withAlpha(240), b.color]).createShader(Rect.fromLTWH(bx, by, bw, bh)));
    // Pitched roof
    final roofPath = Path()
      ..moveTo(bx - 3, by + bh * 0.2)
      ..lineTo(bx + bw / 2, by)
      ..lineTo(bx + bw + 3, by + bh * 0.2)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF8D6E63));
    canvas.drawPath(roofPath, Paint()..color = Colors.black.withAlpha(20)..style = PaintingStyle.stroke..strokeWidth = 1);
    // Chimney with smoke
    final chimX = bx + bw * 0.75;
    canvas.drawRect(Rect.fromLTWH(chimX, by - 6, 6, bh * 0.15 + 6), Paint()..color = const Color(0xFF5D4037));
    // Animated smoke puffs (drift upward over time)
    final st = DateTime.now().millisecondsSinceEpoch / 1000.0;
    for (int s = 0; s < 4; s++) {
      final phase = (st * 0.8 + s * 0.7) % 3.0; // each puff cycles over 3 seconds
      final rise = phase * 12; // rises 36px total
      final drift = sin(phase * 2 + s) * 4; // slight horizontal drift
      final fadeAlpha = ((1.0 - phase / 3.0) * 45).clamp(0, 45).toInt();
      final puffSize = 3.0 + phase * 1.5; // grows as it rises
      canvas.drawCircle(Offset(chimX + 3 + drift, by - 8 - rise), puffSize, Paint()..color = Colors.white.withAlpha(fadeAlpha));
    }
    // Windows
    _drawWindows(canvas, bx, by + bh * 0.3, bw, bh * 0.4, b.tier, gY);
    // Door
    _drawDoor(canvas, bx + bw / 2, gY, bw);
    // Sign
    _drawLabel(canvas, bx, by + bh * 0.22, bw, 'CAFE', Colors.white, 7);
  }

  void _drawRestaurant(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b) {
    final wide = bw * 1.15;
    final wx = bx - (wide - bw) / 2;
    // Body (wider)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx, by, wide, bh), const Radius.circular(4)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [b.color.withAlpha(240), b.color]).createShader(Rect.fromLTWH(wx, by, wide, bh)));
    // Striped awning
    final awningH = 10.0;
    for (int s = 0; s < 6; s++) {
      final sw = wide / 6;
      final color = s % 2 == 0 ? const Color(0xFFD32F2F) : Colors.white;
      canvas.drawRect(Rect.fromLTWH(wx + s * sw, by - awningH, sw, awningH), Paint()..color = color);
    }
    // Scalloped bottom of awning
    for (double ax = wx; ax < wx + wide; ax += 8) {
      canvas.drawCircle(Offset(ax + 4, by), 4, Paint()..color = const Color(0xFFD32F2F).withAlpha(180));
    }
    // Large window with plates visible
    final winRect = Rect.fromLTWH(wx + 4, by + bh * 0.15, wide - 8, bh * 0.35);
    canvas.drawRRect(RRect.fromRectAndRadius(winRect, const Radius.circular(2)), Paint()..color = const Color(0xBB90CAF9));
    // Warm window glow
    canvas.drawRRect(RRect.fromRectAndRadius(winRect.inflate(2), const Radius.circular(3)), Paint()..color = const Color(0x15FFF9C4));
    // Plates (circles in window)
    for (int p = 0; p < 3; p++) {
      canvas.drawCircle(Offset(wx + wide * 0.2 + p * wide * 0.3, by + bh * 0.32), 4, Paint()..color = Colors.white.withAlpha(150));
      // Fork/knife lines
      canvas.drawLine(Offset(wx + wide * 0.2 + p * wide * 0.3 - 3, by + bh * 0.28), Offset(wx + wide * 0.2 + p * wide * 0.3 - 3, by + bh * 0.36), Paint()..color = Colors.white.withAlpha(80)..strokeWidth = 0.5);
      canvas.drawLine(Offset(wx + wide * 0.2 + p * wide * 0.3 + 3, by + bh * 0.28), Offset(wx + wide * 0.2 + p * wide * 0.3 + 3, by + bh * 0.36), Paint()..color = Colors.white.withAlpha(80)..strokeWidth = 0.5);
    }
    // Chimney + animated steam
    canvas.drawRect(Rect.fromLTWH(wx + wide - 8, by - 6, 5, 8), Paint()..color = const Color(0xFF5D4037));
    final st = DateTime.now().millisecondsSinceEpoch / 1000.0;
    for (int s = 0; s < 3; s++) {
      final phase = (st * 0.6 + s * 0.8) % 2.5;
      final rise = phase * 10;
      final drift = sin(phase * 2 + s) * 3;
      final a = ((1.0 - phase / 2.5) * 35).clamp(0, 35).toInt();
      canvas.drawCircle(Offset(wx + wide - 5.5 + drift, by - 8 - rise), 2.5 + phase, Paint()..color = Colors.white.withAlpha(a));
    }
    _drawDoor(canvas, bx + bw / 2, gY, bw);
    _drawLabel(canvas, wx, by + bh * 0.55, wide, 'DINE', Colors.white, 8);
  }

  void _drawMall(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b) {
    final wide = bw * 1.2;
    final wx = bx - (wide - bw) / 2;
    // Main body
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx, by, wide, bh), const Radius.circular(3)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [b.color.withAlpha(240), b.color]).createShader(Rect.fromLTWH(wx, by, wide, bh)));
    // Glass front (large reflective panel)
    final glassRect = Rect.fromLTWH(wx + 3, by + bh * 0.1, wide - 6, bh * 0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(glassRect, const Radius.circular(2)),
      Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xAA90CAF9), const Color(0x88BBDEFB), const Color(0xAA64B5F6)]).createShader(glassRect));
    // Glass divisions
    final divP = Paint()..color = b.color.withAlpha(150)..strokeWidth = 1;
    for (int d = 1; d < 4; d++) {
      final dx = wx + 3 + (wide - 6) / 4 * d;
      canvas.drawLine(Offset(dx, by + bh * 0.1), Offset(dx, by + bh * 0.6), divP);
    }
    // Entrance (wide double door)
    final doorW = wide * 0.25;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx + (wide - doorW) / 2, gY - bh * 0.25, doorW, bh * 0.25), const Radius.circular(2)), Paint()..color = const Color(0xFF37474F));
    canvas.drawLine(Offset(wx + wide / 2, gY - bh * 0.25), Offset(wx + wide / 2, gY), Paint()..color = Colors.white.withAlpha(60)..strokeWidth = 1);
    // Rooftop sign
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx + wide * 0.2, by - 8, wide * 0.6, 10), const Radius.circular(2)), Paint()..color = b.color.withAlpha(220));
    _drawLabel(canvas, wx, by - 7, wide, 'MALL', Colors.white, 7);
  }

  void _drawHotel(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b) {
    final cx = bx + bw / 2;
    // Main tower with slight taper
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(3)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [b.color.withAlpha(240), b.color, b.color.withAlpha(180)]).createShader(Rect.fromLTWH(bx, by, bw, bh)));
    // 3D side shadow
    canvas.drawRect(Rect.fromLTWH(bx + bw * 0.8, by, bw * 0.2, bh), Paint()..color = Colors.black.withAlpha(25));
    // Dome/penthouse
    canvas.drawOval(Rect.fromLTWH(bx + bw * 0.1, by - bh * 0.06, bw * 0.8, bh * 0.14), Paint()..color = b.color.withAlpha(220));
    // Rooftop pool (tier 3+)
    if (b.tier >= 3) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx + bw * 0.15, by + 2, bw * 0.5, 4), const Radius.circular(1)), Paint()..color = const Color(0x6642A5F5));
    }
    // Flag on top
    canvas.drawLine(Offset(cx, by - bh * 0.06), Offset(cx, by - bh * 0.06 - 10), Paint()..color = Colors.grey..strokeWidth = 1);
    canvas.drawRect(Rect.fromLTWH(cx, by - bh * 0.06 - 10, 6, 4), Paint()..color = const Color(0xFFD32F2F));
    // Balconies with glass rails
    final balcP = Paint()..color = Colors.white.withAlpha(40)..strokeWidth = 1;
    for (int f = 0; f < b.tier + 1; f++) {
      final fy = by + bh * 0.18 + f * (bh * 0.65 / (b.tier + 1));
      canvas.drawLine(Offset(bx, fy), Offset(bx + bw, fy), balcP);
      // Glass rail extensions
      canvas.drawRect(Rect.fromLTWH(bx - 3, fy, 3, 4), Paint()..color = const Color(0x5090CAF9));
      canvas.drawRect(Rect.fromLTWH(bx + bw, fy, 3, 4), Paint()..color = const Color(0x5090CAF9));
    }
    // Windows
    _drawWindows(canvas, bx, by + bh * 0.18, bw, bh * 0.5, b.tier, gY);
    // Entrance canopy (wider, red carpet feel)
    final awW = bw * 0.6;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - awW / 2, gY - bh * 0.14 - 5, awW, 5), const Radius.circular(2)), Paint()..color = const Color(0xFF880E4F));
    // Red carpet
    canvas.drawRect(Rect.fromLTWH(cx - 3, gY - bh * 0.14, 6, bh * 0.14), Paint()..color = const Color(0x40D32F2F));
    _drawDoor(canvas, cx, gY, bw);
    // Doorman (tiny person)
    canvas.drawLine(Offset(cx + bw * 0.25, gY), Offset(cx + bw * 0.25, gY - 5), Paint()..color = const Color(0xFF1A237E)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(cx + bw * 0.25, gY - 6.5), 1.5, Paint()..color = const Color(0xFFFFCCBC));
    _drawLabel(canvas, bx, by + bh * 0.08, bw, 'HOTEL', Colors.white, 6);
  }

  void _drawSpace(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b, double cx) {
    // Tapered body
    final bodyPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [b.color.withAlpha(240), b.color, b.color.withAlpha(160)]).createShader(Rect.fromLTWH(bx, by, bw, bh));
    final path = Path()
      ..moveTo(bx + 2, gY)..lineTo(bx + 2, by + bh * 0.2)
      ..lineTo(bx + bw * 0.2, by)..lineTo(bx + bw * 0.8, by)
      ..lineTo(bx + bw - 2, by + bh * 0.2)..lineTo(bx + bw - 2, gY)..close();
    canvas.drawPath(path, bodyPaint);
    // Glass reflection bands
    for (int g = 0; g < 4; g++) {
      final gy = by + bh * 0.1 + g * bh * 0.2;
      canvas.drawRect(Rect.fromLTWH(bx + 4, gy, bw - 8, bh * 0.08), Paint()..color = const Color(0x2290CAF9));
    }
    // 3D edge
    canvas.drawPath(Path()
      ..moveTo(bx + bw * 0.8, by)..lineTo(bx + bw - 2, by + bh * 0.2)
      ..lineTo(bx + bw - 2, gY)..lineTo(bx + bw * 0.65, gY)..close(),
      Paint()..color = Colors.black.withAlpha(25));
    // Windows (grid)
    _drawWindows(canvas, bx + bw * 0.1, by + bh * 0.1, bw * 0.7, bh * 0.7, b.tier, gY);
    // Antenna
    final antPaint = Paint()..color = Colors.grey.shade400..strokeWidth = 2..strokeCap = StrokeCap.round;
    final antTop = by - 15 - b.tier * 4.0;
    canvas.drawLine(Offset(cx, by), Offset(cx, antTop), antPaint);
    // Blinking light
    if ((DateTime.now().millisecondsSinceEpoch ~/ 600) % 2 == 0) {
      canvas.drawCircle(Offset(cx, antTop), 3, Paint()..color = const Color(0xFFFF1744));
    }
    // Struts for level 4+
    if (b.tier >= 4) {
      canvas.drawLine(Offset(cx - 6, by - 4), Offset(cx, antTop + 8), antPaint..strokeWidth = 1.5);
      canvas.drawLine(Offset(cx + 6, by - 4), Offset(cx, antTop + 8), antPaint);
    }
    _drawDoor(canvas, cx, gY, bw);
  }

  // ─── NEW BUILDING DRAWERS ───────────────────────────────────

  void _drawBarber(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b) {
    // Main body
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(3)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [b.color.withAlpha(240), b.color]).createShader(Rect.fromLTWH(bx, by, bw, bh)));
    // Flat roof
    canvas.drawRect(Rect.fromLTWH(bx - 2, by - 3, bw + 4, 5), Paint()..color = b.color.withAlpha(200));
    // Barber pole (red/white/blue stripes)
    final poleX = bx + bw - 6;
    for (int s = 0; s < 6; s++) {
      final py = by + bh * 0.2 + s * (bh * 0.6 / 6);
      final color = s % 3 == 0 ? const Color(0xFFD32F2F) : (s % 3 == 1 ? Colors.white : const Color(0xFF1565C0));
      canvas.drawRect(Rect.fromLTWH(poleX, py, 5, bh * 0.1), Paint()..color = color);
    }
    _drawWindows(canvas, bx, by + bh * 0.15, bw * 0.65, bh * 0.4, b.tier, gY);
    _drawDoor(canvas, bx + bw * 0.35, gY, bw);
    _drawLabel(canvas, bx, by + bh * 0.05, bw, 'BARBER', Colors.white, 6);
  }

  void _drawSalon(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b) {
    final wide = bw * 1.15;
    final wx = bx - (wide - bw) / 2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx, by, wide, bh), const Radius.circular(4)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [b.color.withAlpha(240), b.color]).createShader(Rect.fromLTWH(wx, by, wide, bh)));
    // Sparkle dots (nail polish aesthetic)
    final rng = Random(b.info.id.hashCode);
    for (int i = 0; i < 5; i++) {
      final sx = wx + 5 + rng.nextDouble() * (wide - 10);
      final sy = by + 4 + rng.nextDouble() * bh * 0.4;
      canvas.drawCircle(Offset(sx, sy), 1.5, Paint()..color = Colors.white.withAlpha(100));
    }
    // Window
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx + 4, by + bh * 0.2, wide - 8, bh * 0.35), const Radius.circular(2)), Paint()..color = const Color(0x99FCE4EC));
    _drawDoor(canvas, bx + bw / 2, gY, bw);
    _drawLabel(canvas, wx, by + bh * 0.05, wide, 'NAILS', Colors.white, 6);
  }

  void _drawGym(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b) {
    final wide = bw * 1.2;
    final wx = bx - (wide - bw) / 2;
    // Boxy industrial body
    canvas.drawRect(Rect.fromLTWH(wx, by, wide, bh), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [b.color.withAlpha(240), b.color]).createShader(Rect.fromLTWH(wx, by, wide, bh)));
    // Flat metal roof
    canvas.drawRect(Rect.fromLTWH(wx - 2, by - 2, wide + 4, 4), Paint()..color = const Color(0xFF757575));
    // Dumbbell icon (two circles + bar)
    final dcx = wx + wide / 2;
    final dcy = by + bh * 0.35;
    canvas.drawRect(Rect.fromLTWH(dcx - 8, dcy - 1, 16, 2), Paint()..color = const Color(0xFF424242));
    canvas.drawCircle(Offset(dcx - 8, dcy), 4, Paint()..color = const Color(0xFF424242));
    canvas.drawCircle(Offset(dcx + 8, dcy), 4, Paint()..color = const Color(0xFF424242));
    // Wide entrance
    final doorW = wide * 0.3;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx + (wide - doorW) / 2, gY - bh * 0.35, doorW, bh * 0.35), const Radius.circular(2)), Paint()..color = const Color(0xFF37474F));
    _drawLabel(canvas, wx, by + bh * 0.6, wide, 'GYM', Colors.white, 7);
  }

  void _drawCinema(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b) {
    // Tall facade
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(2)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [b.color.withAlpha(240), b.color]).createShader(Rect.fromLTWH(bx, by, bw, bh)));
    // 3D side
    canvas.drawRect(Rect.fromLTWH(bx + bw * 0.8, by, bw * 0.2, bh), Paint()..color = Colors.black.withAlpha(20));
    // Marquee (protruding sign)
    final mY = by + bh * 0.12;
    final mH = bh * 0.25;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx - 4, mY, bw + 8, mH), const Radius.circular(3)), Paint()..color = const Color(0xFF311B92));
    // Chase lights on marquee (animated sequence)
    final now = DateTime.now().millisecondsSinceEpoch;
    int lightIdx = 0;
    for (double dx = bx - 2; dx < bx + bw + 4; dx += 5) {
      final on = ((now ~/ 150) + lightIdx) % 3 == 0;
      canvas.drawCircle(Offset(dx + 2, mY + 2), 1.5, Paint()..color = Color.fromRGBO(255, 235, 59, on ? 0.9 : 0.15));
      canvas.drawCircle(Offset(dx + 2, mY + mH - 2), 1.5, Paint()..color = Color.fromRGBO(255, 235, 59, on ? 0.15 : 0.9));
      lightIdx++;
    }
    // Screen glow inside (warm light from entrance)
    canvas.drawRect(Rect.fromLTWH(bx + bw * 0.2, mY + mH + 4, bw * 0.6, bh * 0.2), Paint()..color = const Color(0x2090CAF9));
    _drawDoor(canvas, bx + bw / 2, gY, bw);
    _drawLabel(canvas, bx - 2, mY + 5, bw + 4, 'CINEMA', Colors.white, 5);
  }

  void _drawHospital(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b) {
    // White clinical building
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(2)),
      Paint()..color = const Color(0xFFEEEEEE));
    // Flat roof
    canvas.drawRect(Rect.fromLTWH(bx - 1, by - 2, bw + 2, 4), Paint()..color = const Color(0xFFBDBDBD));
    // Red cross on top
    final crossX = bx + bw / 2;
    final crossY = by + bh * 0.15;
    canvas.drawRect(Rect.fromLTWH(crossX - 5, crossY - 2, 10, 4), Paint()..color = const Color(0xFFD32F2F));
    canvas.drawRect(Rect.fromLTWH(crossX - 2, crossY - 5, 4, 10), Paint()..color = const Color(0xFFD32F2F));
    _drawWindows(canvas, bx, by + bh * 0.3, bw, bh * 0.4, b.tier, gY);
    // Emergency door (wider, red trim)
    final doorW = bw * 0.3;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx + (bw - doorW) / 2, gY - bh * 0.25, doorW, bh * 0.25), const Radius.circular(2)), Paint()..color = const Color(0xFFD32F2F).withAlpha(180));
    _drawLabel(canvas, bx, by + bh * 0.05, bw, 'ER', const Color(0xFFD32F2F), 7);
  }

  void _drawStadium(Canvas canvas, double bx, double by, double bw, double bh, double gY, OwnedBuilding b) {
    final wide = bw * 1.3;
    final wx = bx - (wide - bw) / 2;
    // Bowl/arc shape
    final bowlPath = Path()
      ..moveTo(wx, gY)
      ..lineTo(wx, by + bh * 0.3)
      ..quadraticBezierTo(wx + wide / 2, by, wx + wide, by + bh * 0.3)
      ..lineTo(wx + wide, gY)
      ..close();
    canvas.drawPath(bowlPath, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [b.color.withAlpha(220), b.color]).createShader(Rect.fromLTWH(wx, by, wide, bh)));
    // Inner wall shadow
    canvas.drawPath(Path()..moveTo(wx + 4, gY)..lineTo(wx + 4, by + bh * 0.35)..quadraticBezierTo(wx + wide / 2, by + bh * 0.1, wx + wide - 4, by + bh * 0.35)..lineTo(wx + wide - 4, gY)..close(), Paint()..color = Colors.black.withAlpha(20));
    // Green field
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx + wide * 0.15, by + bh * 0.35, wide * 0.7, bh * 0.2), const Radius.circular(2)), Paint()..color = const Color(0xFF2E7D32));
    // Field lines
    canvas.drawLine(Offset(wx + wide * 0.5, by + bh * 0.35), Offset(wx + wide * 0.5, by + bh * 0.55), Paint()..color = Colors.white.withAlpha(40)..strokeWidth = 0.5);
    canvas.drawCircle(Offset(wx + wide * 0.5, by + bh * 0.45), 5, Paint()..color = Colors.white.withAlpha(30)..style = PaintingStyle.stroke..strokeWidth = 0.5);
    // Crowd dots (tiny colored dots on the stands)
    final rng = Random(77);
    for (int c = 0; c < 15; c++) {
      final cdx = wx + wide * 0.1 + rng.nextDouble() * wide * 0.8;
      final cdy = by + bh * 0.15 + rng.nextDouble() * bh * 0.2;
      canvas.drawCircle(Offset(cdx, cdy), 1, Paint()..color = [const Color(0xFFE53935), const Color(0xFF42A5F5), const Color(0xFFFFEB3B), Colors.white][rng.nextInt(4)].withAlpha(50));
    }
    // Floodlight towers with glow
    for (final fx in [wx + 2.0, wx + wide - 4.0]) {
      canvas.drawRect(Rect.fromLTWH(fx, by - 8, 2, bh * 0.35 + 8), Paint()..color = const Color(0xFF616161));
      // Light head
      canvas.drawRect(Rect.fromLTWH(fx - 1, by - 10, 4, 3), Paint()..color = const Color(0xFF9E9E9E));
      // Animated glow
      final glowAlpha = (30 + sin(DateTime.now().millisecondsSinceEpoch / 500.0 + fx) * 10).toInt();
      canvas.drawCircle(Offset(fx + 1, by - 8), 8, Paint()..color = Color.fromRGBO(255, 255, 200, glowAlpha / 255));
    }
    _drawLabel(canvas, wx, by + bh * 0.6, wide, 'STADIUM', Colors.white, 5);
  }

  // ─── SHARED DRAWING HELPERS ─────────────────────────────────

  void _drawWindows(Canvas canvas, double x, double y, double w, double h, int level, double gY) {
    final rng = Random(x.toInt() + y.toInt());
    final rows = level.clamp(1, 5);
    final cols = level >= 3 ? 3 : 2;
    final winW = w / (cols * 2.2 + 1);
    final winH = h / (rows * 2.2 + 1);
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final isLit = rng.nextDouble() > 0.3;
        final wx = x + winW * 0.6 + col * winW * 2.1;
        final wy = y + winH * 0.5 + row * winH * 2.0;
        if (wy + winH > gY - 8) continue;
        final color = isLit ? const Color(0xCCFFF9C4) : const Color(0x33445566);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx, wy, winW, winH * 0.7), const Radius.circular(1)), Paint()..color = color);
      }
    }
  }

  void _drawDoor(Canvas canvas, double cx, double gY, double bw) {
    final dw = bw * 0.2; final dh = min(bw * 0.25, 16.0);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - dw / 2, gY - dh, dw, dh), const Radius.circular(2)), Paint()..color = const Color(0xFF4E342E));
  }

  void _drawLabel(Canvas canvas, double x, double y, double w, String text, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: 1)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x + (w - tp.width) / 2, y));
  }

  void _drawCrane(Canvas canvas, Size size, double cx, double groundY, double bw, double bh, double progress) {
    final cranePaint = Paint()..color = const Color(0xFFFF9800)..strokeWidth = 3..strokeCap = StrokeCap.round;
    final cablePaint = Paint()..color = Colors.grey.shade600..strokeWidth = 1.5;

    // Crane mast (vertical pole on the right side)
    final mastX = cx + bw * 0.6;
    final mastTop = groundY - size.height * 0.45;
    final mastBottom = groundY;

    // Only show during crane animation (progress 0 to ~0.5)
    final craneAlpha = (1.0 - (progress - 0.6) / 0.4).clamp(0.0, 1.0);
    if (craneAlpha <= 0) return;

    cranePaint.color = const Color(0xFFFF9800).withAlpha((craneAlpha * 255).toInt());
    cablePaint.color = Colors.grey.shade600.withAlpha((craneAlpha * 200).toInt());

    // Mast
    canvas.drawLine(Offset(mastX, mastBottom), Offset(mastX, mastTop), cranePaint);

    // Arm (horizontal)
    final armLeft = cx - bw * 0.4;
    canvas.drawLine(Offset(armLeft, mastTop), Offset(mastX + 10, mastTop), cranePaint);

    // Cable down to building position
    final cableEnd = groundY - bh * progress.clamp(0, 0.8);
    canvas.drawLine(Offset(cx, mastTop), Offset(cx, cableEnd), cablePaint);

    // Hook
    canvas.drawCircle(Offset(cx, cableEnd), 3, Paint()..color = Colors.grey.shade400.withAlpha((craneAlpha * 255).toInt()));
  }

  void _drawGoldenCoin(Canvas canvas, Size size) {
    if (goldenCoin == null || goldenCoin!.collected) return;
    final gc = goldenCoin!;

    final bobY = sin(gc.bobPhase) * 8;
    final pos = Offset(gc.pos.dx, gc.pos.dy + bobY);
    final glowSize = 30 + sin(gc.glowPhase) * 8;

    // Fade out in last 2 seconds
    final alpha = gc.life > 2.0 ? 1.0 : (gc.life / 2.0).clamp(0.0, 1.0);

    // Outer glow
    canvas.drawCircle(pos, glowSize, Paint()..color = Color.fromRGBO(255, 215, 0, 0.3 * alpha));
    canvas.drawCircle(pos, glowSize * 0.7, Paint()..color = Color.fromRGBO(255, 215, 0, 0.5 * alpha));

    // Coin body
    canvas.drawCircle(pos, 18, Paint()..color = Color.fromRGBO(255, 215, 0, alpha));
    canvas.drawCircle(pos, 14, Paint()..color = Color.fromRGBO(255, 235, 59, alpha));

    // $ symbol
    final tp = TextPainter(
      text: TextSpan(text: '\$', style: TextStyle(color: Color.fromRGBO(183, 130, 0, alpha), fontSize: 18, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));

    // Sparkle particles around coin
    final rng = Random(42);
    for (int i = 0; i < 4; i++) {
      final angle = gc.glowPhase + i * pi / 2;
      final dist = 22 + sin(gc.glowPhase * 2 + i) * 5;
      final sx = pos.dx + cos(angle) * dist;
      final sy = pos.dy + sin(angle) * dist;
      canvas.drawCircle(Offset(sx, sy), 2, Paint()..color = Color.fromRGBO(255, 255, 255, 0.7 * alpha));
    }
  }

  void _drawTapGlows(Canvas canvas) {
    for (final g in tapGlows) {
      final a = (g.life * 100).clamp(0, 255).toInt();
      final radius = 25 * (1 - g.life) + 10;
      canvas.drawCircle(g.pos, radius, Paint()..color = g.color.withAlpha(a));
      canvas.drawCircle(g.pos, radius * 0.6, Paint()..color = Colors.white.withAlpha(a ~/ 2));
    }
  }

  void _drawComboRings(Canvas canvas) {
    for (final cr in comboRings) {
      final progress = 1.0 - cr.life;
      final radius = 15 + progress * 35;
      final a = (cr.life * 200).clamp(0, 255).toInt();

      // Ring
      canvas.drawCircle(cr.pos, radius, Paint()
        ..color = cr.color.withAlpha(a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * cr.life);

      // Combo number inside
      if (cr.life > 0.4) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${cr.comboNum}x',
            style: TextStyle(
              color: cr.color.withAlpha(a),
              fontSize: 14 + progress * 4,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black.withAlpha(a ~/ 2), blurRadius: 4)],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(cr.pos.dx - tp.width / 2, cr.pos.dy - tp.height / 2));
      }
    }
  }

  void _drawRings(Canvas canvas) {
    for (final r in rings) {
      canvas.drawCircle(r.pos, r.radius, Paint()..color = r.color.withAlpha((r.opacity * 180).toInt())..style = PaintingStyle.stroke..strokeWidth = 3 * r.opacity);
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      canvas.drawCircle(p.pos, p.size * p.life, Paint()..color = p.color.withAlpha((p.life * 255).clamp(0, 255).toInt()));
    }
  }

  void _drawTapHint(Canvas canvas, Size size) {
    if (buildings.isNotEmpty || totalEarned > 20) return;
    final tp = TextPainter(
      text: const TextSpan(text: 'TAP TO EARN!', style: TextStyle(color: Colors.white60, fontSize: 24, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.38));
  }

  void _drawGroundRipples(Canvas canvas, Size size, double gY) {
    for (final gr in groundRipples) {
      final a = (gr.life * 120).clamp(0, 255).toInt();
      final spread = (1 - gr.life) * 60;
      final p = Paint()..color = Colors.white.withAlpha(a)..style = PaintingStyle.stroke..strokeWidth = 2 * gr.life;
      // Horizontal arc on the ground
      canvas.drawArc(Rect.fromCenter(center: Offset(gr.x, gY + 2), width: spread * 2, height: 12), 0, pi, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CityPainter old) => true;
}

// Edge glow vignette painter
class _EdgeGlowPainter extends CustomPainter {
  final double intensity;
  final Color color;
  _EdgeGlowPainter(this.intensity, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final a = (intensity * 80).clamp(0, 255).toInt();
    // Top edge
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.08),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withAlpha(a), Colors.transparent]).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.08)));
    // Bottom edge
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.92, size.width, size.height * 0.08),
      Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [color.withAlpha(a), Colors.transparent]).createShader(Rect.fromLTWH(0, size.height * 0.92, size.width, size.height * 0.08)));
    // Left edge
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.05, size.height),
      Paint()..shader = LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [color.withAlpha(a ~/ 2), Colors.transparent]).createShader(Rect.fromLTWH(0, 0, size.width * 0.05, size.height)));
    // Right edge
    canvas.drawRect(Rect.fromLTWH(size.width * 0.95, 0, size.width * 0.05, size.height),
      Paint()..shader = LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [color.withAlpha(a ~/ 2), Colors.transparent]).createShader(Rect.fromLTWH(size.width * 0.95, 0, size.width * 0.05, size.height)));
  }

  @override
  bool shouldRepaint(covariant _EdgeGlowPainter old) => old.intensity != intensity || old.color != color;
}

// ─── UTILS ───────────────────────────────────────────────────

const _suffixes = ['', 'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc'];

String _fmt(double n) {
  if (n < 0) return '-${_fmt(-n)}';
  if (n < 100) return n.toStringAsFixed(1);
  if (n < 1000) return n.toStringAsFixed(0);

  // Standard suffixes up to Decillion (10^33)
  int tier = 0;
  double val = n;
  while (val >= 1000 && tier < _suffixes.length - 1) {
    val /= 1000;
    tier++;
  }

  if (tier < _suffixes.length) {
    return '${val.toStringAsFixed(val >= 100 ? 0 : 1)}${_suffixes[tier]}';
  }

  // Beyond Decillion: aa, ab, ac... az, ba, bb... notation
  int extra = tier - _suffixes.length;
  final first = String.fromCharCode(97 + (extra ~/ 26)); // a-z
  final second = String.fromCharCode(97 + (extra % 26));  // a-z
  return '${val.toStringAsFixed(val >= 100 ? 0 : 1)}$first$second';
}

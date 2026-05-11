// lib/services/prayer_audio_manager.dart
// ignore_for_file: avoid_print

import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/foundation.dart';
import 'package:pray_on/services/settings_service.dart';

class AdhanService extends ChangeNotifier {
  AdhanService._();

  static final AdhanService instance = AdhanService._();
  final SettingsService _settings = SettingsService.instance;

  // ---------------------------------------------------------------------------
  // Audio Player
  // ---------------------------------------------------------------------------
  final AudioPlayer _player = AudioPlayer(
    handleInterruptions: true,
    androidApplyAudioAttributes: true,
    handleAudioSessionActivation: true,
  );

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _currentSound;
  String? _currentPrayer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _interruptionSub; // 👈 New: Handle audio interruptions

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get isIdle => !_isPlaying && !_isPaused;
  String? get currentSound => _currentSound;
  String? get currentPrayer => _currentPrayer;
  Duration get position => _position;
  Duration get duration => _duration;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  Future<void> initialize() async {
    if (_initialized) return;

    // 🎧 Audio session configuration
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.alarm,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: true,
      ),
    );

    // 🎵 Position updates
    _positionSub = _player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // ⏱️ Duration updates
    _durationSub = _player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    // ▶️ Playback state updates + notification sync
    _playerStateSub = _player.playerStateStream.listen((state) {
      final playing = state.playing;
      _isPlaying = playing;
      _isPaused =
          !playing && state.processingState != ProcessingState.completed;

      if (state.processingState == ProcessingState.completed) {
        _resetState();
      }
      notifyListeners();
    });

    // 🔔 Handle audio interruptions (calls, other apps)
    _interruptionSub = session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (event.type == AudioInterruptionType.duck) {
          _player.setVolume(0.3); // Lower volume during interruption
        } else {
          pause(); // Pause for phone calls, etc.
        }
      } else {
        _player.setVolume(1.0); // Restore volume
      }
    });

    _initialized = true;
    print('🎧 AdhanService initialized with foreground support');
  }

  // ---------------------------------------------------------------------------
  // Main Playback - Now with MediaItem for notifications
  // ---------------------------------------------------------------------------
  Future<void> playPrayerAdhan({String? prayerName}) async {
    try {
      await initialize();

      if (!_settings.soundEnabled) {
        print('🔇 Sound disabled in settings');
        return;
      }

      // Stop any current playback
      if (_isPlaying || _isPaused) {
        await stop();
      }

      final path = _resolveSoundPath();
      final soundName = _settings.notificationSound;

      print('🎵 Playing Adhan: $soundName');

      // 🏷️ Create MediaItem for notification/lockscreen display
      final mediaItem = MediaItem(
        id: 'adhan_$soundName',
        title: 'Adhan - $soundName',
        album: prayerName ?? 'Prayer Time',
        artist: 'Islamic Audio',
        duration: Duration.zero, // Will be updated when loaded
      );

      // 🎵 Load audio source WITH MediaItem tag
      await _player.setAudioSource(
      AudioSource.asset(
        path,
        tag: mediaItem,
      ),
        preload: true,
      );

      // Update current state
      _currentSound = soundName;
      _currentPrayer = prayerName;

      // ▶️ Start playback
      await _player.play();
      notifyListeners();
    } catch (e, stack) {
      print('❌ Failed to play Adhan: $e');
      if (kDebugMode) print(stack);
    }
  }

  // ---------------------------------------------------------------------------
  // Playback Controls
  // ---------------------------------------------------------------------------
  Future<void> pause() async {
    try {
      await _player.pause();
      _isPaused = true;
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      print('❌ Pause failed: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _player.play();
      _isPaused = false;
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      print('❌ Resume failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      _resetState();
      notifyListeners();
      print('🛑 Adhan stopped');
    } catch (e) {
      print('❌ Stop failed: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('❌ Seek failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------
  void _resetState() {
    _isPlaying = false;
    _isPaused = false;
    _position = Duration.zero;
    _currentPrayer = null;
    _currentSound = null;
  }

  String _resolveSoundPath() {
    final sound = _settings.notificationSound;
    switch (sound) {
      case "Alaqsa":
        return "assets/audio/Alaqsa.mp3";
      case "Egypt":
        return "assets/audio/Egypt.mp3";
      case "Madinah":
        return "assets/audio/Madinah.mp3";
      case "Makkah":
        return "assets/audio/Makkah.mp3";
      case "Minshawi":
        return "assets/audio/Minshawi.mp3";
      default:
        return "assets/audio/Minshawi.mp3";
    }
  }

  // ---------------------------------------------------------------------------
  // Disposal
  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _interruptionSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

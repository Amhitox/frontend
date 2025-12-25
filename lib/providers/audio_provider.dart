import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _currentUrl;
  String? _error;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get duration => _duration;
  Duration get position => _position;
  String? get currentUrl => _currentUrl;
  String? get error => _error;

  AudioProvider() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      _position = Duration.zero;
      // Clear current URL so next play() will restart from beginning
      _currentUrl = null;
      notifyListeners();
    });
  }

  Future<void> play(String url) async {
    try {
      _error = null;
      if (_currentUrl != url) {
        _isLoading = true;
        notifyListeners();
        
        await _audioPlayer.play(UrlSource(url));
        _currentUrl = url;
        
        _isLoading = false;
      } else {
        await _audioPlayer.resume();
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to play audio: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

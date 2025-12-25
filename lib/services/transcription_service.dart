import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TranscriptionService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _amplitudeTimer;
  bool _isRecording = false;
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  // Configuration for VAD
  // Increased threshold to capture silence even with background noise
  static const double silenceThresholdDb = -40.0; 
  static const Duration silenceDuration = Duration(milliseconds: 600);
  DateTime? _lastSpeechTime;
  Function()? _onSilenceDetected;

  Stream<double> get amplitudeStream => _amplitudeController.stream;

  Future<void> startRecording({Function()? onSilenceDetected}) async {
    // Check permissions
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/command_${DateTime.now().millisecondsSinceEpoch}.m4a';

    // Config: encoder AAC LC, bit rate 128k, float 44100
    // These are standard for m4a.
    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
      noiseSuppress: true,
      echoCancel: true,
      autoGain: true,
    );

    await _audioRecorder.start(config, path: path);
    _isRecording = true;
    _onSilenceDetected = onSilenceDetected;
    _lastSpeechTime = DateTime.now().add(const Duration(seconds: 1)); // Grace period
    
    _startAmplitudeMonitoring();
  }

  Future<String?> stopRecording() async {
    _isRecording = false;
    _amplitudeTimer?.cancel();
    if (await _audioRecorder.isRecording()) {
       final path = await _audioRecorder.stop();
       return path;
    }
    return null;
  }

  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording) return;
      
      final amplitude = await _audioRecorder.getAmplitude();
      final currentDb = amplitude.current;
      _amplitudeController.add(currentDb);
      
      // print('🎙️ Amp: $currentDb dB'); // Uncomment for debugging

      if (currentDb > silenceThresholdDb) {
        _lastSpeechTime = DateTime.now();
      } else {
        // If silence duration exceeded
        if (_lastSpeechTime != null && 
            DateTime.now().difference(_lastSpeechTime!) > silenceDuration) {
          
          print('🔇 Silence detected (Amplitude: $currentDb dB below $silenceThresholdDb)');
          _onSilenceDetected?.call();
          
          // Reset to null to prevent continuous triggering
          _lastSpeechTime = null; 
        }
      }
    });
  }
  
  void dispose() {
    _amplitudeTimer?.cancel();
    _amplitudeController.close();
    _audioRecorder.dispose();
  }

  Future<String?> transcribe(String filePath) async {
    try {
      if (!File(filePath).existsSync()) {
        print('❌ File does not exist at $filePath');
        return null;
      }

      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'your_openai_api_key_here') {
        print('❌ OpenAI API Key not configured correctly in .env');
        return null;
      }

      final dio = Dio();
      
      // OpenAI Transcriptions endpoint
      const String url = 'https://api.openai.com/v1/audio/transcriptions';
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'audio.m4a'),
        'model': 'whisper-1',
        'response_format': 'json',
      });

      print('📤 Sending audio to OpenAI transcription service...');
      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      print('✅ OpenAI Response: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> && response.data['text'] != null) {
          return response.data['text'];
        }
      } else {
        print('❌ OpenAI Error: ${response.statusCode} - ${response.data}');
      }
      return null;
    } catch (e) {
      print('❌ Transcription error: $e');
      return null;
    }
  }
}

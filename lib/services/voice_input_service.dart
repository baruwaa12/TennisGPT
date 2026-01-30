import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// VoiceInputService provides speech-to-text functionality across the app.
class VoiceInputService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastWords = '';
  String _error = '';
  double _soundLevel = 0.0;
  
  // Getters
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String get error => _error;
  double get soundLevel => _soundLevel;
  
  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) {
          if (kDebugMode) {
            print('VoiceInputService: Error - ${error.errorMsg}');
          }
          _error = error.errorMsg;
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          if (kDebugMode) {
            print('VoiceInputService: Status - $status');
          }
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );
      
      if (kDebugMode) {
        print('VoiceInputService: Initialized - available=$_isAvailable');
      }
      
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      if (kDebugMode) {
        print('VoiceInputService: Failed to initialize - $e');
      }
      _error = 'Speech recognition not available';
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Start listening for voice input
  /// Returns a stream of recognized words
  Future<void> startListening({
    required Function(String) onResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        _error = 'Speech recognition not available';
        notifyListeners();
        return;
      }
    }
    
    _error = '';
    _lastWords = '';
    _isListening = true;
    notifyListeners();
    
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastWords = result.recognizedWords;
          onResult(_lastWords);
          notifyListeners();
          
          if (kDebugMode) {
            print('VoiceInputService: Recognized - $_lastWords (final=${result.finalResult})');
          }
        },
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        partialResults: true,
        onSoundLevelChange: (level) {
          _soundLevel = level;
          notifyListeners();
        },
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      if (kDebugMode) {
        print('VoiceInputService: Error starting - $e');
      }
      _error = 'Failed to start listening';
      _isListening = false;
      notifyListeners();
    }
  }
  
  /// Stop listening
  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    _soundLevel = 0.0;
    notifyListeners();
  }
  
  /// Cancel listening
  Future<void> cancelListening() async {
    await _speech.cancel();
    _isListening = false;
    _soundLevel = 0.0;
    _lastWords = '';
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
  
  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}


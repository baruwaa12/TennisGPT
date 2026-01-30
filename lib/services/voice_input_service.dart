import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// VoiceInputService provides speech-to-text functionality across the app.
/// 
/// Accuracy improvements over basic implementation:
/// - Uses device locale for correct language recognition
/// - Only commits FINAL results (not partial/interim results) to the text field
/// - Shows partial results for live preview but doesn't commit until final
/// - Increased pause tolerance for natural speech patterns
/// - Uses confirmation listening mode for better accuracy on Android
class VoiceInputService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  
  bool _isAvailable = false;
  bool _isListening = false;
  String _finalWords = '';       // Only final confirmed results
  String _partialWords = '';     // Live preview (may be inaccurate)
  String _error = '';
  double _soundLevel = 0.0;
  String? _selectedLocaleId;
  List<LocaleName> _availableLocales = [];
  
  // Getters
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _finalWords;         // Returns FINAL words only
  String get partialWords => _partialWords;    // For live preview display
  String get error => _error;
  double get soundLevel => _soundLevel;
  List<LocaleName> get availableLocales => _availableLocales;
  String? get selectedLocaleId => _selectedLocaleId;
  
  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isAvailable) return true; // Already initialized
    
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) {
          if (kDebugMode) {
            print('VoiceInputService: Error - ${error.errorMsg}');
          }
          _error = _humanizeError(error.errorMsg);
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
        debugLogging: kDebugMode,
      );
      
      if (_isAvailable) {
        // Get available locales and select the best one
        _availableLocales = await _speech.locales();
        _selectedLocaleId = await _selectBestLocale();
        
        if (kDebugMode) {
          print('VoiceInputService: Initialized - available=$_isAvailable');
          print('VoiceInputService: Available locales: ${_availableLocales.length}');
          print('VoiceInputService: Selected locale: $_selectedLocaleId');
        }
      }
      
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      if (kDebugMode) {
        print('VoiceInputService: Failed to initialize - $e');
      }
      _error = 'Speech recognition not available on this device';
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Select the best locale for recognition
  /// Prefers the device's system locale, falls back to en-US
  Future<String?> _selectBestLocale() async {
    if (_availableLocales.isEmpty) return null;
    
    // Try to get device locale
    String deviceLocale;
    try {
      deviceLocale = Platform.localeName.replaceAll('_', '-');
    } catch (_) {
      deviceLocale = 'en-US';
    }
    
    if (kDebugMode) {
      print('VoiceInputService: Device locale: $deviceLocale');
    }
    
    // First try exact match
    for (var locale in _availableLocales) {
      if (locale.localeId == deviceLocale) {
        return locale.localeId;
      }
    }
    
    // Try language-only match (e.g., "en" matches "en-US")
    final deviceLang = deviceLocale.split('-').first.toLowerCase();
    for (var locale in _availableLocales) {
      if (locale.localeId.toLowerCase().startsWith(deviceLang)) {
        return locale.localeId;
      }
    }
    
    // Fall back to English variants (common for tennis terminology)
    final englishLocales = ['en-US', 'en-GB', 'en-AU', 'en_US', 'en_GB'];
    for (var enLocale in englishLocales) {
      for (var locale in _availableLocales) {
        if (locale.localeId == enLocale) {
          return locale.localeId;
        }
      }
    }
    
    // Last resort: use first available
    return _availableLocales.first.localeId;
  }
  
  /// Convert error messages to user-friendly text
  String _humanizeError(String errorMsg) {
    final lowerError = errorMsg.toLowerCase();
    if (lowerError.contains('no_match') || lowerError.contains('nomatch')) {
      return 'Could not understand. Please speak more clearly.';
    } else if (lowerError.contains('audio')) {
      return 'Audio error. Please check microphone access.';
    } else if (lowerError.contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (lowerError.contains('permission')) {
      return 'Microphone permission denied.';
    } else if (lowerError.contains('busy')) {
      return 'Speech recognition is busy. Please try again.';
    } else if (lowerError.contains('not_available') || lowerError.contains('unavailable')) {
      return 'Speech recognition not available on this device.';
    }
    return 'Voice input error. Please try again.';
  }
  
  /// Start listening for voice input
  /// 
  /// [onResult] - Called with the FINAL recognized text only
  /// [onPartialResult] - Optional: Called with partial (live) results for preview
  /// [listenFor] - Maximum duration to listen
  /// [pauseFor] - How long to wait for speech before stopping
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
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
    _finalWords = '';
    _partialWords = '';
    _isListening = true;
    notifyListeners();
    
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (kDebugMode) {
            print('VoiceInputService: "${result.recognizedWords}" (final=${result.finalResult}, confidence=${result.confidence})');
          }
          
          if (result.finalResult) {
            // FINAL result - this is the accurate, confirmed text
            _finalWords = result.recognizedWords;
            _partialWords = '';
            
            // Only call onResult with final, confirmed text
            if (_finalWords.isNotEmpty) {
              onResult(_finalWords);
            }
          } else {
            // Partial result - show for preview but don't commit
            _partialWords = result.recognizedWords;
            onPartialResult?.call(_partialWords);
          }
          
          notifyListeners();
        },
        // Use the detected locale for better accuracy
        localeId: _selectedLocaleId,
        // Longer listen time for detailed descriptions
        listenFor: listenFor ?? const Duration(seconds: 60),
        // Longer pause tolerance for thinking/natural speech
        pauseFor: pauseFor ?? const Duration(seconds: 4),
        // IMPORTANT: Set to false to only get final, accurate results
        // Setting to true gives live feedback but less accurate interim text
        partialResults: onPartialResult != null,
        onSoundLevelChange: (level) {
          _soundLevel = level;
          // Don't notify for every sound level change - too many rebuilds
        },
        // Use confirmation mode for better accuracy (waits for confirmation)
        // dictation mode is faster but less accurate
        listenMode: ListenMode.confirmation,
        // Cancel any ongoing listening before starting new
        cancelOnError: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('VoiceInputService: Error starting - $e');
      }
      _error = 'Failed to start voice input. Please try again.';
      _isListening = false;
      notifyListeners();
    }
  }
  
  /// Stop listening and get the final result
  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    _soundLevel = 0.0;
    _partialWords = '';
    notifyListeners();
  }
  
  /// Cancel listening without getting results
  Future<void> cancelListening() async {
    await _speech.cancel();
    _isListening = false;
    _soundLevel = 0.0;
    _finalWords = '';
    _partialWords = '';
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
  
  /// Manually set a locale (for user preference)
  void setLocale(String localeId) {
    if (_availableLocales.any((l) => l.localeId == localeId)) {
      _selectedLocaleId = localeId;
      notifyListeners();
      
      if (kDebugMode) {
        print('VoiceInputService: Locale manually set to $localeId');
      }
    }
  }
  
  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}

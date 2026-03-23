import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/voice_input_service.dart';
import '../theme/app_theme.dart';

/// A microphone button that enables voice input for text fields.
/// 
/// Uses improved speech recognition with:
/// - Proper locale detection for accuracy
/// - Only commits FINAL results (not partial/interim)
/// - User-friendly error messages
/// 
/// Usage:
/// ```dart
/// Row(
///   children: [
///     Expanded(child: TextField(controller: _controller)),
///     VoiceInputButton(
///       onResult: (text) => _controller.text = text,
///     ),
///   ],
/// )
/// ```
class VoiceInputButton extends StatefulWidget {
  /// Called when voice recognition produces FINAL results
  final Function(String) onResult;
  
  /// Optional: Called when listening state changes
  final Function(bool)? onListeningChanged;
  
  /// Button size (default: 40)
  final double size;
  
  /// Icon color when not listening
  final Color? iconColor;
  
  /// Icon color when listening
  final Color? activeColor;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.onListeningChanged,
    this.size = 40,
    this.iconColor,
    this.activeColor,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();
  late AnimationController _pulseController;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _voiceService.addListener(_onVoiceStateChanged);
  }
  
  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceStateChanged);
    _voiceService.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  void _onVoiceStateChanged() {
    if (mounted) {
      // Check for errors
      if (_voiceService.error.isNotEmpty && !_hasError) {
        _hasError = true;
        _showError(_voiceService.error);
        _voiceService.clearError();
      } else if (_voiceService.error.isEmpty) {
        _hasError = false;
      }
      
      setState(() {});
      widget.onListeningChanged?.call(_voiceService.isListening);
    }
  }
  
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mic_off, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _toggleListening,
        ),
      ),
    );
  }
  
  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();
    
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
    } else {
      // Initialize on first tap — this is when the OS permission prompt appears
      if (!_voiceService.isAvailable) {
        final initialized = await _voiceService.initialize();
        if (!initialized) {
          _showPermissionDeniedDialog();
          return;
        }
      }
      
      await _voiceService.startListening(
        onResult: (recognizedText) {
          if (recognizedText.isNotEmpty) {
            HapticFeedback.lightImpact();
            widget.onResult(recognizedText);
          }
        },
      );
    }
  }
  
  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Access Required'),
        content: const Text(
          'Composure needs microphone and speech recognition access to use voice input.\n\n'
          'Please enable both in Settings > Composure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              launchUrl(Uri.parse('app-settings:'));
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _voiceService.isListening;
    final defaultColor = widget.iconColor ?? AppTheme.textMutedColor(context);
    final activeColorValue = widget.activeColor ?? AppTheme.primary;
    
    return GestureDetector(
      onTap: _toggleListening,
      onLongPress: () {
        // Long press to show available locales (for debugging)
        if (_voiceService.availableLocales.isNotEmpty) {
          HapticFeedback.heavyImpact();
          _showLocaleInfo();
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: isListening 
                  ? activeColorValue.withOpacity(0.1 + (_pulseController.value * 0.1))
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isListening ? activeColorValue : AppTheme.borderColor(context),
                width: isListening ? 2 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring when listening
                if (isListening)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        width: widget.size * (0.8 + (_pulseController.value * 0.3)),
                        height: widget.size * (0.8 + (_pulseController.value * 0.3)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activeColorValue.withOpacity(0.3 - (_pulseController.value * 0.2)),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                
                // Microphone icon
                Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  size: widget.size * 0.5,
                  color: isListening ? activeColorValue : defaultColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _showLocaleInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Recognition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current locale: ${_voiceService.selectedLocaleId ?? "Not set"}'),
            const SizedBox(height: 8),
            Text('Available: ${_voiceService.availableLocales.length} locales'),
            const SizedBox(height: 16),
            const Text(
              'Tips for better accuracy:\n'
              '• Speak clearly and at normal pace\n'
              '• Reduce background noise\n'
              '• Wait for the mic to stop pulsing\n'
              '• Use short, complete sentences',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// A text field with integrated voice input button.
/// 
/// Only commits FINAL speech recognition results to the text field.
/// 
/// Usage:
/// ```dart
/// VoiceTextField(
///   controller: _controller,
///   hintText: 'Enter your message...',
/// )
/// ```
class VoiceTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final bool enabled;
  final InputDecoration? decoration;
  final TextStyle? style;
  final Function(String)? onChanged;
  
  const VoiceTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLines = 3,
    this.enabled = true,
    this.decoration,
    this.style,
    this.onChanged,
  });

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  bool _isListening = false;
  String _textBeforeVoice = '';
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: _isListening ? AppTheme.primary : AppTheme.borderColor(context),
          width: _isListening ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.enabled && !_isListening,
                  maxLines: widget.maxLines,
                  style: widget.style ?? AppTheme.bodyMediumThemed(context),
                  onChanged: widget.onChanged,
                  decoration: widget.decoration ?? InputDecoration(
                    hintText: _isListening 
                        ? 'Listening... speak now'
                        : (widget.hintText ?? 'Type or tap mic to speak...'),
                    hintStyle: AppTheme.bodySmallThemed(context).copyWith(
                      color: _isListening 
                          ? AppTheme.primary
                          : AppTheme.textMutedColor(context).withOpacity(0.5),
                      fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spaceMD),
                  ),
                ),
              ),
              
              // Voice input button
              Padding(
                padding: const EdgeInsets.only(
                  top: AppTheme.spaceSM,
                  right: AppTheme.spaceSM,
                ),
                child: VoiceInputButton(
                  size: 36,
                  onResult: (text) {
                    // Called only with FINAL results
                    // Append to existing text if there was any before we started
                    if (_textBeforeVoice.isNotEmpty) {
                      widget.controller.text = '$_textBeforeVoice $text';
                    } else {
                      widget.controller.text = text;
                    }
                    widget.onChanged?.call(widget.controller.text);
                  },
                  onListeningChanged: (listening) {
                    if (listening) {
                      // Save current text before listening
                      _textBeforeVoice = widget.controller.text;
                    }
                    setState(() => _isListening = listening);
                  },
                ),
              ),
            ],
          ),
          
          // Listening indicator
          if (_isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceXS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusMD - 1),
                  bottomRight: Radius.circular(AppTheme.radiusMD - 1),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Speak clearly • Tap mic when done',
                    style: AppTheme.bodySmallThemed(context).copyWith(
                      color: AppTheme.primary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

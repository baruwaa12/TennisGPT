import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/voice_input_service.dart';
import '../theme/app_theme.dart';

/// A microphone button that enables voice input for text fields.
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
  /// Called when voice recognition produces results
  final Function(String) onResult;
  
  /// Optional: Called when listening state changes
  final Function(bool)? onListeningChanged;
  
  /// Button size (default: 40)
  final double size;
  
  /// Icon color when not listening
  final Color? iconColor;
  
  /// Icon color when listening
  final Color? activeColor;
  
  /// Whether to append to existing text or replace
  final bool appendMode;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.onListeningChanged,
    this.size = 40,
    this.iconColor,
    this.activeColor,
    this.appendMode = false,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();
  late AnimationController _pulseController;
  String _existingText = '';
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _voiceService.addListener(_onVoiceStateChanged);
    _voiceService.initialize();
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
      setState(() {});
      widget.onListeningChanged?.call(_voiceService.isListening);
    }
  }
  
  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();
    
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
    } else {
      // Store existing text for append mode
      _existingText = '';
      
      await _voiceService.startListening(
        onResult: (recognizedText) {
          if (widget.appendMode && _existingText.isNotEmpty) {
            widget.onResult('$_existingText $recognizedText');
          } else {
            widget.onResult(recognizedText);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _voiceService.isListening;
    final defaultColor = widget.iconColor ?? AppTheme.textMutedColor(context);
    final activeColorValue = widget.activeColor ?? AppTheme.primary;
    
    return GestureDetector(
      onTap: _toggleListening,
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
}

/// A text field with integrated voice input button.
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              style: widget.style ?? AppTheme.bodyMediumThemed(context),
              onChanged: widget.onChanged,
              decoration: widget.decoration ?? InputDecoration(
                hintText: widget.hintText ?? 'Type or speak...',
                hintStyle: AppTheme.bodySmallThemed(context).copyWith(
                  color: AppTheme.textMutedColor(context).withOpacity(0.5),
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
                // Append to existing text if there's content
                final existingText = widget.controller.text;
                if (existingText.isNotEmpty) {
                  widget.controller.text = '$existingText $text';
                } else {
                  widget.controller.text = text;
                }
                widget.onChanged?.call(widget.controller.text);
              },
              onListeningChanged: (listening) {
                setState(() => _isListening = listening);
              },
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/openai_service.dart';
import '../services/storage_service.dart';
import '../models/check_in_entry.dart';
import '../widgets/confetti_overlay.dart';

class MentalCheckInScreen extends StatefulWidget {
  const MentalCheckInScreen({super.key});

  @override
  State<MentalCheckInScreen> createState() => _MentalCheckInScreenState();
}

class _MentalCheckInScreenState extends State<MentalCheckInScreen> {
  final TextEditingController _journalController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  int _currentRating = 3;
  bool _showConfetti = false;
  bool _isLoading = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadLastRating();
  }

  @override
  void dispose() {
    _journalController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLastRating() async {
    final lastRating = await StorageService.getLastRating();
    setState(() {
      _currentRating = lastRating;
    });
  }

  String _getMoodEmoji(int rating) {
    switch (rating) {
      case 1:
        return '😰';
      case 2:
        return '😟';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  String _getTailoredTip(int rating) {
    if (rating <= 2) {
      return "Try this 2-minute breathing drill.";
    } else if (rating >= 4) {
      return "Great mood—set a new practice goal today!";
    } else {
      return "Keep focusing on your form—you're doing well!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      showConfetti: _showConfetti,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🧠 Mental Check-In'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_hasSubmitted) ...[
                // Input Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.psychology,
                          size: 64,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'How are you feeling today?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Mood Slider
                        Column(
                          children: [
                            Text(
                              _getMoodEmoji(_currentRating),
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Stressed', style: TextStyle(fontSize: 12)),
                                const Text('Calm', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            Slider(
                              value: _currentRating.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              activeColor: Colors.blue,
                              onChanged: (value) {
                                setState(() {
                                  _currentRating = value.round();
                                });
                              },
                            ),
                            Text(
                              'Rating: $_currentRating/5',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Journal Text Field
                        const Text(
                          "What's on your mind today?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _journalController,
                          focusNode: _focusNode,
                          maxLines: null,
                          minLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Share your thoughts about your tennis performance, challenges, or anything on your mind...',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading || _journalController.text.trim().isEmpty
                                ? null
                                : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Response Section (after submission)
                Expanded(
                  child: Consumer<OpenAIService>(
                    builder: (context, openAIService, child) {
                      if (openAIService.isLoading) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Your coach is thinking...',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        );
                      }

                      if (openAIService.lastResponse != null) {
                        return Column(
                          children: [
                            // Success Header
                            Card(
                              color: Colors.green[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Check-in Complete!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Coach's Response
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.psychology, color: Colors.blue, size: 32),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Your Coach\'s Response:',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            openAIService.lastResponse!,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              height: 1.6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // New Check-in Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _hasSubmitted = false;
                                    _journalController.clear();
                                    openAIService.clearResponse();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'New Check-in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
              
              // Error Display
              Consumer<OpenAIService>(
                builder: (context, openAIService, child) {
                  if (openAIService.error != null) {
                    return Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error: ${openAIService.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final journalText = _journalController.text.trim();
    
    if (journalText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Hide keyboard
    _focusNode.unfocus();
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Create check-in entry
      final entry = CheckInEntry(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        rating: _currentRating,
        journalText: journalText,
      );

      // Save to local storage
      await StorageService.saveCheckIn(entry);

      // TODO: Analytics event - mental_checkin_submitted
      // analytics.track('mental_checkin_submitted', {
      //   'rating': _currentRating,
      //   'has_journal_text': journalText.isNotEmpty,
      // });

      // Show tailored tip
      final tip = _getTailoredTip(_currentRating);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tip),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Show confetti animation
      setState(() {
        _showConfetti = true;
      });

      // Hide confetti after animation
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _showConfetti = false;
        });
      });

      // Get AI response
      final openAIService = Provider.of<OpenAIService>(context, listen: false);
      await openAIService.mentalCheckIn(journalText);

      // Show response section
      setState(() {
        _hasSubmitted = true;
        _isLoading = false;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Extension method to get check-ins for parent screens
extension MentalCheckInData on MentalCheckInScreen {
  static Future<List<CheckInEntry>> getCheckIns() async {
    return await StorageService.getCheckIns();
  }
} 
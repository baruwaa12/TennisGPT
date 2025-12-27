import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/check_in_entry.dart';

class MentalCheckInScreen extends StatefulWidget {
  const MentalCheckInScreen({super.key});

  @override
  State<MentalCheckInScreen> createState() => _MentalCheckInScreenState();
}

class _MentalCheckInScreenState extends State<MentalCheckInScreen> {
  int _currentRating = 3;
  bool _isLoading = false;
  bool _hasSubmitted = false;
  
  // New State for Chips
  final Set<String> _selectedTags = {};
  
  final List<String> _feelingsTags = [
    'Confident', 'Anxious', 'Focused', 'Distracted', 
    'Tired', 'Energetic', 'Frustrated', 'Calm',
    'Choked', 'In the Zone', 'Angry', 'Motivated'
  ];

  @override
  void initState() {
    super.initState();
    _loadLastRating();
  }

  Future<void> _loadLastRating() async {
    final lastRating = await StorageService.getLastRating();
    setState(() {
      _currentRating = lastRating;
    });
  }

  String _getMoodEmoji(int rating) {
    switch (rating) {
      case 1: return '😰';
      case 2: return '😟';
      case 3: return '😐';
      case 4: return '😊';
      case 5: return '😄';
      default: return '😐';
    }
  }

  void _handleHaptic() {
    HapticFeedback.selectionClick();
  }

  void _handleSuccessHaptic() {
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Check-In'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_hasSubmitted) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mood Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'How are you feeling?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _getMoodEmoji(_currentRating),
                              style: const TextStyle(fontSize: 64),
                            ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 16),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Theme.of(context).colorScheme.primary,
                                thumbColor: Theme.of(context).colorScheme.primary,
                                overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: _currentRating.toDouble(),
                                min: 1,
                                max: 5,
                                divisions: 4,
                                onChanged: (value) {
                                  if (value.round() != _currentRating) {
                                    _handleHaptic();
                                    setState(() {
                                      _currentRating = value.round();
                                    });
                                  }
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Stressed', style: TextStyle(color: Colors.grey[400])),
                                Text('Peaking', style: TextStyle(color: Colors.grey[400])),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      // Tags Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select what describes you',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _feelingsTags.map((tag) {
                                final isSelected = _selectedTags.contains(tag);
                                return FilterChip(
                                  label: Text(tag),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    _handleHaptic();
                                    setState(() {
                                      if (selected) {
                                        _selectedTags.add(tag);
                                      } else {
                                        _selectedTags.remove(tag);
                                      }
                                    });
                                  },
                                  checkmarkColor: Colors.black,
                                  selectedColor: Theme.of(context).colorScheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  backgroundColor: Colors.grey[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected 
                                          ? Theme.of(context).colorScheme.primary 
                                          : Colors.transparent,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedTags.isEmpty
                      ? null
                      : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Log Check-In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ] else ...[
              // Response Section
              Expanded(
                child: Consumer<ApiService>(
                  builder: (context, apiService, child) {
                    if (apiService.isLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 24),
                            Text(
                              'Processing...',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[400],
                              ),
                            ).animate().shimmer(),
                          ],
                        ),
                      );
                    }

                    if (apiService.lastResponse != null) {
                      return Column(
                        children: [
                          // Success Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 12),
                                Text(
                                  'Check-In Logged',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                          
                          const SizedBox(height: 16),
                          
                          // Coach's Response
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.lightbulb_outline, size: 28),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Insight',
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
                                        apiService.lastResponse!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.6,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                          
                          const SizedBox(height: 16),
                          
                          // New Check-in Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _hasSubmitted = false;
                                  _selectedTags.clear();
                                  apiService.clearResponse();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
            Consumer<ApiService>(
              builder: (context, apiService, child) {
                if (apiService.error != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Text(
                        'Error: ${apiService.error}',
                        style: const TextStyle(color: Colors.redAccent),
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
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedTags.isEmpty) return;

    _handleSuccessHaptic();
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Construct journal text from tags
      final journalText = "I am feeling: ${_selectedTags.join(', ')}";

      // Create check-in entry
      final entry = CheckInEntry(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        rating: _currentRating,
        journalText: journalText,
      );

      // Save to local storage
      await StorageService.saveCheckIn(entry);

      // Get AI response
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.mentalCheckIn(_currentRating, journalText);

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
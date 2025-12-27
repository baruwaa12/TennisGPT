import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_performance.dart';
import '../services/match_history_service.dart';
import '../services/api_service.dart';

class AddMatchScreen extends StatefulWidget {
  const AddMatchScreen({super.key});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _result = 'Win';
  int _setsWon = 2;
  int _setsLost = 0;
  String _surface = 'Hard';
  String _weather = 'Sunny';
  
  final Map<String, int> _strengths = {
    'Serve': 7,
    'Forehand': 7,
    'Backhand': 7,
    'Volley': 7,
    'Footwork': 7,
  };
  
  final Map<String, int> _weaknesses = {
    'Serve': 5,
    'Forehand': 5,
    'Backhand': 5,
    'Volley': 5,
    'Footwork': 5,
  };
  
  final List<String> _keyMoments = [];
  final TextEditingController _keyMomentController = TextEditingController();
  
  bool _isSaving = false;
  String? _analysisResponse;

  final List<String> _surfaces = ['Hard', 'Clay', 'Grass', 'Carpet', 'Indoor'];
  final List<String> _weatherConditions = ['Sunny', 'Cloudy', 'Rainy', 'Windy', 'Hot', 'Cold'];

  @override
  void dispose() {
    _opponentController.dispose();
    _notesController.dispose();
    _keyMomentController.dispose();
    super.dispose();
  }

  void _addKeyMoment() {
    if (_keyMomentController.text.trim().isNotEmpty) {
      setState(() {
        _keyMoments.add(_keyMomentController.text.trim());
        _keyMomentController.clear();
      });
    }
  }

  void _removeKeyMoment(int index) {
    setState(() {
      _keyMoments.removeAt(index);
    });
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Generate match ID
      final String matchId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create match description for AI analysis
      final String matchDescription = '''
Opponent: ${_opponentController.text}
Result: $_result (${_setsWon}-${_setsLost})
Surface: $_surface
Weather: $_weather
Strengths: ${_strengths.entries.map((e) => '${e.key}(${e.value}/10)').join(', ')}
Weaknesses: ${_weaknesses.entries.map((e) => '${e.key}(${e.value}/10)').join(', ')}
Key Moments: ${_keyMoments.join('; ')}
Notes: ${_notesController.text}
      '''.trim();

      // Get AI analysis
      final apiService = Provider.of<ApiService>(context, listen: false);
      final recentMatches = await _matchHistoryService.getRecentMatches(3);
      final analysis = await apiService.tacticalAnalysis(matchDescription, recentMatches);
      
      // Generate drill recommendations
      final allMatches = await _matchHistoryService.getAllMatches();
      allMatches.add(MatchPerformance(
        id: matchId,
        date: DateTime.now(),
        opponent: _opponentController.text,
        result: _result,
        setsWon: _setsWon,
        setsLost: _setsLost,
        surface: _surface,
        weather: _weather,
        notes: _notesController.text,
        strengths: Map.from(_strengths),
        weaknesses: Map.from(_weaknesses),
        keyMoments: List.from(_keyMoments),
        tacticalAnalysis: analysis ?? 'Analysis pending',
        recommendedDrills: [],
      ));
      
      final drills = await apiService.generateDrillsFromHistory(allMatches);
      
      // Create final match performance
      final match = MatchPerformance(
        id: matchId,
        date: DateTime.now(),
        opponent: _opponentController.text,
        result: _result,
        setsWon: _setsWon,
        setsLost: _setsLost,
        surface: _surface,
        weather: _weather,
        notes: _notesController.text,
        strengths: Map.from(_strengths),
        weaknesses: Map.from(_weaknesses),
        keyMoments: List.from(_keyMoments),
        tacticalAnalysis: analysis ?? 'Analysis pending',
        recommendedDrills: drills?.split('\n').where((line) => line.trim().isNotEmpty).toList() ?? [],
      );

      await _matchHistoryService.saveMatch(match);

      setState(() {
        _isSaving = false;
        _analysisResponse = analysis;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving match: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      appBar: AppBar(
        title: const Text('📝 Add Match'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Match Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Match Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _opponentController,
                        decoration: const InputDecoration(
                          labelText: 'Opponent Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Please enter opponent name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _result,
                              decoration: const InputDecoration(
                                labelText: 'Result',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Win', child: Text('Win')),
                                DropdownMenuItem(value: 'Loss', child: Text('Loss')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _result = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: _setsWon,
                                    decoration: const InputDecoration(
                                      labelText: 'Sets Won',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: List.generate(4, (index) => 
                                      DropdownMenuItem(value: index, child: Text('$index'))
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _setsWon = value!;
                                      });
                                    },
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('-'),
                                ),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: _setsLost,
                                    decoration: const InputDecoration(
                                      labelText: 'Sets Lost',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: List.generate(4, (index) => 
                                      DropdownMenuItem(value: index, child: Text('$index'))
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _setsLost = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _surface,
                              decoration: const InputDecoration(
                                labelText: 'Surface',
                                border: OutlineInputBorder(),
                              ),
                              items: _surfaces.map((surface) => 
                                DropdownMenuItem(value: surface, child: Text(surface))
                              ).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _surface = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _weather,
                              decoration: const InputDecoration(
                                labelText: 'Weather',
                                border: OutlineInputBorder(),
                              ),
                              items: _weatherConditions.map((weather) => 
                                DropdownMenuItem(value: weather, child: Text(weather))
                              ).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _weather = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Performance Ratings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Ratings (1-10)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._strengths.keys.map((skill) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(skill),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Strengths: ${_strengths[skill]}/10'),
                                  Slider(
                                    value: _strengths[skill]!.toDouble(),
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    label: _strengths[skill].toString(),
                                    onChanged: (value) {
                                      setState(() {
                                        _strengths[skill] = value.round();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Weaknesses: ${_weaknesses[skill]}/10'),
                                  Slider(
                                    value: _weaknesses[skill]!.toDouble(),
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    label: _weaknesses[skill].toString(),
                                    onChanged: (value) {
                                      setState(() {
                                        _weaknesses[skill] = value.round();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Key Moments
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Key Moments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _keyMomentController,
                              decoration: const InputDecoration(
                                hintText: 'Add a key moment...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addKeyMoment,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      if (_keyMoments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ..._keyMoments.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('• ${entry.value}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeKeyMoment(entry.key),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Any additional thoughts about the match...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMatch,
                  icon: _isSaving 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Match'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
} 
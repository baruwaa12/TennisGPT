import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import 'paywall_screen.dart';

class EmotionalResetScreen extends StatefulWidget {
  const EmotionalResetScreen({super.key});

  @override
  State<EmotionalResetScreen> createState() => _EmotionalResetScreenState();
}

class _EmotionalResetScreenState extends State<EmotionalResetScreen> {
  final TextEditingController _customController = TextEditingController();
  String? _selectedTrigger;
  bool _showCustomInput = false;

  // Tactical trigger options based on common match situations
  final List<Map<String, dynamic>> _triggers = [
    {
      'emoji': '😤',
      'title': 'Choked at crunch time',
      'situation': 'I choked at a critical moment in the match when the pressure was high',
    },
    {
      'emoji': '😵',
      'title': 'Lost to weaker player',
      'situation': 'I lost to an opponent I should have beaten - they played below my level',
    },
    {
      'emoji': '🎯',
      'title': 'Too many errors',
      'situation': 'I made too many unforced errors and beat myself',
    },
    {
      'emoji': '😰',
      'title': 'Lost focus completely',
      'situation': 'I lost my concentration and focus during the match',
    },
    {
      'emoji': '😠',
      'title': 'Opponent got to me',
      'situation': 'My opponent\'s behavior or gamesmanship affected my play',
    },
    {
      'emoji': '📉',
      'title': 'My shots broke down',
      'situation': 'My technique fell apart - I couldn\'t hit my usual shots',
    },
  ];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Post-Match Debrief'),
        centerTitle: true,
      ),
      body: Consumer<ApiService>(
        builder: (context, apiService, child) {
          // Show response view if we have a response
          if (apiService.lastResponse != null) {
            return _buildResponseView(context, apiService);
          }

          // Show input view
          return _buildInputView(context, apiService);
        },
      ),
    );
  }

  Widget _buildInputView(BuildContext context, ApiService apiService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.rate_review,
                    size: 48,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'What happened?',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select what best describes your situation for a tactical debrief',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Trigger Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: _triggers.length,
            itemBuilder: (context, index) {
              final trigger = _triggers[index];
              final isSelected = _selectedTrigger == trigger['situation'];
              
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedTrigger = trigger['situation'];
                    _showCustomInput = false;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          trigger['emoji'],
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trigger['title'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Other / Custom option
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showCustomInput = true;
                _selectedTrigger = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _showCustomInput ? Colors.blue.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showCustomInput ? Colors.blue : Colors.grey.shade300,
                  width: _showCustomInput ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: _showCustomInput ? Colors.blue : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Describe something else...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _showCustomInput ? Colors.blue.shade700 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom input field
          if (_showCustomInput) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe what happened in your match...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _selectedTrigger = value.isNotEmpty ? value : null;
                });
              },
            ),
          ],

          const SizedBox(height: 24),

          // Analyze Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_selectedTrigger == null || apiService.isLoading)
                  ? null
                  : () => _handleDebrief(context, apiService),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: apiService.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Get Tactical Debrief 🎯',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          // Error display
          if (apiService.error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${apiService.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildResponseView(BuildContext context, ApiService apiService) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success Header
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Tactical Debrief Complete',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Response Card
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Analysis & Recommendations',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
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
                          style: GoogleFonts.poppins(
                            fontSize: 15,
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
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedTrigger = null;
                      _showCustomInput = false;
                      _customController.clear();
                    });
                    apiService.clearResponse();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Debrief'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.done),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDebrief(
    BuildContext context,
    ApiService apiService,
  ) async {
    if (_selectedTrigger == null) return;

    // Check usage limits (premium users bypass)
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    
    if (!purchaseService.isPremium && !usageService.canUseDebrief) {
      HapticFeedback.mediumImpact();
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(
            trigger: PaywallTrigger.debriefLimit,
          ),
        ),
      );
      
      if (result != true) return;
    }

    HapticFeedback.lightImpact();
    
    final response = await apiService.emotionalReset(_selectedTrigger!);
    
    // Record usage for free users
    if (!purchaseService.isPremium && response != null) {
      await usageService.recordDebrief();
    }
    
    if (response != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Analysis complete',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

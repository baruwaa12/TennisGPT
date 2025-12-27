import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import '../services/player_profile_service.dart';
import '../models/check_in_entry.dart';
import '../utils/tennis_validator.dart';
import 'paywall_screen.dart';

class MentalCheckInScreen extends StatefulWidget {
  const MentalCheckInScreen({super.key});

  @override
  State<MentalCheckInScreen> createState() => _MentalCheckInScreenState();
}

class _MentalCheckInScreenState extends State<MentalCheckInScreen> {
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  int _confidenceLevel = 7;
  String? _selectedGamePlan;
  bool _isLoading = false;
  bool _hasSubmitted = false;
  String? _briefingResponse;

  static const List<Map<String, String>> gamePlanOptions = [
    {'id': 'attack_backhand', 'label': 'Attack their backhand', 'emoji': '🎯'},
    {'id': 'consistent', 'label': 'Stay consistent, wait for errors', 'emoji': '🛡️'},
    {'id': 'serve_volley', 'label': 'Serve and volley', 'emoji': '⚡'},
    {'id': 'change_pace', 'label': 'Change pace frequently', 'emoji': '🔄'},
    {'id': 'aggressive', 'label': 'Be aggressive, dictate play', 'emoji': '💪'},
    {'id': 'angles', 'label': 'Move them with angles', 'emoji': '📐'},
  ];

  @override
  void dispose() {
    _opponentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_hasSubmitted && _briefingResponse != null) {
      return _buildBriefingView(isDark);
    }
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '🧠 Pre-Match Prep',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.psychology, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tactical Preparation',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Get focused before you step on court',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Opponent (optional)
            Text(
              'Playing against (optional)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _opponentController,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              decoration: InputDecoration(
                hintText: 'Opponent name...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Game Plan
            Text(
              "What's your game plan?",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gamePlanOptions.map((option) {
                final isSelected = _selectedGamePlan == option['id'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedGamePlan = isSelected ? null : option['id'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.withOpacity(isDark ? 0.3 : 0.15)
                          : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.blue 
                            : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(option['emoji'] ?? '', style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          option['label'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected 
                                ? Colors.blue 
                                : (isDark ? Colors.grey[300] : Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Confidence Level
            Text(
              'Confidence Level',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_confidenceLevel',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _getConfidenceColor(_confidenceLevel),
                        ),
                      ),
                      Text(
                        '/10',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _confidenceLevel.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: _getConfidenceColor(_confidenceLevel),
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _confidenceLevel = value.round();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nervous',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(
                        'Ready to dominate',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Additional Notes
            Text(
              'Anything else on your mind? (optional)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : Colors.grey[800],
              ),
              decoration: InputDecoration(
                hintText: 'Concerns, focus areas, recent form...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Get Briefing Button
            GestureDetector(
              onTap: _isLoading ? null : _getBriefing,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Preparing your briefing...',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Get Pre-Match Briefing 🎯',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBriefingView(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '🎯 Your Briefing',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _opponentController.text.isNotEmpty 
                              ? 'vs ${_opponentController.text}'
                              : 'Match Prep Complete',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        if (_selectedGamePlan != null)
                          Text(
                            'Plan: ${gamePlanOptions.firstWhere((o) => o['id'] == _selectedGamePlan)['label']}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.blue.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Briefing Response
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.psychology, color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tactical Briefing',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    _briefingResponse!,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      height: 1.7,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _hasSubmitted = false;
                        _briefingResponse = null;
                        _opponentController.clear();
                        _notesController.clear();
                        _selectedGamePlan = null;
                        _confidenceLevel = 7;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'New Prep',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade500, Colors.green.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Ready to Play! 🎾',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(int level) {
    if (level <= 3) return Colors.red;
    if (level <= 5) return Colors.orange;
    if (level <= 7) return Colors.amber;
    return Colors.green;
  }

  Future<void> _getBriefing() async {
    // Build context for AI
    final gamePlanLabel = _selectedGamePlan != null
        ? gamePlanOptions.firstWhere((o) => o['id'] == _selectedGamePlan)['label']
        : 'No specific plan';
    
    // Validate notes if substantial
    if (_notesController.text.trim().length > 20) {
      final validationError = TennisValidator.validate(_notesController.text);
      if (validationError != null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError, style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Check usage limits
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final usageService = Provider.of<UsageService>(context, listen: false);
    
    if (!purchaseService.isPremium && !usageService.canUsePrepSession) {
      HapticFeedback.mediumImpact();
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(trigger: PaywallTrigger.prepSessionLimit),
        ),
      );
      if (result != true) return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final profileService = Provider.of<PlayerProfileService>(context, listen: false);
      final playerContext = profileService.getPlayerContext();
      
      final briefingRequest = '''
$playerContext

Pre-Match Preparation Request:
- Opponent: ${_opponentController.text.isNotEmpty ? _opponentController.text : 'Unknown'}
- Game Plan: $gamePlanLabel
- Confidence Level: $_confidenceLevel/10
- Additional Notes: ${_notesController.text.isNotEmpty ? _notesController.text : 'None'}

Please provide a focused tactical briefing.
''';

      final apiService = Provider.of<ApiService>(context, listen: false);
      final response = await apiService.mentalCheckIn(_confidenceLevel, briefingRequest);
      
      // Record usage
      if (!purchaseService.isPremium) {
        await usageService.recordPrepSession();
      }

      // Save to storage
      final entry = CheckInEntry(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        rating: _confidenceLevel,
        journalText: briefingRequest,
      );
      await StorageService.saveCheckIn(entry);

      setState(() {
        _isLoading = false;
        _hasSubmitted = true;
        _briefingResponse = response;
      });
      
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

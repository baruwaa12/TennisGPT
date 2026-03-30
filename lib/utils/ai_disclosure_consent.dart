import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles first-use consent for AI processing disclosures.
class AiDisclosureConsent {
  static const String _acceptedKey = 'ai_disclosure_accepted_v1';

  static Future<bool> ensureAccepted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_acceptedKey) ?? false;
    if (accepted) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          'AI Processing Notice',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'To generate coaching insights, your match notes and prompts are sent '
          'to our AI provider (OpenAI) for processing.\n\n'
          'By continuing, you agree to this processing as described in our Privacy Policy.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Continue', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    final consented = result == true;
    if (consented) {
      await prefs.setBool(_acceptedKey, true);
    }
    return consented;
  }
}

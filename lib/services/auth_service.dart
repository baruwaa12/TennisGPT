// Sign in with Google (mobile OAuth + deep link)
Future<void> signInWithGoogle() async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════');
      print('Starting Google OAuth flow...');
      print('═══════════════════════════════════════════════════════');
    }

    // Optional sanity check: ensure Google provider is enabled
    final providers = await _supabase.auth.listProviders();
    if (kDebugMode) {
      print('Available providers: ${providers.map((p) => p.id).toList()}');
    }

    if (!providers.any((p) => p.id == 'google')) {
      throw Exception(
        'Google OAuth provider is not enabled in Supabase.\n\n'
        'To fix:\n'
        '1. Supabase Dashboard → Authentication → Providers → Google\n'
        '2. Toggle Google ON and add Client ID + Client Secret\n'
        '3. Save changes',
      );
    }

    if (kDebugMode) {
      print('✅ Google provider is enabled');
      print('Calling signInWithOAuth WITHOUT redirectTo (mobile PKCE flow)...');
    }

    // ❗ IMPORTANT: no redirectTo here
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (kDebugMode) {
      print('OAuth flow launched. Waiting for deep link callback...');
      print('The auth state listener in initialize() will handle the session.');
    }

    // Do NOT set _isLoading = false here.
    // We wait for the auth state listener to fire `signedIn`.
  } catch (e) {
    _error = e.toString().replaceFirst('Exception: ', '');
    _isLoading = false;
    notifyListeners();
    if (kDebugMode) {
      print('Error signing in with Google: $e');
    }
  }
}

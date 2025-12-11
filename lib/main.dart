import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/openai_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with PKCE auth flow for mobile OAuth
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    print('SUPABASE_URL from .env = ${dotenv.env['SUPABASE_URL']}');
    print('SUPABASE_ANON_KEY is set = ${dotenv.env['SUPABASE_ANON_KEY'] != null}');
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Optional: check if we already have a session
  final initialSession = Supabase.instance.client.auth.currentSession;
  if (initialSession != null) {
    // This can happen if the user was already logged in
    // or if Supabase processed a deep link before build
    // (mostly useful for logging)
    // ignore: avoid_print
    print('App started with existing session: ${initialSession.user.email}');
  } else {
    // ignore: avoid_print
    print('No existing session found at startup');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => OpenAIService()),
        // Initialize AuthService immediately so it sets up the auth listener
        ChangeNotifierProvider(
          create: (context) => AuthService()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'TennisGPT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // While we're not sure yet, you *could* show a loader,
        // but for now we just swap based on isAuthenticated.
        if (authService.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

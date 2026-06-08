import 'package:eigen_flutter/providers/auth_provider.dart';
import 'package:eigen_flutter/screens/auth.dart' show AuthScreen;
import 'package:eigen_flutter/screens/home.dart';
import 'package:eigen_flutter/screens/main.dart';
import 'package:eigen_flutter/screens/question_screen.dart';
import 'package:eigen_flutter/screens/single_contest_questions_screen.dart';
import 'package:eigen_flutter/screens/single_contest_screen.dart';
import 'package:eigen_flutter/storage/storage_provider.dart';
import 'package:eigen_flutter/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://orojpltfjcypnhjvjyjg.supabase.co',
    anonKey: 'sb_publishable_Psf4yYJ1CuD-B3MqIQwMag_UJu2swoT',
  );
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    return MaterialApp(
      onGenerateRoute: (settings) {
        // /question route — argument is the question id string
        if (settings.name == '/question') {
          final questionId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => QuestionScreen(questionId: questionId),
          );
        }

                // inside onGenerateRoute, add alongside /contest:
        if (settings.name == '/contest-questions') {
          final contestId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => ContestQuestionsScreen(contestId: contestId),
          );
        }

        if (settings.name == '/contest') {
            final contestId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => SingleContestScreen(contestId: contestId),
            );
          }
        // Static routes
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/auth':
            return MaterialPageRoute(
                builder: (_) => AuthScreen(initialMode: 'signup'));
          case '/main':
            return MaterialPageRoute(builder: (_) => const MainScreen());
          case '/contest-questions':
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Contest questions coming soon')),
                ),
              );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('404')),
              ),
            );
        }
      },
      home: authAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const Scaffold(
          body: Center(child: Text('Something went wrong on startup.')),
        ),
        data: (authState) => authState.isAuthenticated
            ? const MainScreen()
            : const HomeScreen(),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/audio_handler_provider.dart';
import 'features/splash/presentation/splash_screen.dart';

class MusiqApp extends ConsumerWidget {
  const MusiqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure audio handler is initialized and wired
    ref.watch(audioHandlerProvider);

    return MaterialApp(
      title: 'Musiq',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}

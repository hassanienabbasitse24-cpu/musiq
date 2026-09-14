import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_handler.dart';

final audioHandlerProvider = Provider<MusiqAudioHandler>((ref) {
  final handler = MusiqAudioHandler();
  ref.onDispose(() async {
    try {
      await handler.stop();
    } catch (_) {}
  });
  return handler;
});

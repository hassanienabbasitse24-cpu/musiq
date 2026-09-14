import 'dart:async';

class AudioElement {
  String src = '';
  double currentTime = 0;
  double duration = 0;
  double volume = 1.0;

  final Stream<dynamic> onTimeUpdate = const Stream.empty();
  final Stream<dynamic> onEnded = const Stream.empty();
  final Stream<dynamic> onError = const Stream.empty();

  Future<void> play() async {}
  void pause() {}
}

class DummyWindow {
  final Map<String, String> localStorage = {};
}

final DummyWindow window = DummyWindow();

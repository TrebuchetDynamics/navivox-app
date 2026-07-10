abstract interface class TextToSpeechService {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> dispose();
}

class FakeTextToSpeechService implements TextToSpeechService {
  final List<String> spoken = [];
  int stopCalls = 0;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> dispose() => stop();
}

class NeedleEngineException implements Exception {
  const NeedleEngineException(this.message);

  final String message;

  @override
  String toString() => 'NeedleEngineException: $message';
}

abstract interface class NeedleEngineApi {
  bool get isLoaded;
  Future<void> load(String modelDir);
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  });
  Future<void> unload();
}

class NativeCallQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() op) {
    final result = _tail.then((_) => op());
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }
}

class NeedleEngine implements NeedleEngineApi {
  static const _unsupported = NeedleEngineException(
    'Needle voice commands are not supported on web.',
  );

  @override
  bool get isLoaded => false;

  @override
  Future<void> load(String modelDir) => Future.error(_unsupported);

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) => Future.error(_unsupported);

  @override
  Future<void> unload() async {}
}

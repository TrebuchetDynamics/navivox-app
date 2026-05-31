void regressionExpect(bool condition, String message) {
  if (!condition) throw StateError(message);
}

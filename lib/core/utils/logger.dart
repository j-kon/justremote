class AppLogger {
  const AppLogger._();

  static void info(String message) {
    // Keep logging lightweight for the MVP; replace with structured logging only
    // if diagnostics become necessary.
    // ignore: avoid_print
    print('[JustRemote] $message');
  }
}

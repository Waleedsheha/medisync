import 'pwa_install_stub.dart'
    if (dart.library.js_util) 'pwa_install_web.dart' as impl;

/// PWA install prompt helper.
///
/// Android/Chrome requires a user gesture to show the prompt; this API is meant
/// to be called from a button tap.
class PwaInstall {
  static Future<bool> canPrompt() => impl.canPrompt();

  /// Returns true if the user accepted installation.
  static Future<bool> prompt() => impl.prompt();
}

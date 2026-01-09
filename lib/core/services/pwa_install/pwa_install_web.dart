// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist

import 'dart:js_util' as js_util;

Object get _global => js_util.globalThis;

Future<bool> canPrompt() async {
  if (!js_util.hasProperty(_global, 'pwaCanInstall')) return false;
  final res = js_util.callMethod(_global, 'pwaCanInstall', const []);
  return res == true;
}

Future<bool> prompt() async {
  if (!js_util.hasProperty(_global, 'pwaInstall')) return false;

  final promise = js_util.callMethod(_global, 'pwaInstall', const []);
  final result = await js_util.promiseToFuture<Object?>(promise);

  if (result == null) return false;
  if (!js_util.hasProperty(result, 'outcome')) return false;
  final outcome = js_util.getProperty(result, 'outcome')?.toString();
  return outcome == 'accepted';
}

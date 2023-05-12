import 'dart:io';

import 'config.dart';

Future<void> initialiseAnalytics() async {
  if (analytics) {}
}

Future<void> logEvent(eventName) async {
  if (analytics) {}
}

Future<void> logAppOpen() async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {}
}

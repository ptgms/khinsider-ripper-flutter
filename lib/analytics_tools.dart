import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'config.dart';

Future<void> initialiseAnalytics() async {
  if (analytics) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
  }
}

Future<void> logEvent(eventName) async {
  if (analytics) {
    await FirebaseAnalytics.instance.logEvent(
      name: eventName,
    );
  }
}

Future<void> logAppOpen() async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await FirebaseAnalytics.instance.logAppOpen();
  }
}

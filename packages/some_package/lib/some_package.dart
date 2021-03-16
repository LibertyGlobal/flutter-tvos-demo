
import 'dart:async';

import 'package:flutter/services.dart';

class SomePackage {
  static const MethodChannel _channel =
      const MethodChannel('some_package');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreenSecurity {
  ProfileScreenSecurity._();

  static const MethodChannel _channel = MethodChannel('com.anbu.matrimony/screen_security');

  static Future<void> enable() async {
    await _channel.invokeMethod<void>('setSecure', true);
  }

  static Future<void> disable() async {
    await _channel.invokeMethod<void>('setSecure', false);
  }
}

class SecureProfileScreen extends StatefulWidget {
  const SecureProfileScreen({required this.child, super.key});

  final Widget child;

  @override
  State<SecureProfileScreen> createState() => _SecureProfileScreenState();
}

class _SecureProfileScreenState extends State<SecureProfileScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_setSecure(true));
  }

  @override
  void dispose() {
    unawaited(_setSecure(false));
    super.dispose();
  }

  Future<void> _setSecure(bool enabled) async {
    try {
      if (enabled) {
        await ProfileScreenSecurity.enable();
      } else {
        await ProfileScreenSecurity.disable();
      }
    } on PlatformException catch (error, stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Anbu Matrimony profile security',
        context: ErrorDescription('while toggling protected-screen capture behavior'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

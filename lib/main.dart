import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';
export 'src/app.dart' show OneBitApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const OneBitApp());
}

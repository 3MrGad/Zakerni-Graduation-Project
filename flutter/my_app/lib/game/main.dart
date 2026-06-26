import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
//import 'login_screen.dart';
import 'patient_game_entry.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MemoryBridgeApp());
}

class MemoryBridgeApp extends StatelessWidget {
  const MemoryBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Bridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const PatientGameEntry(),
    );
  }
}

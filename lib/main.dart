import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovelense_booth/screens/start_screen.dart';

void main() {
  runApp(const ProviderScope(child: LoveLenseBooth()));
}

class LoveLenseBooth extends StatelessWidget {
  const LoveLenseBooth({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoveLense Booth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF75E6DA),
          primary: const Color(0xFF75E6DA),
          secondary: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Montserrat',
      ),
      home: const StartScreen(),
    );
  }
}

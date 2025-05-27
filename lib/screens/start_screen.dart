import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovelense_booth/screens/camera_screen.dart';
import 'package:animated_background/animated_background.dart';
import 'package:lovelense_booth/services/camera_service.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen>
    with TickerProviderStateMixin {
  // TickerProviderStateMixin is needed for AnimatedBackground

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Ensure camera is disposed when leaving the start screen
    ref.read(cameraServiceProvider).disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF87CEEB), // Light blue
                  Color(0xFF61ECD9), // Turquoise
                ],
              ),
            ),
          ),

          // Animated background on top of the gradient
          AnimatedBackground(
            behaviour: RandomParticleBehaviour(
              options: const ParticleOptions(
                baseColor: Color(0xFFBA68C8),
                spawnOpacity: 0.2,
                opacityChangeRate: 0.25,
                minOpacity: 0.1,
                maxOpacity: 0.3,
                particleCount: 70,
                spawnMaxRadius: 100,
                spawnMaxSpeed: 100,
                spawnMinSpeed: 30,
                spawnMinRadius: 5,
              ),
            ),
            vsync: this,
            child: SafeArea(
              child: Stack(
                children: [
                  // Logo and App name at the top left
                  Positioned(
                    top: 30,
                    left: 30,
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration:
                              const BoxDecoration(shape: BoxShape.circle),
                          child: Center(
                            child: Image.asset(
                              'assets/images/LoveLenseIcon.png',
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'LoveLense Booth',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // START button centered
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Ensure camera is disposed before navigating
                        ref.read(cameraServiceProvider).disposeCamera();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CameraScreen(
                              initialFrameCount: 3,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'START',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the idle service
final idleServiceProvider = Provider((ref) => IdleService());

class IdleService {
  Timer? _idleTimer;
  final Duration _idleTimeout = const Duration(minutes: 3);
  final List<Function()> _onIdleCallbacks = [];

  // Add a callback to be executed when idle timeout is reached
  void addOnIdleCallback(Function() callback) {
    _onIdleCallbacks.add(callback);
  }

  // Remove a callback
  void removeOnIdleCallback(Function() callback) {
    _onIdleCallbacks.remove(callback);
  }

  // Start monitoring user activity
  void startMonitoring() {
    // Cancel any existing timer
    _idleTimer?.cancel();

    // Start the idle timer
    _resetIdleTimer();
  }

  // Stop monitoring
  void stopMonitoring() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, () {
      // Execute all registered callbacks
      for (var callback in _onIdleCallbacks) {
        callback();
      }
    });
  }

  // Call this method whenever user activity is detected
  void onUserActivity() {
    _resetIdleTimer();
  }
}

// A widget that wraps its child and detects user activity
class IdleDetector extends StatelessWidget {
  final Widget child;
  final IdleService idleService;

  const IdleDetector({
    super.key,
    required this.child,
    required this.idleService,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => idleService.onUserActivity(),
      onPointerMove: (_) => idleService.onUserActivity(),
      onPointerUp: (_) => idleService.onUserActivity(),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => idleService.onUserActivity(),
        child: child,
      ),
    );
  }
}

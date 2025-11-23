import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:the_basics/core/utils/session_manager.dart';

class InactivityDetector extends StatefulWidget {
  final Widget child;

  const InactivityDetector({super.key, required this.child});

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector> {
  void _resetTimer([PointerEvent? _]) {
    SessionManager.instance.resetTimer();
  }

  @override
  void initState() {
    super.initState();
    SessionManager.instance.start();
  }

  @override
  void dispose() {
    SessionManager.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _resetTimer,
      onPointerMove: _resetTimer,
      onPointerUp: _resetTimer,
      onPointerSignal: _resetTimer,
      child: widget.child,
    );
  }
}

// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
import 'dart:async';

class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({
    Key? key,
    required this.height,
    required this.width,
    this.cursorWidth = 2.0,
    this.cursorHeight = 20.0,
    this.cursorColor = Colors.black,
  }) : super(key: key);
  final double? height;
  final double? width;
  final double cursorWidth;
  final double cursorHeight;
  final Color cursorColor;

  @override
  _BlinkingCursorState createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _cursorColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _cursorColor = ColorTween(
      begin: widget.cursorColor,
      end: Colors.transparent,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cursorColor,
      builder: (context, child) {
        return Container(
          width: widget.cursorWidth,
          height: widget.cursorHeight,
          color: _cursorColor.value,
        );
      },
    );
  }
}

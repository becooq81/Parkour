// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:http/http.dart' as http;
import 'dart:convert';

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
// Other imports...
class CustomKoreanKeyboard extends StatefulWidget {
  const CustomKoreanKeyboard(
      {Key? key, required this.height, required this.width})
      : super(key: key);
  final double? height;
  final double? width;
  @override
  _CustomKeyboardState createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKoreanKeyboard> {
  String text = "";
  bool isShiftEnabled = false;
  TextEditingController textController = TextEditingController();
  TextEditingController coordinateController = TextEditingController();
  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    coordinateController = TextEditingController();
  }

  @override
  void dispose() {
    textController.dispose();
    coordinateController.dispose();
    super.dispose();
  }

  void onKeyTap(String key, DragDownDetails details) {
    final position = details.globalPosition; // Position of the user's tap
    setState(() {
      if (key == "←") {
        if (text.isNotEmpty) {
          text = text.substring(0, text.length - 1);
        }
      } else if (key == "↑") {
        isShiftEnabled = !isShiftEnabled;
      } else if (key == " ") {
        text += ' ';
      } else {
        text += isShiftEnabled ? toDoubled(key) : toSingled(key);
      }
      textController.text = text;
      Offset relativePosition = getRelativePosition(position);
      coordinateController.text =
          "X: ${relativePosition.dx.toStringAsFixed(2)}, Y: ${relativePosition.dy.toStringAsFixed(2)}";
    });
  }

  Offset getRelativePosition(Offset globalPosition) {
    final RenderBox renderBoxKeyboard = context.findRenderObject() as RenderBox;
    final keyboardSize = renderBoxKeyboard.size;
    final centerOfKeyboard = Offset(
        renderBoxKeyboard.localToGlobal(Offset.zero).dx +
            keyboardSize.width / 2,
        renderBoxKeyboard.localToGlobal(Offset.zero).dy +
            keyboardSize.height / 2);
    // Invert the Y-coordinate calculation
    return Offset(globalPosition.dx - centerOfKeyboard.dx,
        centerOfKeyboard.dy - globalPosition.dy // Inverted Y-coordinate
        );
  }

  String toDoubled(String input) {
    // Map of single characters to their doubled counterparts
    Map<String, String> charMap = {
      'ㄱ': 'ㄲ',
      'ㄷ': 'ㄸ',
      'ㅂ': 'ㅃ',
      'ㅈ': 'ㅉ',
      'ㅅ': 'ㅆ'
    };

    // Replace characters in the input string
    String result = input.split('').map((char) {
      return charMap[char] ??
          char; // Replace with mapped char, or keep original if not mapped
    }).join('');

    return result;
  }

  String toSingled(String input) {
    // Map of single characters to their doubled counterparts
    Map<String, String> charMap = {
      'ㄲ': 'ㄱ',
      'ㄸ': 'ㄷ',
      'ㅃ': 'ㅂ',
      'ㅉ': 'ㅈ',
      'ㅆ': 'ㅅ'
    };

    // Replace characters in the input string
    String result = input.split('').map((char) {
      return charMap[char] ??
          char; // Replace with mapped char, or keep original if not mapped
    }).join('');

    return result;
  }

  Widget buildKey(String key) {
    return Expanded(
      child: GestureDetector(
        onPanDown: (details) => onKeyTap(key, details),
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            color: Colors.grey[200],
          ),
          child: Text(
            isShiftEnabled && !isSpecialKey(key)
                ? toDoubled(key)
                : toSingled(key),
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  bool isSpecialKey(String key) {
    return key == "↑" || key == "←" || key == " ";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          width: widget.width,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: textController,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Input Text',
                  ),
                ),
              ),
              ...keys.map((row) {
                return Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row.map((key) => buildKey(key)).toList(),
                  ),
                );
              }).toList(),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: coordinateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Touch Coordinates',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<List<String>> keys = [
    ["ㅂ", "ㅈ", "ㄷ", "ㄱ", "ㅅ", "ㅛ", "ㅕ", "ㅑ", "ㅐ", "ㅔ"],
    ["ㅁ", "ㄴ", "ㅇ", "ㄹ", "ㅎ", "ㅗ", "ㅓ", "ㅏ", "ㅣ"],
    ["↑", "ㅋ", "ㅌ", "ㅊ", "ㅍ", "ㅠ", "ㅜ", "ㅡ", "←"],
    [" "]
  ];
}

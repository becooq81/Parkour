// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share/share.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class DesignedKeyboard extends StatefulWidget {
  const DesignedKeyboard({Key? key, required this.height, required this.width})
      : super(key: key);
  final double? height;
  final double? width;
  @override
  _CustomKeyboardState createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<DesignedKeyboard> {
  String text = "";
  String word = "";
  String sentenceText = "";
  bool isShiftEnabled = true;
  bool isDoubleShiftEnabled = false;
  bool isAlphabetKeypad = true;
  bool isNumKeypad = false;
  bool isFirstSpecialKeypad = false;
  bool isSecSpecialKeypad = false;
  bool areSentencesVisible = false;
  bool isAddingSentence = false;
  bool isKeyboardVisible = false;
  bool isNewFieldEmpty = true;

  List<String> sentences = [
    "Please call me.",
    "I'm at home",
    "I'm at hospital.",
    // ... add more sentences ...
  ];

  TextEditingController textController = TextEditingController();
  List<KeyPressInfo> coordinates = [];
  ScrollController scrollController = ScrollController();
  ScrollController textFieldScrollController = ScrollController();
  ScrollController newTextFieldScrollController = ScrollController();
  TextEditingController newSentenceController = TextEditingController();
  FocusNode textFocusNode = FocusNode();

  int cursorPosition = 0;
  int sentCursorPosition = 0;

  String userInputText = "";
  String predictedText2 = "";
  String predictedText1 = "";

  late double keyboardHeight;
  late DateTime lastShiftTap;
  late File keyCoordinatesCSV;
  late File inputCoordinatesCSV;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    scrollController = ScrollController();
    textFieldScrollController = ScrollController();
    lastShiftTap = DateTime.now();
    newSentenceController.addListener(() {
      setState(() {
        isNewFieldEmpty = newSentenceController.text.isEmpty;
      });
    });
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    textFieldScrollController.dispose();
    newTextFieldScrollController.dispose();
    textFocusNode.dispose();
    super.dispose();
  }

  void updateTextAndScroll(String newText) {
    setState(() {
      text = newText;
      textController.text = text;
    });
    // Schedule a callback for the end of this frame to scroll to the bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (textFieldScrollController.hasClients) {
        textFieldScrollController
            .jumpTo(textFieldScrollController.position.maxScrollExtent);
      }
    });
  }

  void updateNewTextAndScroll(String newText) {
    setState(() {
      sentenceText = newText;
      newSentenceController.text = text;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (newTextFieldScrollController.hasClients) {
        newTextFieldScrollController
            .jumpTo(newTextFieldScrollController.position.maxScrollExtent);
      }
    });
  }

  void copyAndExport() {
    Clipboard.setData(ClipboardData(text: text));
    exportCoordinatesToCSV();
    exportKeyCoordinatesToCSV();
    //sendEmailWithCsvs(keyCoordinatesCSV, inputCoordinatesCSV);
    setState(() {
      isKeyboardVisible = false; // Hide the keyboard
    });
  }

  Future<void> sendEmailWithCsvs(File csvFile1, File csvFile2) async {
    final Email email = Email(
      body: 'Here are your CSV files.',
      subject: 'CSV Files',
      recipients: ['gdsc.yonsei.parkour@gmail.com'],
      attachmentPaths: [csvFile1.path, csvFile2.path], // Attach two files
      isHTML: false,
    );
    await FlutterEmailSender.send(email);
  }

  void exportCoordinatesToCSV() async {
    final coordinatesList = coordinates
        .map((e) => [
              DateFormat('yyyy-MM-dd HH:mm:ss').format(e.timestamp),
              e.position.dx,
              e.position.dy,
              e.isShiftEnabled,
              e.isDoubleShiftEnabled,
              e.isAlphabetKeypad,
              e.isNumKeypad,
              e.isFirstSpecialKeypad,
              e.isSecSpecialKeypad,
              e.key,
            ])
        .toList();
    final List<List<dynamic>> csvData = [
      [
        'Timestamp',
        'X',
        'Y',
        'Is Shift Enabled',
        'Is Double Shift Enabled',
        'Is Alphabet Keypad'
            'Is Num Keypad',
        'Is Special Keypad',
        'Is Second Special Keypad',
        'Key value'
      ],
      ...coordinatesList,
    ];
    final String csv = const ListToCsvConverter().convert(csvData);
    // Updated path to the project directory
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/coordinates.csv';
    inputCoordinatesCSV = File(filePath);
    await inputCoordinatesCSV.writeAsString(csv);
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  void updateTexts(String ui, String pt2) {
    setState(() {
      userInputText = ui;
      predictedText2 = pt2;
    });
  }

  void onKeyTap(String key, DragDownDetails details) {
    final position = details.globalPosition;
    Offset relativePosition = getRelativePosition(position);
    if (!isAddingSentence) {
      if (key == "←") {
        if (text.isNotEmpty && cursorPosition != 0) {
          text = text.substring(0, cursorPosition - 1) +
              text.substring(cursorPosition);
          word = word.substring(0, cursorPosition - 1) +
              word.substring(cursorPosition);
          cursorPosition--;
        }
        coordinates.add(KeyPressInfo(
          position: Offset(100000.0, 100000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "BACKSPACE",
        ));
      } else if (key == "↑") {
        if (isDoubleShiftEnabled) {
          setState(() {
            isDoubleShiftEnabled = false;
            isShiftEnabled = false;
          });
        } else {
          DateTime now = DateTime.now();
          if (now.difference(lastShiftTap).inMilliseconds < 300) {
            // Double tap detected
            setState(() {
              isDoubleShiftEnabled = true;
            });
          } else {
            // Single tap or time between taps is too long
            setState(() {
              isDoubleShiftEnabled = false;
              isShiftEnabled = !isShiftEnabled;
            });
          }
          lastShiftTap = now;
        }
        coordinates.add(KeyPressInfo(
          position: Offset(200000.0, 200000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "SHIFT",
        ));
      } else if (key == " " || key == "␣") {
        text = text.substring(0, cursorPosition) +
            " " +
            text.substring(cursorPosition);
        cursorPosition++;
        if (text.isNotEmpty && text.endsWith('.')) {
          setState(() {
            isShiftEnabled = true;
          });
        }
        coordinates.add(KeyPressInfo(
          position: Offset(400000.0, 400000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "SPACEBAR",
        ));
        sendCoordinatesToServer(coordinates);
      } else if (key == "⏎") {
        text = text.substring(0, cursorPosition) +
            "\n" +
            text.substring(cursorPosition);
        cursorPosition++;
        coordinates.add(KeyPressInfo(
          position: Offset(300000.0, 300000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "ENTER",
        ));
      } else if (key == "◂") {
        cursorPosition = max(0, cursorPosition - 1);
        coordinates.add(KeyPressInfo(
          position: Offset(500000.0, 500000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "MOVE CURSOR LEFT",
        ));
      } else if (key == "▸") {
        cursorPosition = min(text.length, cursorPosition + 1);
        coordinates.add(KeyPressInfo(
          position: Offset(600000.0, 600000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "MOVE CURSOR RIGHT",
        ));
      } else if (key == "123") {
        setState(() {
          isNumKeypad = true;
          isFirstSpecialKeypad = false;
          isSecSpecialKeypad = false;
          isAlphabetKeypad = false;
        });
        coordinates.add(KeyPressInfo(
          position: Offset(700000.0, 700000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "CHANGE TO NUMKEYPAD",
        ));
      } else if (key == "abc") {
        setState(() {
          isNumKeypad = false;
          isFirstSpecialKeypad = false;
          isSecSpecialKeypad = false;
          isAlphabetKeypad = true;
        });
        coordinates.add(KeyPressInfo(
          position: Offset(800000.0, 800000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "CHANGE TO ALPHABET KEYPAD",
        ));
      } else if (key == "#?!" || key == "2/2") {
        setState(() {
          isNumKeypad = false;
          isFirstSpecialKeypad = true;
          isSecSpecialKeypad = false;
          isAlphabetKeypad = false;
        });
        coordinates.add(KeyPressInfo(
          position: Offset(900000.0, 900000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "CHANGE TO FIRST SPECIAL KEYPAD",
        ));
      } else if (key == "1/2") {
        setState(() {
          isNumKeypad = false;
          isFirstSpecialKeypad = false;
          isSecSpecialKeypad = true;
          isAlphabetKeypad = false;
        });
        coordinates.add(KeyPressInfo(
          position: Offset(1900000.0, 1900000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "CHANGE TO SECOND SPECIAL KEYPAD",
        ));
      } else {
        String addText = (isShiftEnabled || isDoubleShiftEnabled)
            ? key.toUpperCase()
            : key.toLowerCase();
        text = text.substring(0, cursorPosition) +
            addText +
            text.substring(cursorPosition);
        word = word.substring(0, cursorPosition) +
            addText +
            word.substring(cursorPosition);
        cursorPosition++;
        coordinates.add(KeyPressInfo(
          position: relativePosition,
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: addText,
        ));
      }

      if (word == "Hwu ") {
        updateTexts("Hwu", "her");
        text = "Hey";
        word = "";
      }
      if (word == "hokn, ") {
        updateTexts("hokn,", "john,");
        text = "John,";
        word = "";
      }

      textController.text = text;
      updateTextAndScroll(text);
    } else {
      if (key == "←") {
        if (sentenceText.isNotEmpty && sentCursorPosition != 0) {
          sentenceText = sentenceText.substring(0, sentCursorPosition - 1) +
              sentenceText.substring(sentCursorPosition);
          sentCursorPosition--;
        }
        coordinates.add(KeyPressInfo(
          position: Offset(100000.0, 100000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "BACKSPACE",
        ));
      } else if (key == "↑") {
        if (isDoubleShiftEnabled) {
          setState(() {
            isDoubleShiftEnabled = false;
            isShiftEnabled = false;
          });
        } else {
          DateTime now = DateTime.now();
          if (now.difference(lastShiftTap).inMilliseconds < 300) {
            // Double tap detected
            setState(() {
              isDoubleShiftEnabled = true;
            });
          } else {
            // Single tap or time between taps is too long
            setState(() {
              isDoubleShiftEnabled = false;
              isShiftEnabled = !isShiftEnabled;
            });
          }
          lastShiftTap = now;
        }
        coordinates.add(KeyPressInfo(
          position: Offset(200000.0, 200000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "SHIFT",
        ));
      } else if (key == " " || key == "␣") {
        sentenceText = sentenceText.substring(0, sentCursorPosition) +
            " " +
            sentenceText.substring(sentCursorPosition);
        sentCursorPosition++;
        if (sentenceText.isNotEmpty && sentenceText.endsWith('.')) {
          setState(() {
            isShiftEnabled = true;
          });
        }
        coordinates.add(KeyPressInfo(
          position: Offset(400000.0, 400000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "SPACEBAR",
        ));
        sendCoordinatesToServer(coordinates);
      } else if (key == "⏎") {
        sentenceText = sentenceText.substring(0, sentCursorPosition) +
            "\n" +
            sentenceText.substring(sentCursorPosition);
        sentCursorPosition++;

        coordinates.add(KeyPressInfo(
          position: Offset(300000.0, 300000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "ENTER",
        ));
        sendCoordinatesToServer(coordinates);
      } else if (key == "◂") {
        sentCursorPosition = max(0, sentCursorPosition - 1);
        coordinates.add(KeyPressInfo(
          position: Offset(500000.0, 500000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "MOVE CURSOR LEFT",
        ));
      } else if (key == "▸") {
        sentCursorPosition = min(sentenceText.length, sentCursorPosition + 1);
        coordinates.add(KeyPressInfo(
          position: Offset(600000.0, 600000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "MOVE CURSOR RIGHT",
        ));
      } else if (key == "123") {
        setState(() {
          isNumKeypad = true;
          isFirstSpecialKeypad = false;
          isSecSpecialKeypad = false;
          isAlphabetKeypad = false;
        });

        coordinates.add(KeyPressInfo(
          position: Offset(700000.0, 700000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "CHANGE TO NUMKEYPAD",
        ));
      } else if (key == "abc") {
        setState(() {
          isNumKeypad = false;
          isFirstSpecialKeypad = false;
          isSecSpecialKeypad = false;
          isAlphabetKeypad = true;
        });

        coordinates.add(KeyPressInfo(
          position: Offset(800000.0, 800000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "CHANGE TO ALPHABET KEYPAD",
        ));
      } else if (key == "#?!" || key == "2/2") {
        setState(() {
          isNumKeypad = false;
          isFirstSpecialKeypad = true;
          isSecSpecialKeypad = false;
          isAlphabetKeypad = false;
        });

        coordinates.add(KeyPressInfo(
          position: Offset(900000.0, 900000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "CHANGE TO FIRST SPECIAL KEYPAD",
        ));
      } else if (key == "1/2") {
        setState(() {
          isNumKeypad = false;
          isFirstSpecialKeypad = false;
          isSecSpecialKeypad = true;
          isAlphabetKeypad = false;
        });

        coordinates.add(KeyPressInfo(
          position: Offset(1900000.0, 1900000.0),
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: "CHANGE TO SECOND SPECIAL KEYPAD",
        ));
      } else {
        String addText = (isShiftEnabled || isDoubleShiftEnabled)
            ? key.toUpperCase()
            : key.toLowerCase();
        sentenceText = sentenceText.substring(0, sentCursorPosition) +
            addText +
            sentenceText.substring(sentCursorPosition);
        sentCursorPosition++;
        coordinates.add(KeyPressInfo(
          position: relativePosition,
          isShiftEnabled: isShiftEnabled,
          isDoubleShiftEnabled: isDoubleShiftEnabled,
          isAlphabetKeypad: isAlphabetKeypad,
          isNumKeypad: isNumKeypad,
          isFirstSpecialKeypad: isFirstSpecialKeypad,
          isSecSpecialKeypad: isSecSpecialKeypad,
          timestamp: DateTime.now(),
          key: addText,
        ));
      }

      newSentenceController.text = sentenceText;
      updateNewTextAndScroll(sentenceText);
    }

    if (isShiftEnabled && !isControlKey(key) && (!isDoubleShiftEnabled)) {
      isShiftEnabled = false;
    }

    print("isKeyboardVisible: " + isKeyboardVisible.toString());
    print("isAlphabetKeypad: " + isAlphabetKeypad.toString());
    print("isNumKeypad: " + isNumKeypad.toString());
    print("isFirstSpecialKeypad: " + isFirstSpecialKeypad.toString());
    print("isSecondSpecialKeypad: " + isSecSpecialKeypad.toString());
    print("areSentencesVisible: " + areSentencesVisible.toString());
    print("isAddingSentence: " + isAddingSentence.toString());
    print("isNewFieldEmpty: " + isNewFieldEmpty.toString());
  }

  Future<void> sendCoordinatesToServer(List<KeyPressInfo> keyPressInfos) async {
    var url = Uri.parse('http://your-server-url.com/endpoint');
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'keyPressInfos': keyPressInfos
              .map((e) => {
                    'x': e.position.dx,
                    'y': e.position.dy,
                    'isShiftEnabled': e.isShiftEnabled,
                    'isNumKeypad': e.isNumKeypad
                  })
              .toList()
        }),
      );
      if (response.statusCode == 200) {
        print("Coordinates sent successfully: ${response.body}");
      } else {
        print("Error sending coordinates: ${response.statusCode}");
      }
    } catch (e) {
      print("Network error occurred: $e");
    }
  }

  Offset getRelativePosition(Offset globalPosition) {
    final RenderBox renderBoxKeyboard = context.findRenderObject() as RenderBox;
    final keyboardSize = renderBoxKeyboard.size;
    final centerOfKeyboard = Offset(
        renderBoxKeyboard.localToGlobal(Offset.zero).dx +
            keyboardSize.width / 2,
        renderBoxKeyboard.localToGlobal(Offset.zero).dy +
            keyboardSize.height / 2);
    return Offset(globalPosition.dx - centerOfKeyboard.dx,
        centerOfKeyboard.dy - globalPosition.dy);
  }

  Offset getKeyCenter(String key) {
    // Find the row index and the key's index within that row
    int rowIndex = keys.indexWhere((row) => row.contains(key));
    int keyIndexInRow = keys[rowIndex].indexOf(key);
    // Calculate the width of the keyboard and each key
    final double keyboardWidth = MediaQuery.of(context).size.width;
    double keyWidth = keyboardWidth / keys[rowIndex].length;
    // Correctly determine the keyboard height
    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight =
        screenHeight * 0.4; // Assuming the keyboard occupies 40% of the screen
    // Calculate the height of each key
    double keyHeight = keyboardHeight / keys.length;
    // Calculate the top-left coordinate of the key
    double topLeftX = keyIndexInRow * keyWidth;
    double topLeftY = rowIndex * keyHeight;
    // Calculate the center coordinate of the key
    double centerX = topLeftX + keyWidth / 2;
    double centerY = topLeftY + keyHeight / 2;
    // Calculate the center of the keyboard
    double keyboardCenterX = keyboardWidth / 2;
    double keyboardCenterY = keyboardHeight / 2;
    // Calculate the key center relative to the keyboard center
    double relativeCenterX = centerX - keyboardCenterX;
    double relativeCenterY = centerY - keyboardCenterY;
    // Inverting the Y-axis to follow the conventional coordinate system
    relativeCenterY = -relativeCenterY;
    return Offset(relativeCenterX, relativeCenterY);
  }

  Offset getKeyCenterForNumPad(String key) {
    final double screenHeight =
        widget.height?.toDouble() ?? MediaQuery.of(context).size.height;
    final double screenWidth =
        widget.width?.toDouble() ?? MediaQuery.of(context).size.width;

    // Find the row index and the key's index within that row for the number keypad
    int rowIndex = numKeys.indexWhere((row) => row.contains(key));
    int keyIndexInRow = numKeys[rowIndex].indexOf(key);
    // Assuming different dimensions for number keys, calculate their width and height
    final double keyboardWidth = MediaQuery.of(context).size.width;
    double keyWidth = keyboardWidth / numKeys[rowIndex].length;
    // Assuming the number keypad occupies a different portion of the screen
    final double keyboardHeight =
        screenHeight * 0.3; // Example: 30% of the screen
    // Calculate the height of each key in the number keypad
    double keyHeight = keyboardHeight / numKeys.length;
    // Calculate the top-left coordinate of the key in the number keypad
    double topLeftX = keyIndexInRow * keyWidth;
    double topLeftY = rowIndex * keyHeight;
    // Calculate the center coordinate of the key
    double centerX = topLeftX + keyWidth / 2;
    double centerY = topLeftY + keyHeight / 2;
    // Calculate the center of the keyboard
    double keyboardCenterX = keyboardWidth / 2;
    double keyboardCenterY = keyboardHeight / 2;
    // Calculate the key center relative to the keyboard center
    double relativeCenterX = centerX - keyboardCenterX;
    double relativeCenterY = centerY - keyboardCenterY;
    // Inverting the Y-axis to follow the conventional coordinate system
    relativeCenterY = -relativeCenterY;
    return Offset(relativeCenterX, relativeCenterY);
  }

  // Calculate and export key coordinates to CSV
  void exportKeyCoordinatesToCSV() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/key_coordinates.csv';
    keyCoordinatesCSV = File(filePath);
    List<List<dynamic>> csvData = [
      ['Key', 'Center X', 'Center Y'],
    ];
    for (var row in keys) {
      for (var key in row) {
        final keyCenter = getKeyCenter(key);
        csvData.add([key, keyCenter.dx, keyCenter.dy]);
      }
    }
    // Add coordinates for number keys
    for (var row in numKeys) {
      for (var key in row) {
        final keyCenter =
            getKeyCenterForNumPad(key); // Use the new function for number keys
        csvData.add([key, keyCenter.dx, keyCenter.dy]);
      }
    }
    String csv = const ListToCsvConverter().convert(csvData);
    await keyCoordinatesCSV.writeAsString(csv);
  }

  double getKeyHeight(List<List<String>> keys) {
    final double screenHeight =
        widget.height?.toDouble() ?? MediaQuery.of(context).size.height;

    final double exHeight = 892;

    if (isKeyboardVisible) {
      if (isNumKeypad) {
        return 46 / exHeight * screenHeight;
      } else {
        return 40 / exHeight * screenHeight;
      }
    } else {
      return 0;
    }
  }

  Widget buildKey(List<List<String>> keys, String key) {
    final double screenHeight =
        widget.height?.toDouble() ?? MediaQuery.of(context).size.height;
    final double screenWidth =
        widget.width?.toDouble() ?? MediaQuery.of(context).size.width;

    final double exHeight = 892.0;
    final double exWidth = 412.0;

    double keyWidth = screenWidth * 30.0 / exWidth;
    double customFontSize = 22.0 / exHeight * screenHeight;
    Color customColor = Color(0xffE0EAF9);
    if (key == " ") {
      keyWidth = screenWidth * 150.0 / exWidth;
    } else if (key == "↑") {
      keyWidth = screenWidth * 0.20873786407;
      if (isDoubleShiftEnabled || isShiftEnabled) {
        customFontSize = screenHeight * 0.030;
      }
    } else if (key == "←") {
      keyWidth = screenWidth * 89.0 / exWidth;
    } else if (key == "123" || key == "#?!" || key == "abc") {
      keyWidth = screenWidth * 64.0 / exWidth;
    } else if (key == "⏎") {
      keyWidth = screenWidth * 100.0 / exWidth;
      customColor = Color(0xffA6C8FF);
    } else if (key == "◂" || key == "▸") {
      keyWidth = screenWidth * 45.0 / exWidth;
      customFontSize = screenHeight * 30.0 / exHeight;
      customColor = Color(0xffA6C8FF);
    } else if (keys[1].contains(key)) {
      keyWidth = screenWidth * 34.0 / exWidth;
    } else if (keys[2].contains(key)) {
      keyWidth = screenWidth * 37.0 / exWidth;
    }

    if (key == "#?!") {
      customColor = Color(0xffBDC6DC);
    }

    return GestureDetector(
      onPanDown: (details) => onKeyTap(key, details),
      child: Container(
        width: keyWidth,
        height: getKeyHeight(keys),
        alignment: Alignment.center,
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: customColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          (isShiftEnabled || isDoubleShiftEnabled) && !isControlKey(key)
              ? key.toUpperCase()
              : key.toLowerCase(),
          style: TextStyle(
            fontSize: customFontSize,
            color: Color(0xff1B1B1D),
          ),
        ),
      ),
    );
  }

  Widget buildSpecialKey(List<List<String>> keys, String key) {
    final double screenHeight =
        widget.height?.toDouble() ?? MediaQuery.of(context).size.height;
    final double screenWidth =
        widget.width?.toDouble() ?? MediaQuery.of(context).size.width;
    final double exHeight = 892.0;
    final double exWidth = 412.0;

    double keyWidth = screenWidth * 55.0 / exWidth;
    double customFontSize = 22.0 / exHeight * screenHeight;
    Color customColor = Color(0xffE0EAF9);

    if (key == " ") {
      keyWidth = screenWidth * 150.0 / exWidth;
    } else if (key == "1/2" || key == "2/2") {
      keyWidth = screenWidth * 0.2;
      customFontSize = 20.0 / exHeight * screenHeight;
    } else if (key == "←") {
      keyWidth = screenWidth * 89.0 / exWidth;
    } else if (key == "123" || key == "#?!" || key == "abc") {
      keyWidth = screenWidth * 64.0 / exWidth;
    } else if (key == "⏎") {
      keyWidth = screenWidth * 100.0 / exWidth;
      customColor = Color(0xffA6C8FF);
    } else if (key == "◂" || key == "▸") {
      keyWidth = screenWidth * 45.0 / exWidth;
      customColor = Color(0xffA6C8FF);
      customFontSize = screenHeight * 30.0 / exHeight;
    }

    if (key == "abc") {
      customColor = Color(0xffBDC6DC);
    }

    return GestureDetector(
      onPanDown: (details) => onKeyTap(key, details),
      child: Container(
        width: keyWidth,
        height: getKeyHeight(keys),
        alignment: Alignment.center,
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: customColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          key,
          style: TextStyle(
            fontSize: customFontSize,
            color: Color(0xff1B1B1D),
          ),
        ),
      ),
    );
  }

  Widget buildNumKey(List<List<String>> keys, String key) {
    final double screenHeight =
        widget.height?.toDouble() ?? MediaQuery.of(context).size.height;
    final double screenWidth =
        widget.width?.toDouble() ?? MediaQuery.of(context).size.width;

    final double exHeight = 892.0;
    final double exWidth = 412.0;

    double keyWidth = screenWidth * 95.67 / exWidth;
    double keyHeight = getKeyHeight(numKeys);
    double customFontSize = 0.03363228699 * screenHeight;
    EdgeInsets margin = EdgeInsets.all(2);
    Color customColor = Color(0xffE0EAF9);

    if (key == "#?!" || key == "abc" || key == "◂" || key == "▸") {
      keyWidth = screenWidth * 0.2;
      customFontSize = 22.0 / exHeight * screenHeight;
      keyHeight = 42 / exHeight * screenHeight;
    }

    if (key == "◂" || key == "▸") {
      customFontSize = 0.04242152466 * screenHeight;
    }

    if (key == "-" || key == "␣" || key == "←") {
      customColor = Color(0xffD7D9DF);
    } else if (key == "⏎" || key == "◂" || key == "▸") {
      customColor = Color(0xffA6C8FF);
    } else if (key == "#?!") {
      customColor = Color(0xffBDC6DC);
    }

    if (numKeys[numKeys.length - 1].contains(key)) {
      if (numKeys[numKeys.length - 1][0] == key ||
          numKeys[numKeys.length - 1][numKeys[numKeys.length - 1].length - 1] ==
              key) {
        margin = EdgeInsets.symmetric(horizontal: 0, vertical: 2);
      } else {
        margin = EdgeInsets.all(2);
      }
    }

    return GestureDetector(
      onPanDown: (details) => onKeyTap(key, details),
      child: Container(
        width: keyWidth,
        height: keyHeight,
        alignment: Alignment.center,
        margin: margin,
        decoration: BoxDecoration(
          color: customColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          key,
          style: TextStyle(
            fontSize: customFontSize,
            fontWeight: key == "↑" ? FontWeight.bold : FontWeight.normal,
            color: Color(0xff1B1B1D),
          ),
        ),
      ),
    );
  }

  bool isControlKey(String key) {
    return key == "↑" ||
        key == "←" ||
        key == " " ||
        key == "◂" ||
        key == "▸" ||
        key == "123" ||
        key == "#?!" ||
        key == "abc" ||
        key == "1/2" ||
        key == "2/2";
  }

  void insertText(String newText) {
    setState(() {
      // Insert new text at the current cursor position
      text = text.substring(0, cursorPosition) +
          newText +
          text.substring(cursorPosition);
      // Update cursor position
      cursorPosition += newText.length;
      textController.text = text; // Update the text controller
    });
    // Ensure the text field scrolls to the new cursor position
    textController.selection =
        TextSelection.fromPosition(TextPosition(offset: cursorPosition));
  }

  Widget buildFrequentlyUsedSentences() {
    return ListView(
      children: [
        // Existing sentences
        ...sentences.map((sentence) => ListTile(
              title: Text(sentence),
              onTap: () {
                insertText(sentence + " ");
                setState(() {
                  isKeyboardVisible = true;
                  areSentencesVisible = false;
                  isAlphabetKeypad = true;
                });
              },
            )),
        // Plus icon to add a new sentence
        ListTile(
          leading: Icon(Icons.add),
          onTap: () {
            setState(() {
              isAddingSentence = true;
              isKeyboardVisible = true;
              areSentencesVisible = false;
              isAlphabetKeypad = true;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight =
        widget.height?.toDouble() ?? MediaQuery.of(context).size.height;
    final double screenWidth =
        widget.width?.toDouble() ?? MediaQuery.of(context).size.width;

    final double exHeight = 892.0;
    final double exWidth = 412.0;
    final double navBarHeight = screenHeight * 0.065;

    keyboardHeight = isKeyboardVisible ? (screenHeight * 360.0 / exHeight) : 0;

    final textFieldHeight = screenHeight -
        keyboardHeight -
        navBarHeight -
        48; // 48 is the height of the copy button
    return Column(
      children: [
        // Navigation Bar
        Container(
          height: navBarHeight,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize:
                    MainAxisSize.min, // To keep the row size to a minimum
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    iconSize: 28.0,
                    onPressed: () {
                      // Handle navigation to previous page here
                    },
                  ),
                  SizedBox(width: 22),
                  Text(
                    'Keyboard',
                    style: TextStyle(
                      fontSize: 23.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 38),
              TextButton(
                onPressed: () {
                  setState(() {
                    text = '';
                    textController.text = text;
                    textFocusNode.requestFocus();
                  });
                },
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xffBDC6DC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                ),
              ),
              SizedBox(width: 3),
              IconButton(
                icon: Icon(Icons.settings),
                iconSize: 30.0,
                onPressed: () {
                  // Navigate to settings page here
                },
              ),
            ],
          ),
        ),
        Container(
          height: textFieldHeight,
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            controller: textFieldScrollController,
            child: TextField(
              focusNode: textFocusNode,
              controller: textController,
              maxLines: null,
              readOnly: true,
              showCursor: true,
              cursorWidth: 2.0,
              onTap: () {
                setState(() {
                  isKeyboardVisible = true;
                });
                // Prevent the default keyboard from appearing
              },
              style: TextStyle(
                fontSize: 20,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Input Text',
              ),
            ),
          ),
        ),

        // Copy & Export Button
        InkWell(
          onTap: copyAndExport,
          child: Container(
            width: double.infinity,
            height: 48,
            margin: EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(
              color: Color(0xff4285F4),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              isAddingSentence ? "Add sentence" : "Copy",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        // Predicted text + Quick Sentence + Mic
        Container(
          padding: EdgeInsets.symmetric(vertical: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Visibility(
                  visible: !areSentencesVisible,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xff575E71), // Background color
                      borderRadius: BorderRadius.circular(6), // Rounded corners
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      userInputText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 1),
              Expanded(
                child: Visibility(
                  visible: !areSentencesVisible,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xff575E71),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      predictedText2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    areSentencesVisible =
                        !areSentencesVisible; // Toggle the state
                    if (areSentencesVisible) {
                      isKeyboardVisible = true;
                      isNumKeypad = false;
                      isAlphabetKeypad = false;
                      isFirstSpecialKeypad = false;
                      isSecSpecialKeypad = false;
                      buildFrequentlyUsedSentences();
                    } else {
                      isKeyboardVisible = true;
                      isAlphabetKeypad = true;
                      isNumKeypad = false;
                      isFirstSpecialKeypad = false;
                      isSecSpecialKeypad = false;
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: areSentencesVisible
                        ? Color(0xff575E71)
                        : Color(0xffE0EAF9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.menu,
                      color: areSentencesVisible ? Colors.white : Colors.black),
                ),
              ),
              SizedBox(width: 2),
              GestureDetector(
                onTap: () {
                  // Handle mic icon tap
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xffE0EAF9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.mic),
                ),
              ),
            ],
          ),
        ),

        // Frequently Used Sentences List
        if (areSentencesVisible && !isAddingSentence)
          Expanded(
            child: buildFrequentlyUsedSentences(),
          ),

        // Keyboard
        if (isKeyboardVisible && isAlphabetKeypad)
          SizedBox(
              height: keyboardHeight,
              width: double.infinity,
              child: Container(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    bool isLastRow = (index == keys.length - 1) ||
                        (index == keys.length - 2);
                    return Row(
                      mainAxisAlignment: isLastRow
                          ? MainAxisAlignment.spaceEvenly
                          : MainAxisAlignment.center,
                      children: keys[index]
                          .map((key) => buildKey(keys, key))
                          .toList(),
                    );
                  },
                ),
              )),
        if (isKeyboardVisible && isNumKeypad)
          SizedBox(
              height: keyboardHeight,
              width: double.infinity,
              child: Container(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: numKeys.length,
                  itemBuilder: (context, index) {
                    bool isLastRow = (index == numKeys.length - 1);
                    return Row(
                      mainAxisAlignment: isLastRow
                          ? MainAxisAlignment.spaceEvenly
                          : MainAxisAlignment.center,
                      children: numKeys[index]
                          .map((key) => buildNumKey(numKeys, key))
                          .toList(),
                    );
                  },
                ),
              )),
        if (isKeyboardVisible && isFirstSpecialKeypad)
          SizedBox(
              height: keyboardHeight,
              width: double.infinity,
              child: Container(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: firstSpecialKeys.length,
                  itemBuilder: (context, index) {
                    bool isLastRow = (index == firstSpecialKeys.length - 1) ||
                        (index == firstSpecialKeys.length - 2);
                    return Row(
                      mainAxisAlignment: isLastRow
                          ? MainAxisAlignment.spaceEvenly
                          : MainAxisAlignment.center,
                      children: firstSpecialKeys[index]
                          .map((key) => buildSpecialKey(firstSpecialKeys, key))
                          .toList(),
                    );
                  },
                ),
              )),
        if (isKeyboardVisible && isSecSpecialKeypad)
          SizedBox(
              height: keyboardHeight,
              width: double.infinity,
              child: Container(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: secSpecialKeys.length,
                  itemBuilder: (context, index) {
                    bool isLastRow = (index == secSpecialKeys.length - 1) ||
                        (index == secSpecialKeys.length - 2);
                    return Row(
                      mainAxisAlignment: isLastRow
                          ? MainAxisAlignment.spaceEvenly
                          : MainAxisAlignment.center,
                      children: secSpecialKeys[index]
                          .map((key) => buildSpecialKey(secSpecialKeys, key))
                          .toList(),
                    );
                  },
                ),
              )),
      ],
    );
  }

  List<List<String>> keys = [
    ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
    ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
    ["Z", "X", "C", "V", "B", "N", "M"],
    ["↑", " ", ".", "←"],
    ["#?!", "123", "⏎", "◂", "▸"]
  ];
  List<List<String>> numKeys = [
    ["1", "2", "3", "-"],
    ["4", "5", "6", "␣"],
    ["7", "8", "9", "←"],
    [",", "0", ".", "⏎"],
    ["#?!", "abc", "◂", "▸"]
  ];
  List<List<String>> firstSpecialKeys = [
    ["+", "=", "/", "_", "(", ")"],
    ["!", "@", "\$", "%", "^", "*"],
    ["-", "\'", "\"", ",", "?"],
    ["1/2", " ", ".", "←"],
    ["abc", "123", "⏎", "◂", "▸"]
  ];
  List<List<String>> secSpecialKeys = [
    ["~", "\\", "|", "#", "{", "}"],
    ["€", "£", "[", "]", "<", ">"],
    [":", ";", "&", "¡", "¿"],
    ["2/2", " ", ".", "←"],
    ["abc", "123", "⏎", "◂", "▸"]
  ];
}

class KeyPressInfo {
  final Offset position;
  final bool isShiftEnabled;
  final bool isDoubleShiftEnabled;
  final bool isAlphabetKeypad;
  final bool isNumKeypad;
  final bool isFirstSpecialKeypad;
  final bool isSecSpecialKeypad;
  final DateTime timestamp;
  final String key;
  KeyPressInfo({
    required this.position,
    required this.isShiftEnabled,
    required this.isDoubleShiftEnabled,
    required this.isAlphabetKeypad,
    required this.isNumKeypad,
    required this.isFirstSpecialKeypad,
    required this.isSecSpecialKeypad,
    required this.timestamp,
    required this.key,
  });
}

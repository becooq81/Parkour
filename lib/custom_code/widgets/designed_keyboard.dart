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
  bool isShiftEnabled = true;
  bool isDoubleShiftEnabled = false;
  bool isNumKeypad = false;
  TextEditingController textController = TextEditingController();
  bool isKeyboardVisible = false;
  List<KeyPressInfo> coordinates = [];
  ScrollController scrollController = ScrollController();
  ScrollController textFieldScrollController = ScrollController();
  FocusNode textFocusNode = FocusNode();
  int cursorPosition = 0;

  late DateTime lastShiftTap;
  late File keyCoordinatesCSV;
  late File inputCoordinatesCSV;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    scrollController = ScrollController();
    textFieldScrollController = ScrollController();
    isShiftEnabled = false;
    isDoubleShiftEnabled = false;
    lastShiftTap = DateTime.now();
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    textFieldScrollController.dispose();
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

  void copyAndExport() {
    Clipboard.setData(ClipboardData(text: text));
    exportCoordinatesToCSV();
    exportKeyCoordinatesToCSV();
    sendEmailWithCsvs(keyCoordinatesCSV, inputCoordinatesCSV);
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
              DateFormat('yyyy-MM-dd HH:mm:ss')
                  .format(e.timestamp), // Format the timestamp
              e.position.dx,
              e.position.dy,
              (e.isShiftEnabled || isDoubleShiftEnabled)
                  ? 'true'
                  : 'false', // Adjusted logic for isShiftEnabled
              e.isNumKeypad ? 'true' : 'false',
            ])
        .toList();

    final List<List<dynamic>> csvData = [
      ['Timestamp', 'X', 'Y', 'Is Shift Enabled', 'Is Num Keypad'],
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

  void onKeyTap(String key, DragDownDetails details) {
    final position = details.globalPosition;
    Offset relativePosition = getRelativePosition(position);
    if (key == "←") {
      if (text.isNotEmpty && cursorPosition != 0) {
        text = text.substring(0, cursorPosition - 1) +
            text.substring(cursorPosition);
        cursorPosition--;
      }
      coordinates.add(KeyPressInfo(
        position: Offset(100000.0, 100000.0),
        isShiftEnabled: isShiftEnabled,
        isNumKeypad: isNumKeypad,
        timestamp: DateTime.now(),
      ));
    } else if (key == "↑") {
      if (isDoubleShiftEnabled) {
        isDoubleShiftEnabled = false;
        isShiftEnabled = false;
      } else {
        DateTime now = DateTime.now();
        if (now.difference(lastShiftTap).inMilliseconds < 300) {
          // Double tap detected
          isDoubleShiftEnabled = true;
        } else {
          // Single tap or time between taps is too long
          isDoubleShiftEnabled = false;
          isShiftEnabled = !isShiftEnabled;
        }
        lastShiftTap = now;
      }
      coordinates.add(KeyPressInfo(
        position: Offset(200000.0, 200000.0),
        isShiftEnabled: isShiftEnabled,
        isNumKeypad: isNumKeypad,
        timestamp: DateTime.now(),
      ));
    } else if (key == " " || key == "␣") {
      text = text.substring(0, cursorPosition) +
          " " +
          text.substring(cursorPosition);
      cursorPosition++;
      coordinates.add(KeyPressInfo(
        position: Offset(400000.0, 400000.0),
        isShiftEnabled: isShiftEnabled,
        isNumKeypad: isNumKeypad,
        timestamp: DateTime.now(),
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
        isNumKeypad: isNumKeypad,
        timestamp: DateTime.now(),
      ));
    } else if (key == "<") {
      cursorPosition = max(0, cursorPosition - 1);
      coordinates.add(KeyPressInfo(
        position: Offset(500000.0, 500000.0),
        isShiftEnabled: isShiftEnabled,
        isNumKeypad: isNumKeypad,
        timestamp: DateTime.now(),
      ));
    } else if (key == ">") {
      cursorPosition = min(text.length, cursorPosition + 1);
      coordinates.add(KeyPressInfo(
        position: Offset(600000.0, 600000.0),
        isShiftEnabled: isShiftEnabled,
        isNumKeypad: isNumKeypad,
        timestamp: DateTime.now(),
      ));
    } else if (key == "123") {
      isNumKeypad = !isNumKeypad;
      coordinates.add(KeyPressInfo(
        position: Offset(700000.0, 700000.0),
        isShiftEnabled: isShiftEnabled,
        isNumKeypad: isNumKeypad,
        timestamp: DateTime.now(),
      ));
    } else if (key == "abc") {
      isNumKeypad = !isNumKeypad;
      coordinates.add(KeyPressInfo(
        position: Offset(800000.0, 800000.0),
        isShiftEnabled: isShiftEnabled,
        isNumKeypad: isNumKeypad,
        timestamp: DateTime.now(),
      ));
    } else {
      String addText =
          ((isShiftEnabled || isDoubleShiftEnabled) && !isSpecialKey(key))
              ? key.toUpperCase()
              : key.toLowerCase();
      text = text.substring(0, cursorPosition) +
          addText +
          text.substring(cursorPosition);
      cursorPosition++;
      coordinates.add(KeyPressInfo(
        position: relativePosition,
        isShiftEnabled: isShiftEnabled,
        isNumKeypad: isNumKeypad,
        timestamp: DateTime.now(),
      ));
    }

    updateTextAndScroll(text);
    textController.text = text;

    if (isShiftEnabled && !isSpecialKey(key) && (!isDoubleShiftEnabled)) {
      isShiftEnabled = false;
    }
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

    String csv = const ListToCsvConverter().convert(csvData);
    await keyCoordinatesCSV.writeAsString(csv);
  }

  double get keyHeight => isKeyboardVisible
      ? (widget.height ?? MediaQuery.of(context).size.height) *
          0.4 /
          keys.length
      : 0;

  Widget buildKey(String key) {
    int flexFactor = (key == " ") ? 3 : 1;
    return Expanded(
      flex: flexFactor,
      child: GestureDetector(
        onPanDown: (details) => onKeyTap(key, details),
        child: Container(
          height: keyHeight,
          alignment: Alignment.center,
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            color: Colors.grey[200],
          ),
          child: Text(
            (isShiftEnabled || isDoubleShiftEnabled) && !isSpecialKey(key)
                ? key.toUpperCase()
                : key.toLowerCase(),
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget buildNumKey(String key) {
    return Expanded(
      child: GestureDetector(
        onPanDown: (details) => onKeyTap(key, details),
        child: Container(
          height: keyHeight, // Set the height of the key
          alignment: Alignment.center,
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            color: Colors.grey[200],
          ),
          child: Text(
            ((isShiftEnabled || isDoubleShiftEnabled) && !isSpecialKey(key))
                ? key.toUpperCase()
                : key.toLowerCase(),
            style: TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }

  bool isSpecialKey(String key) {
    return key == "↑" ||
        key == "←" ||
        key == " " ||
        key == "<" ||
        key == ">" ||
        key == "123" ||
        key == "*/?" ||
        key == "abc";
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight =
        widget.height?.toDouble() ?? MediaQuery.of(context).size.height;
    final double keyboardHeight = isKeyboardVisible
        ? (screenHeight * 0.45)
        : 0; // Keyboard occupies 50% of screen

    final textFieldHeight = screenHeight -
        keyboardHeight -
        48; // 48 is the height of the copy button
    isShiftEnabled = text.isEmpty;

    return Column(
      children: [
        // Text Field Container
        Container(
          height: textFieldHeight,
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            controller: textFieldScrollController,
            child: TextField(
              controller: textController,
              focusNode: textFocusNode,
              maxLines: null,
              readOnly: true,
              showCursor: true,
              cursorWidth: 2.0,
              onTap: () {
                setState(() {
                  isKeyboardVisible = true;
                });
                // Prevent the default keyboard from appearing
                textFocusNode.canRequestFocus = false;
              },
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
            color: Colors.blue,
            alignment: Alignment.center,
            child: Text(
              "Copy",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),

        // Keyboard
        if (isKeyboardVisible && !isNumKeypad)
          SizedBox(
              height: keyboardHeight,
              width: double.infinity,
              child: Container(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          keys[index].map((key) => buildKey(key)).toList(),
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
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          numKeys[index].map((key) => buildKey(key)).toList(),
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
    ["123", "*/?", "⏎", "<", ">"]
  ];

  List<List<String>> numKeys = [
    ["1", "2", "3", "-"],
    ["4", "5", "6", "␣"],
    ["7", "8", "9", "⏎"],
    ["abc", "*/?", "<", ">"]
  ];
}

class KeyPressInfo {
  final Offset position;
  final bool isShiftEnabled;
  final bool isNumKeypad;
  final DateTime timestamp;

  KeyPressInfo({
    required this.position,
    required this.isShiftEnabled,
    required this.isNumKeypad,
    required this.timestamp,
  });
}

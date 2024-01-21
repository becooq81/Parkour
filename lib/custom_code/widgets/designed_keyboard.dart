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
  bool isShiftEnabled = false;
  bool isNumKeypad = false;
  TextEditingController textController = TextEditingController();
  bool isKeyboardVisible = false;
  List<KeyPressInfo> coordinates = [];
  ScrollController scrollController = ScrollController();
  ScrollController textFieldScrollController = ScrollController();
  FocusNode textFocusNode = FocusNode();
  int cursorPosition = 0;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    scrollController = ScrollController();
    textFieldScrollController = ScrollController();
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
    setState(() {
      isKeyboardVisible = false; // Hide the keyboard
    });
  }

  Future<void> sendEmailWithCsv(File csvFile) async {
    final Email email = Email(
      body: 'Here is your CSV file.',
      subject: 'CSV File',
      recipients: ['gdsc.yonsei.parkour@gmail.com'],
      attachmentPaths: [csvFile.path],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
  }

  void exportCoordinatesToCSV() async {
    // Create a list of lists, where each inner list represents a row in the CSV file
    final List<List<dynamic>> csvData = [
      // Define the headers
      ['X', 'Y', 'Is Shift Enabled', 'Is Num Keypad'],
    ];

    // Add the data from each KeyPressInfo object to the csvData list
    csvData.addAll(coordinates.map((e) => [
          e.position.dx,
          e.position.dy,
          e.isShiftEnabled.toString(),
          e.isNumKeypad.toString(),
        ]));

    // Convert the data to CSV format
    final String csv = const ListToCsvConverter().convert(csvData);

    // Updated path to the project directory
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/coordinates.csv';

    final File file = File(filePath);
    await file.writeAsString(csv);

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    await sendEmailWithCsv(file);
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
      ));
    } else if (key == "↑") {
      isShiftEnabled = !isShiftEnabled;
      coordinates.add(KeyPressInfo(
        position: Offset(200000.0, 200000.0),
        isShiftEnabled: isShiftEnabled,
        isNumKeypad: isNumKeypad,
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
      ));
    } else if (key == "<") {
      cursorPosition = max(0, cursorPosition - 1);
    } else if (key == ">") {
      cursorPosition = min(text.length, cursorPosition + 1);
    } else if (key == "123") {
      isNumKeypad = !isNumKeypad;
    } else if (key == "abc") {
      isNumKeypad = !isNumKeypad;
    } else {
      String addText = isShiftEnabled ? key.toUpperCase() : key.toLowerCase();
      text = text.substring(0, cursorPosition) +
          addText +
          text.substring(cursorPosition);
      cursorPosition++;
      coordinates.add(KeyPressInfo(
        position: relativePosition,
        isShiftEnabled: isShiftEnabled,
        isNumKeypad: isNumKeypad,
      ));
    }

    updateTextAndScroll(text);
    textController.text = text;

    if (isShiftEnabled && !isSpecialKey(key)) {
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
            key,
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
            isShiftEnabled && !isSpecialKey(key)
                ? key.toUpperCase()
                : key.toLowerCase(),
            style: TextStyle(fontSize: 25),
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
        key == "*/?";
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
              readOnly: false,
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

  KeyPressInfo(
      {required this.position,
      required this.isShiftEnabled,
      required this.isNumKeypad});
}

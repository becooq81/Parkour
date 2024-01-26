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
  bool isAlphabetKeypad = true;
  bool isNumKeypad = false;
  bool isFirstSpecialKeypad = false;
  bool isSecSpecialKeypad = false;
  TextEditingController textController = TextEditingController();
  bool isKeyboardVisible = false;
  List<KeyPressInfo> coordinates = [];
  ScrollController scrollController = ScrollController();
  ScrollController textFieldScrollController = ScrollController();
  FocusNode textFocusNode = FocusNode();
  int cursorPosition = 0;

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
        isShiftEnabled = true;
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
      isNumKeypad = true;
      isFirstSpecialKeypad = false;
      isSecSpecialKeypad = false;
      isAlphabetKeypad = false;
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
      isNumKeypad = false;
      isFirstSpecialKeypad = false;
      isSecSpecialKeypad = false;
      isAlphabetKeypad = true;
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
      isNumKeypad = false;
      isFirstSpecialKeypad = true;
      isSecSpecialKeypad = false;
      isAlphabetKeypad = false;
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
      isNumKeypad = false;
      isFirstSpecialKeypad = false;
      isSecSpecialKeypad = true;
      isAlphabetKeypad = false;
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
    updateTextAndScroll(text);
    textController.text = text;
    if (isShiftEnabled && !isControlKey(key) && (!isDoubleShiftEnabled)) {
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
        return 58 / exHeight * screenHeight;
      } else {
        return 42 / exHeight * screenHeight;
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
    } else if (key == "◂" || key == "▸") {
      keyWidth = screenWidth * 45.0 / exWidth;
      customFontSize = screenHeight * 30.0 / exHeight;
    } else if (keys[1].contains(key)) {
      keyWidth = screenWidth * 34.0 / exWidth;
    } else if (keys[2].contains(key)) {
      keyWidth = screenWidth * 37.0 / exWidth;
    }

    return GestureDetector(
      onPanDown: (details) => onKeyTap(key, details),
      child: Container(
        width: keyWidth,
        height: getKeyHeight(keys),
        alignment: Alignment.center,
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Color(0xffE0EAF9),
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
    } else if (key == "◂" || key == "▸") {
      keyWidth = screenWidth * 45.0 / exWidth;
      customFontSize = screenHeight * 30.0 / exHeight;
    }

    return GestureDetector(
      onPanDown: (details) => onKeyTap(key, details),
      child: Container(
        width: keyWidth,
        height: getKeyHeight(keys),
        alignment: Alignment.center,
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Color(0xffE0EAF9),
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
    double customFontSize = 0.03363228699 * screenHeight;
    EdgeInsets margin = EdgeInsets.all(2);

    if (key == "123" ||
        key == "#?!" ||
        key == "abc" ||
        key == "◂" ||
        key == "▸") {
      keyWidth = screenWidth * 0.2;
      customFontSize = 22.0 / exHeight * screenHeight;
    }

    if (key == "◂" || key == "▸") {
      customFontSize = 0.04242152466 * screenHeight;
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
        height: getKeyHeight(keys),
        alignment: Alignment.center,
        margin: margin,
        decoration: BoxDecoration(
          color: Color(0xffE0EAF9),
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

  @override
  Widget build(BuildContext context) {
    final double screenHeight =
        widget.height?.toDouble() ?? MediaQuery.of(context).size.height;
    final double screenWidth =
        widget.width?.toDouble() ?? MediaQuery.of(context).size.width;

    final double exHeight = 892.0;
    final double exWidth = 412.0;
    final double navBarHeight = screenHeight * 0.065;

    keyboardHeight = isKeyboardVisible ? (screenHeight * 350.0 / exHeight) : 0;

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
                  });
                },
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xff4285F4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              "Copy",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
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
                          .map((key) => buildKey(secSpecialKeys, key))
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
    ["7", "8", "9", "⏎"],
    ["abc", "#?!", "◂", "▸"]
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

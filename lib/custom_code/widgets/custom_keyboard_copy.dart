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

class CustomKeyboardCopy extends StatefulWidget {
  const CustomKeyboardCopy(
      {Key? key, required this.height, required this.width})
      : super(key: key);
  final double? height;
  final double? width;
  @override
  _CustomKeyboardState createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboardCopy> {
  String text = "";
  bool isShiftEnabled = false;
  TextEditingController textController = TextEditingController();
  bool isKeyboardVisible = false;
  List<Offset> coordinates = [];
  ScrollController scrollController = ScrollController();
  ScrollController textFieldScrollController = ScrollController();
  late File keyCoordinatesCSV;
  late File inputCoordinatesCSV;

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
    final coordinatesList = coordinates.map((e) => [e.dx, e.dy]).toList();
    final List<List<dynamic>> csvData = [
      ['X', 'Y'],
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
      if (text.isNotEmpty) {
        text = text.substring(0, text.length - 1);
        coordinates.add(Offset(100000.0, 100000.0));
      }
    } else if (key == "↑") {
      isShiftEnabled = !isShiftEnabled;
      coordinates.add(Offset(200000.0, 200000.0));
    } else if (key == " ") {
      text += ' ';
      coordinates.add(Offset(300000.0, 300000.0));
      sendCoordinatesToServer(coordinates);
    } else if (key == "⏎") {
      text += '\n';
      coordinates.add(Offset(400000.0, 400000.0));
    } else {
      text += isShiftEnabled ? key.toUpperCase() : key.toLowerCase();
      coordinates.add(relativePosition);
    }
    updateTextAndScroll(text);
    textController.text = text;
  }

  Future<void> sendCoordinatesToServer(List<Offset> coords) async {
    var url = Uri.parse('http://your-server-url.com/endpoint');
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'coordinates': coords.map((e) => {'x': e.dx, 'y': e.dy}).toList()
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

    // Calculate the width and height of the keyboard
    final double keyboardWidth = MediaQuery.of(context).size.width;
    final double keyboardHeight =
        isKeyboardVisible ? MediaQuery.of(context).size.height * 0.4 : 0;

    // Calculate the width and height of a single key
    double keyWidth = keyboardWidth / keys[rowIndex].length;
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

    // Inverting the Y-axis to follow conventional coordinate system
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
            style: TextStyle(fontSize: 20),
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
    final double screenHeight =
        widget.height?.toDouble() ?? MediaQuery.of(context).size.height;
    final double keyboardHeight = isKeyboardVisible
        ? (screenHeight * 0.4)
        : 0; // Keyboard occupies 40% of screen

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
              maxLines: null,
              readOnly: true,
              onTap: () {
                setState(() {
                  isKeyboardVisible = true;
                });
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
              "Copy & Export",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),

        // Keyboard
        if (isKeyboardVisible)
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
              ))
      ],
    );
  }

  List<List<String>> keys = [
    ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
    ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
    ["↑", "Z", "X", "C", "V", "B", "N", "M", "←"],
    [" ", "⏎"]
  ];
}

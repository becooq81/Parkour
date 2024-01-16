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

  /*void updateTextAndScroll(String newText) {
    setState(() {
      text = newText;
      textController.text = text;
      if (textFieldScrollController.hasClients) {
        final scrollPosition =
            textFieldScrollController.position.maxScrollExtent;
        textFieldScrollController.animateTo(
          scrollPosition,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
  */
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

  /* 
  void exportCoordinatesToCSV() async {
    final coordinatesList = coordinates.map((e) => [e.dx, e.dy]).toList();
    final List<List<dynamic>> csvData = [
      ['X', 'Y'],
      ...coordinatesList,
    ];
    final String csv = const ListToCsvConverter().convert(csvData);
    final String directoryPath =
        (await getApplicationDocumentsDirectory()).path;
    final String filePath = '$directoryPath/coordinates.csv';
    File file = File(filePath);
    await file.writeAsString(csv);
// Notify the user or perform other actions as needed
    print('CSV file exported to: $filePath');
  }
  */
  void exportCoordinatesToCSV() async {
    // Request necessary permissions for external storage (Android)
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
    final coordinatesList = coordinates.map((e) => [e.dx, e.dy]).toList();
    final List<List<dynamic>> csvData = [
      ['X', 'Y'],
      ...coordinatesList,
    ];
    final String csv = const ListToCsvConverter().convert(csvData);
    // Get the appropriate directory
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/coordinates.csv';
    final File file = File(filePath);
    await file.writeAsString(csv);
    // Check if the file exists and notify the user
    if (await file.exists()) {
      Share.shareFiles([filePath], text: 'Your Coordinates CSV File');
    } else {
      print('Failed to create CSV file.');
      // Optionally, show an error message to the user
    }
  }

  void onKeyTap(String key, DragDownDetails details) {
    final position = details.globalPosition;
    Offset relativePosition = getRelativePosition(position);
    coordinates.add(relativePosition);
    if (key == "←") {
      if (text.isNotEmpty) {
        text = text.substring(0, text.length - 1);
      }
    } else if (key == "↑") {
      isShiftEnabled = !isShiftEnabled;
    } else if (key == " ") {
      text += ' ';
      sendCoordinatesToServer(coordinates);
      coordinates.clear();
    } else if (key == "⏎") {
      text += '\n';
    } else {
      text += isShiftEnabled ? key.toUpperCase() : key.toLowerCase();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomMargin = screenHeight * 0.04;
    final double keyboardHeight = isKeyboardVisible
        ? (screenHeight * 0.3) + bottomMargin
        : 0; // Keyboard occupies 40% of screen

    final textFieldHeight = screenHeight -
        keyboardHeight -
        48; // 48 is the height of the copy button

    return Column(
      children: [
        // Text Field Container
        Container(
          height: textFieldHeight,
          width: screenWidth,
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
              height: keyboardHeight - bottomMargin,
              width: screenWidth,
              child: Container(
                margin: EdgeInsets.only(bottom: bottomMargin),
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

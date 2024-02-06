import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:ocrapp/screens/info_page.dart';
import 'package:ocrapp/screens/table_calendar_screen.dart';
import 'package:ocrapp/widgets/event_list.dart';
import 'package:ocrapp/models/event.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  Map<DateTime, List<Event>> events = {};
  // _InfoPageState? _infoPageState;

  @override
  void initState() {
    super.initState();
    _loadFirstRunStatus();
  }

  Future<void> _loadFirstRunStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('firstRun') ?? true;

    if (isFirstRun) {
      // If it's the first run, navigate to InfoPage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => InfoPage()),
      );

      // Set the flag to false to indicate that it's not the first run anymore
      prefs.setBool('firstRun', false);
    }
  }

  Future<void> saveImageLocally(List<int> bytes) async {
    final directory = await getApplicationDocumentsDirectory();

    // Get the current date
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyyMMdd').format(now);

    // Get the number of events for the current date
    final currentEvents = events[now] ?? [];
    final currentNumber = currentEvents.length + 1;

    final imageName = '$formattedDate${currentNumber.toString().padLeft(2, '0')}';

    final file = File('${directory.path}/$imageName.jpg');

    await file.writeAsBytes(bytes);

    events[now] = [
      ...currentEvents,
    ];
  }

  Future<void> _getImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _uploadImageToServer();
      }
    });
  }

  Future<void> _uploadImageToServer() async {
    if (_image == null) return;

    final String serverUrl = 'http://51.20.93.250:5000/';

    try {
      // Get base64 encoding of the image
      String base64Image = base64Encode(_image!.readAsBytesSync());
      // Ensure _infoPageState is not null
      if (true) {
        // 이미지 업로드
        final imageResponse = await http.post(
          Uri.parse(serverUrl + '/perform_ocr'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"image": base64Image,
          }),
        );

        if (imageResponse.statusCode == 200) {
          print("Image uploaded successfully!");
          await saveImageLocally(_image!.readAsBytesSync());
          _image = null;
          print(json.decode(imageResponse.body));
        } else {

          print("Failed to upload image. Status code: ${imageResponse.statusCode}");
        }
      }
    } catch (error) {
      print("Error uploading image and info: $error");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OCR'),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await saveImageLocally(_image!.readAsBytesSync());
              },
              child: Text('Save Image'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _getImageFromCamera();
        },
        child: Icon(
          CupertinoIcons.camera,
          color: Colors.cyan[700],
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0), // Adjust the value to change the button's roundness
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
          notchMargin: 12,
          elevation: 8,
          shape: const CircularNotchedRectangle(),
          color: Colors.cyan[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InfoPage()),
                );
              }, icon: Icon(CupertinoIcons.star)),
              IconButton(onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TableCalendarScreen()),
                );
              }, icon: Icon(CupertinoIcons.calendar)),
            ],
          )
      ),
    );
  }
}
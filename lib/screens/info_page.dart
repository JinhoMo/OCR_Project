import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  bool isMale = true;

  @override
  void initState() {
    super.initState();

    loadUserInfo();
  }

  Future<void> _sendUserInfoToServer() async {
    final String serverUrl = 'http://51.20.93.250:5000/'; // Replace with your actual server URL

    try {
      // Create a map containing user information
      Map<String, dynamic> userInfo = {
        "age": ageController.text,
        "height": heightController.text,
        "weight": weightController.text,
        "gender": isMale ? "m" : "f",
        "pa_level": 1,
        "carb_ratio": 60,
        "protein_ratio": 25,
        "fat_ratio": 15,
      };



      print(jsonEncode(userInfo));
      // Send a POST request to your server
      final response = await http.post(
        Uri.parse('$serverUrl/calculate_status'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userInfo),
      );

      if (response.statusCode == 200) {
        print("User info uploaded successfully!");
        final Map<String, dynamic> data = json.decode(response.body);

        // 여기서 data를 사용하거나 원하는 형태로 파싱할 수 있습니다.
        print('Received data: $data');
      } else {
        print("Failed to upload user info. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error uploading user info: $error");
    }
  }



  Future<void> loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      ageController.text = prefs.getString('age') ?? '';
      heightController.text = prefs.getString('height') ?? '';
      weightController.text = prefs.getString('weight') ?? '';
      isMale = prefs.getBool('gender') ?? true;
    });
  }

  void saveUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('age', ageController.text);
    prefs.setString('height', heightController.text);
    prefs.setString('weight', weightController.text);
    prefs.setBool('gender', isMale);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _sendUserInfoToServer(); // Send user info when pressing the back button
        return true; // Allow back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Info Page'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('성별'),
                  SizedBox(width: 10),
                  Switch(
                    value: isMale,
                    onChanged: (value) {
                      setState(() {
                        isMale = value;
                      });
                    },
                  ),
                  Text(isMale ? '남자' : '여자'),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                '신체 정보',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Text('나이'),
                  SizedBox(width: 10),
                  Container(
                    width: 60,
                    child: TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        saveUserInfo();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('키'),
                  SizedBox(width: 10),
                  Container(
                    width: 60,
                    child: TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        saveUserInfo();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('몸무게'),
                  SizedBox(width: 10),
                  Container(
                    width: 60,
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        saveUserInfo();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }
}
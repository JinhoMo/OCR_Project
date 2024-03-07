import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:ocrapp/models/event.dart';

String savedUrl = 'http://34.168.68.114:5000/';

class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  String gender = 'm';
  int paLevel = 0;
  int purpose = 0;



  @override
  void initState() {
    super.initState();

    loadUserInfo();
  }



  Future<void> _sendUserInfoToServer() async {
    final String serverUrl = savedUrl; // Replace with your actual server URL
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      // Create a map containing user information
      Map<String, dynamic> userInfo = {
        'age': ageController.text,
        'height': heightController.text,
        'weight': weightController.text,
        'gender': gender,
        'pa_level': paLevel,
        'purpose' : purpose,

      };



      print(jsonEncode(userInfo));
      saveUserInfo();

      // Send a POST request to your server
      final response = await http.post(
        Uri.parse('$serverUrl/calculate_status'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userInfo),
      );

      if (response.statusCode == 200) {

        Map<String, dynamic> data = json.decode(response.body);
        print(data);
        // Extracting values from the server response
        String userName = "User1"; // User Nickname
        double bmiValue = data['bmi']['bmi'].toDouble();
        // String bmiResultText = data['bmi']['bmi_result'];

        double recommendedCalories = data['TEE']; //

        double carb_g = data['nutrient_ratio']['Carbohydrate'];
        double protein_g = data['nutrient_ratio']['Protein'];
        double fat_g = data['nutrient_ratio']['Lipide'];

        //todo
        prefs.setDouble('recommendedCalories', recommendedCalories);
        prefs.setDouble('bmi', bmiValue);
        prefs.setDouble('carb_g', carb_g);
        prefs.setDouble('protein_g', protein_g);
        prefs.setDouble('fat_g', fat_g);
      }
      else {
      print(
          "Failed to upload user info. Status code: ${response.statusCode}");
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
      gender = prefs.getString('gender') ?? 'm';
      paLevel = prefs.getInt('pa_level') ?? 0;
      purpose = prefs.getInt('purpose') ?? 1;

    });
  }

  void saveUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('age', ageController.text);
    prefs.setString('height', heightController.text);
    prefs.setString('weight', weightController.text);
    prefs.setString('gender', gender);
    prefs.setInt('pa_level', paLevel);
    prefs.setInt('purpose', purpose);

  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _sendUserInfoToServer(); // Send user info when pressing the back button
        return true; // Allow back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Info Page',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.face),
                  const SizedBox(width: 10),
                  Text('Age', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.vertical_align_top),
                  const SizedBox(width: 10),
                  Text('Height', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.fastfood),
                  const SizedBox(width: 10),
                  Text('Weight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.male),
                  const SizedBox(width: 10),
                  Text('Gender', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Radio(
                          value: 'm',
                          groupValue: gender,
                          onChanged: (value) {
                            setState(() {
                              gender = value.toString();
                            });
                          },
                        ),
                        const Text('Male'),
                        Radio(
                          value: 'f',
                          groupValue: gender,
                          onChanged: (value) {
                            setState(() {
                              gender = value.toString();
                            });
                          },
                        ),
                        const Text('Female'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.directions_bike),
                  const SizedBox(width: 10),
                  Text('일주일 운동횟수', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 10),
                ],
              ),
              Row(
                children: [
                  Radio(
                    value: 0,
                    groupValue: paLevel,
                    onChanged: (value) {
                      setState(() {
                        paLevel = value as int;
                      });
                    },
                  ),
                  const Text('0'),
                  Radio(
                    value: 1,
                    groupValue: paLevel,
                    onChanged: (value) {
                      setState(() {
                        paLevel = value as int;
                      });
                    },
                  ),
                  const Text('1'),
                  Radio(
                    value: 2,
                    groupValue: paLevel,
                    onChanged: (value) {
                      setState(() {
                        paLevel = value as int;
                      });
                    },
                  ),
                  const Text('2'),
                  Radio(
                    value: 3,
                    groupValue: paLevel,
                    onChanged: (value) {
                      setState(() {
                        paLevel = value as int;
                      });
                    },
                  ),
                  const Text('3'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.rocket),
                  const SizedBox(width: 10),
                  Text('목표', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 10),
                ],
              ),
              Row(
                children: [
                  Radio(
                    value: 0,
                    groupValue: purpose,
                    onChanged: (value) {
                      setState(() {
                        purpose = value as int;
                      });
                    },
                  ),
                  const Text('체중유지'),
                  Radio(
                    value: 1,
                    groupValue: purpose,
                    onChanged: (value) {
                      setState(() {
                        purpose = value as int;
                      });
                    },
                  ),
                  const Text('다이어트'),
                  Radio(
                    value: 2,
                    groupValue: purpose,
                    onChanged: (value) {
                      setState(() {
                        purpose = value as int;
                      });
                    },
                  ),
                  const Text('벌크업'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
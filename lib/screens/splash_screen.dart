import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ocrapp/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait for 3 seconds and then navigate to the main screen
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFFCCD7DB), // 주변 배경색 설정
        child: Center(
          child: Image(
            image: AssetImage('assets/logo.jpg'),
            width: 200, // 이미지의 너비 설정
            height: 200, // 이미지의 높이 설정
          ),
        ),
      ),
    );
  }
}
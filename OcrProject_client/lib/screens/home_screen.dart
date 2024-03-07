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
import 'package:ocrapp/models/event.dart';
import 'package:hexcolor/hexcolor.dart';
import 'dart:math' as math;

String savedUrl = 'http://34.168.68.114:5000/';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  Map<DateTime, List<Event>> events = {};
  late Directory directory;


  double todayCalories = 0;
  double recommendedCalories = 0;
  double carb_g = 0;
  double protein_g = 0;
  double fat_g = 0;
  double bmi = 0;
  Map<DateTime, List<Event>> eventsByDate = {};
  double eatenCarb = 0;
  double eatenFat = 0;
  double eatenProtein = 0;
  double curCarb = 0;
  double curFat = 0;
  double curProtein = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFirstRunStatus();
    _loadEvents();
    _getDirectory();
    _loadData();
  }



  _loadEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? eventsMap = prefs.getString('events') != null
        ? jsonDecode(prefs.getString('events')!)
        : null;

    if (eventsMap != null) {
      // Get today's date
      DateTime today = DateTime.now();
      // Format today's date as a string in 'yyyy-MM-dd' format
      DateTime todayString = DateTime(today.year, today.month, today.day);
      String date = todayString.toIso8601String();
      // Check if events exist for today
      if (eventsMap.containsKey(date)) {

        // Get events for today
        List<dynamic> eventsData = eventsMap[date];

        // Initialize variables to store the sum of carb, protein, and fat values
        double totalCarb = 0;
        double totalProtein = 0;
        double totalFat = 0;

        // Iterate through the events for today
        for (dynamic eventJson in eventsData) {
          // Convert each event JSON to an Event object
          Event event = Event.fromJson(eventJson);
          // Add the carb, protein, and fat values of the event to the totals
          totalCarb += event.carbs;
          totalProtein += event.protein;
          totalFat += event.fat;
        }

          totalCarb = double.parse(totalCarb.toStringAsFixed(1));
          totalProtein = double.parse(totalProtein.toStringAsFixed(1));
          totalFat = double.parse(totalFat.toStringAsFixed(1));

        // Update the state variables with the totals for today
        setState(() {
          eatenCarb = totalCarb;
          eatenProtein = totalProtein;
          eatenFat = totalFat;
          todayCalories = totalCarb * 4 + totalProtein * 4 + totalFat * 9;
        });

        print(eatenCarb);
        print(eatenProtein);
        print(eatenFat);
      }
    }
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      recommendedCalories = prefs.getDouble('recommendedCalories') ?? 0;
      carb_g = prefs.getDouble('carb_g') ?? 0;
      bmi = prefs.getDouble('bmi') ?? 0;
      protein_g = prefs.getDouble('protein_g') ?? 0;
      fat_g = prefs.getDouble('fat_g') ?? 0;
    });

  }

  Future<void> _getDirectory() async {
    directory = await getApplicationDocumentsDirectory();
    setState(() {}); // Rebuild the widget after getting the directory
  }

  // 첫 접속일 때
  Future<void> _loadFirstRunStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('firstRun') ?? true;

    if (isFirstRun) {
      // If it's the first run, navigate to InfoPage
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => InfoPage()),
      );
      _loadData();
      // Set the flag to false to indicate that it's not the first run anymore
      prefs.setBool('firstRun', false);
    }
  }

  Future<void> saveImageLocally(List<int> bytes) async {
    final directory = await getApplicationDocumentsDirectory();

    // Get the current date
    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    final formattedDate = DateFormat('yyyyMMdd').format(now);

    // Get the number of events for the current date
    final currentEvents = events[now] ?? [];
    final currentNumber = currentEvents.length + 1;

    final imageName = '$formattedDate${currentNumber.toString().padLeft(2, '0')}';

    final file = File('${directory.path}/$imageName.jpg');

    await file.writeAsBytes(bytes);

    _showAddEventDialog(nowDate, imageName);

  }

  _showAddEventDialog(DateTime date, final imageName) async {
    Event selectedEvent = Event(
        image: imageName,
        number: eventsByDate[date]?.length ?? 0 + 1,
        carbs: curCarb,
        fat: curFat,
        protein: curProtein
    );


    TextEditingController carbsController = TextEditingController(text: selectedEvent.carbs.toString());
    TextEditingController proteinController = TextEditingController(text: selectedEvent.protein.toString());
    TextEditingController fatController = TextEditingController(text: selectedEvent.fat.toString());

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New Event"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: carbsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Carbs"),
                ),
                TextField(
                  controller: proteinController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Protein"),
                ),
                TextField(
                  controller: fatController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Fat"),
                ),
                Container(
                  width: 150,
                  height: 150,
                  margin: EdgeInsets.all(8.0),
                  color: Colors.grey,
                  child: selectedEvent.image != null && selectedEvent.image.isNotEmpty
                      ? Image.file(
                    File('${directory.path}/${selectedEvent.image}.jpg'), // Assuming image file extension is jpg
                    fit: BoxFit.cover,
                  )
                      : Center(
                    child: Text(
                      'No Image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Update the selected event with the new values
                selectedEvent.carbs = double.parse(carbsController.text);
                selectedEvent.protein = double.parse(proteinController.text);
                selectedEvent.fat = double.parse(fatController.text);

                _addEvent(date, selectedEvent);

                Navigator.of(context).pop();
              },
              child: Text("Save"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              // style: ElevatedButton.styleFrom(primary: Colors.red), // Red color for delete button
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  _saveEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> eventsMap = {};
    eventsByDate.forEach((date, events) {
      eventsMap[date.toIso8601String()] = events.map((event) => event.toJson()).toList();
    });

    prefs.setString('events', jsonEncode(eventsMap));
    _loadEvents();
  }

  _addEvent(DateTime date, Event event) {

    setState(() {
      if (!eventsByDate.containsKey(date)) {
        eventsByDate[date] = [];
      }

      print(1);

      // Check if there are events on the same date
      List<Event> eventsOnDate = eventsByDate[date]!;
      if (eventsOnDate.isNotEmpty) {
        // Find the maximum event number on the same date
        int maxEventNumber = eventsOnDate.map((e) => e.number).reduce((value, element) => value > element ? value : element);

        // Set the event number to the next sequential number
        event.number = maxEventNumber + 1;
      }
      if (eventsOnDate.any((e) => e.image == event.image)) {
        return; // Event already exists, do not add
      }
      else {
        eventsByDate[date]!.add(event);
      }

    });

    print(eventsByDate);
    _saveEvents();
  }

  Future<void> _getImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) {
      return; // 이미지를 선택하지 않은 경우 함수 종료
    }

    Directory appDirectory = await getApplicationDocumentsDirectory();
    File newImage = File('${appDirectory.path}/image');
    newImage.writeAsBytesSync(await pickedFile.readAsBytes()); // 파일 저장 방법 변경

    setState(() {
      _image = newImage;
      _uploadImageToServer();
    });
  }

  Future<void> _uploadImageToServer() async {


    if (_image == null) return;

    final String serverUrl = savedUrl;

    try {
      // Get base64 encoding of the image
      String base64Image = base64Encode(_image!.readAsBytesSync());
      if (true) {
        // 이미지 업로드
        setState(() {
          _loading = true;
        });
        final imageResponse = await http.post(
          Uri.parse(serverUrl + '/perform_ocr'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"image": base64Image,
          }),
        );
        print(imageResponse.body);
        if (imageResponse.statusCode == 200) {
          print("Image uploaded successfully!");
          Map<String, dynamic> data = json.decode(imageResponse.body);
          print(data);
          if(data["erro"] == 0) {
            curCarb = double.tryParse(data["탄수화물"].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
            curFat = double.tryParse(data["지방"].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
            curProtein= double.tryParse(data["단백질"].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          } else {
            curCarb = 0.0;
            curFat = 0.0;
            curProtein= 0.0;
          }



          await saveImageLocally(_image!.readAsBytesSync());
          _image = null;

        } else {
          print("Failed to upload image. Status code: ${imageResponse.statusCode}");
        }
      }
    } catch (error) {
      print("Error uploading image and info: $error");
    }
    setState(() {
      _loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {

    double leftCalories = recommendedCalories - todayCalories;
    double caloriesRatio = (todayCalories / recommendedCalories) * 360;

    List<BMIResult> results = [
      calculateBMIResult(0),
      calculateBMIResult(18.5),
      calculateBMIResult(23),
      calculateBMIResult(25),
      calculateBMIResult(30),
    ];

    DateTime today = DateTime.now();
    // Format today's date as a string in 'yyyy-MM-dd' format
    DateTime todayString = DateTime(today.year, today.month, today.day);
    String date = todayString.toIso8601String().substring(0, 10);

    return Scaffold(
        appBar: _loading
            ? AppBar( // 로딩 중일 때 AppBar 보여주기
          backgroundColor: Colors.black.withOpacity(0.8), // 배경색 설정
          title: Text(
            'Result of ' + date,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Color(0xFF707070)),
          ),
        )
            : AppBar( // 로딩 중이 아닐 때 AppBar 보여주기
          title: Text(
            'Result of ' + date,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ),
        body: Stack(
                children: [
          SingleChildScrollView(
              child:Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 칼로리 파트
                    Text(
                      'Calories',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10, bottom: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                'Recommended:',
                                style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF213333).withOpacity(0.8),
                                ),
                              ),

                              Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(width: 10),
                                    Text(
                                      '$recommendedCalories',
                                      style: TextStyle(fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2633C5).withOpacity(0.8),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'kcal',
                                      style: TextStyle(fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF213333).withOpacity(0.5),
                                      ),
                                    ),
                                  ]
                              ), // padding , center

                              Text(
                                'Today:',
                                style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF213333).withOpacity(0.8),
                                ),
                              ),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(width: 10),
                                    Text(
                                      '$todayCalories',
                                      style: TextStyle(fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2633C5).withOpacity(0.8),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'kcal',
                                      style: TextStyle(fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF213333).withOpacity(0.5),
                                      ),
                                    ),
                                  ]
                              ), // padding , center


                            ],
                          ),
                        ),

                        //원형 그래프 & 잔여 칼로리

                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(100.0),
                                      ),
                                      border: new Border.all(
                                          width: 4,
                                          color: Color(0xFF2633C5)
                                              .withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          '$leftCalories',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(

                                            fontWeight: FontWeight.normal,
                                            fontSize: 24,
                                            letterSpacing: 0.0,
                                            color: Color(0xFF2633C5),
                                          ),
                                        ),
                                        Text(
                                          'Kcal left',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            letterSpacing: 0.0,
                                            color: Color(0xFF3A5160)
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: CustomPaint(
                                    painter: CurvePainter(
                                        colors: [
                                          Color(0xFF2633C5),
                                          HexColor("#8A98E8"),
                                          HexColor("#8A98E8")
                                        ],
                                        angle: caloriesRatio),
                                    child: SizedBox(
                                      width: 108,
                                      height: 108,
                                    ),
                                  ),

                                ),

                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 20),
                    // 영양소 파트
                    Text(
                      'Nutrients',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    _buildNutrientBar('Carbohydrate', '#5b53f5', carb_g, eatenCarb),
                    _buildNutrientBar('Protein', '#9b96fa', protein_g, eatenProtein),
                    _buildNutrientBar('Fat', '#5b53f5', fat_g, eatenFat),
                    SizedBox(height: 20),

                    // BMI 파트
                    Text(
                      'BMI',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 10, bottom: 3),
                      // child: Text(
                      //     'BMI: ${widget.bmi}',
                      //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color:Color(0xFF213333).withOpacity(0.8)),
                      // ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Row(
                              children: [
                                Text('BMI 결과: ${bmi}',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Color(0xFF213333).withOpacity(0.8),
                                      fontWeight: FontWeight.bold),),
                                SizedBox(width: 15),
                                Text(
                                  '${calculateBMIResult(bmi).result}',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: calculateBMIResult(bmi).color),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: results.map((result) {
                                return _buildBar(result);
                              }).toList(),
                            ),

                          ], //children
                        ),
                      ),
                    ),
                  ],
                ),
              ),



            ),
            if (_loading) // 로딩 중이면 화면 전체를 덮는 흑색 배경과 로딩 인디케이터 표시
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ]
        ),
        floatingActionButton: _loading
            ? null // 로딩 중일 때는 BottomNavigationBar 숨김
            : FloatingActionButton(
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
        bottomNavigationBar: _loading
            ? null // 로딩 중일 때는 BottomNavigationBar 숨김
            : BottomAppBar(
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
                  ).then((value) {
                    _loadData(); // InfoPage가 닫힌 후에 _loadData()를 호출합니다.
                  });
                }, icon: Icon(CupertinoIcons.star)),
                IconButton(onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TableCalendarScreen()),
                  ).then((value) {
                    // 캘린더 창이 닫히고 나서 이벤트를 로드합니다.
                    _loadEvents();
                  });
                }, icon: Icon(CupertinoIcons.calendar)),
              ],
            )
        ),

      );
  }


  //영양성분
  Widget _buildNutrientBar(String nutrient, String color, double total, double current) {
    double ratio = (current / total) * 100;
    if (current == 0) {
      ratio = 0;
    }

    return Column(
      children: [
        Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 3),
            ),
            Container(
              width: 100,
              height: 20,
              child: Text(
                '$nutrient',
                style: TextStyle(
                  color: HexColor(color),
                  fontSize: 16,
                  letterSpacing: -0.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: HexColor('#8A98E8').withOpacity(0.2),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 1.5 * ratio,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            HexColor(color).withOpacity(0.4),
                            HexColor(color),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: HexColor(color),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 0,
                    child: Text(
                      '$current g / $total g',
                      style: TextStyle(
                        color: Color(0x000000).withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildBar(BMIResult result) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            width: 200,
            child: Stack(
              children: [
                Positioned(
                  left: 5,
                  top: 0, // 왼쪽 아래에 배치
                  child: Text(
                    result.limit,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
                Positioned(
                  top: 20,
                  child: Container(
                    height: 10,
                    width: 200 * (bmi / 35), // 최대 BMI를 기준으로 계산
                    color: result.color,
                  ),
                ),
                Positioned(
                  left: 5,
                  bottom: 5,
                  child: Text(
                    result.result,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}


// 원형 그래프
class CurvePainter extends CustomPainter {
  final double? angle;
  final List<Color>? colors;

  CurvePainter({this.colors, this.angle = 140});

  @override
  void paint(Canvas canvas, Size size) {
    List<Color> colorsList = [];
    if (colors != null) {
      colorsList = colors ?? [];
    } else {
      colorsList.addAll([Colors.white, Colors.white]);
    }

    final shdowPaint = new Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    final shdowPaintCenter = new Offset(size.width / 2, size.height / 2);
    final shdowPaintRadius =
        math.min(size.width / 2, size.height / 2) - (14 / 2);
    canvas.drawArc(
        new Rect.fromCircle(center: shdowPaintCenter, radius: shdowPaintRadius),
        degreeToRadians(278),
        degreeToRadians(360 - (365 - angle!)),
        false,
        shdowPaint);

    shdowPaint.color = Colors.grey.withOpacity(0.3);
    shdowPaint.strokeWidth = 16;
    canvas.drawArc(
        new Rect.fromCircle(center: shdowPaintCenter, radius: shdowPaintRadius),
        degreeToRadians(278),
        degreeToRadians(360 - (365 - angle!)),
        false,
        shdowPaint);

    shdowPaint.color = Colors.grey.withOpacity(0.2);
    shdowPaint.strokeWidth = 20;
    canvas.drawArc(
        new Rect.fromCircle(center: shdowPaintCenter, radius: shdowPaintRadius),
        degreeToRadians(278),
        degreeToRadians(360 - (365 - angle!)),
        false,
        shdowPaint);

    shdowPaint.color = Colors.grey.withOpacity(0.1);
    shdowPaint.strokeWidth = 22;
    canvas.drawArc(
        new Rect.fromCircle(center: shdowPaintCenter, radius: shdowPaintRadius),
        degreeToRadians(278),
        degreeToRadians(360 - (365 - angle!)),
        false,
        shdowPaint);

    final rect = new Rect.fromLTWH(0.0, 0.0, size.width, size.width);
    final gradient = new SweepGradient(
      startAngle: degreeToRadians(268),
      endAngle: degreeToRadians(270.0 + 360),
      tileMode: TileMode.repeated,
      colors: colorsList,
    );
    final paint = new Paint()
      ..shader = gradient.createShader(rect)
      ..strokeCap = StrokeCap.round // StrokeCap.round is not recommended.
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    final center = new Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - (14 / 2);

    canvas.drawArc(
        new Rect.fromCircle(center: center, radius: radius),
        degreeToRadians(278),
        degreeToRadians(360 - (365 - angle!)),
        false,
        paint);

    final gradient1 = new SweepGradient(
      tileMode: TileMode.repeated,
      colors: [Colors.white, Colors.white],
    );

    var cPaint = new Paint();
    cPaint..shader = gradient1.createShader(rect);
    cPaint..color = Colors.white;
    cPaint..strokeWidth = 14 / 2;
    canvas.save();

    final centerToCircle = size.width / 2;
    canvas.save();

    canvas.translate(centerToCircle, centerToCircle);
    canvas.rotate(degreeToRadians(angle! + 2));

    canvas.save();
    canvas.translate(0.0, -centerToCircle + 14 / 2);
    canvas.drawCircle(new Offset(0, 0), 14 / 5, cPaint);

    canvas.restore();
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  double degreeToRadians(double degree) {
    var redian = (math.pi / 180) * degree;
    return redian;
  }
}

// BMI
class BMIResult {
  final String result;
  final Color color;
  final String limit;

  BMIResult({required this.result, required this.color, required this.limit});
}

BMIResult calculateBMIResult(double bmi) {
  if (bmi >= 30) {
    return BMIResult(
        result: "고도비만", color: HexColor("CC5324"), limit: "30");
  } else if (bmi >= 25) {
    return BMIResult(
        result: "비만", color: HexColor("D1721E"), limit: "20");
  } else if (bmi >= 23) {
    return BMIResult(result: "과체중", color: HexColor("D5A60E"), limit: "23");
  } else if (bmi >= 18.5) {
    return BMIResult(result: "정상", color: HexColor("83B20C"), limit: "18.5");
  } else {
    return BMIResult(
        result: "저체중", color: HexColor("34B8BD"), limit: "0");
  }
}

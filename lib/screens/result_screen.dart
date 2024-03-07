import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;




class ResultScreen extends StatefulWidget {
  final String userName;
  final double todayCalories;
  final double recommendedCalories;


  final double carb_g;
  final double protein_g;
  final double fat_g;
  final double bmi;


  ResultScreen({
    required this.userName,
    required this.todayCalories,
    required this.recommendedCalories,

    required this.carb_g,
    required this.protein_g,
    required this.fat_g,
    required this.bmi,
  });


  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late String userName;
  late double todayCalories;
  late double recommendedCalories;
  late double carb_g;
  late double protein_g;
  late double fat_g;
  late double bmi;

  @override
  void initState() {
    super.initState();
    userName = widget.userName;
    todayCalories = widget.todayCalories;
    recommendedCalories = widget.recommendedCalories;
    carb_g = widget.carb_g;
    protein_g = widget.protein_g;
    fat_g = widget.fat_g;
    bmi = widget.bmi;
  }

  @override
  Widget build(BuildContext context) {
    double leftCalories = recommendedCalories - todayCalories;
    double caloriesRatio = (todayCalories / recommendedCalories) * 360;
    double eatenCarb = 120;
    double eatenFat = 45;
    double eatenProtein = 40;


    List<BMIResult> results = [
      calculateBMIResult(0),
      calculateBMIResult(18.5),
      calculateBMIResult(23),
      calculateBMIResult(25),
      calculateBMIResult(30),
    ];


    // Result UI
    return Scaffold(
        appBar: AppBar(
          title: Text('결과'),
        ),
        body:SingleChildScrollView(
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
                _buildNutrientBar('Carbohydrate', '#87A0E5', carb_g, eatenCarb),
                _buildNutrientBar('Protein', '#F56E98', protein_g, eatenProtein),
                _buildNutrientBar('Fat', '#F1B440', fat_g, eatenFat),
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
                            Text('BMI 결과: ${widget.bmi}',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF213333).withOpacity(0.8),
                                  fontWeight: FontWeight.bold),),
                            SizedBox(width: 15),
                            Text(
                              '${calculateBMIResult(widget.bmi).result}',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: calculateBMIResult(widget.bmi).color),
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



        )

    );
  }


  //영양성분
  Widget _buildNutrientBar(String nutrient, String color, double total,
      double current) {
    double ratio = (current / total) * 100;
    if (current == 0) {
      ratio = 0;
    }

    return Column(
      children: [
        Row(
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.only(
                    left: 10, bottom: 3)),
            Container(
              width: 100,
              height: 20,
              child: Text('$nutrient',
                style: TextStyle(
                    color: HexColor(color),
                    fontSize: 16,
                    letterSpacing: -0.2,
                    fontWeight: FontWeight.w500
                ),
              ),

            ),


            SizedBox(width: 10),

            Positioned(
                left: 100,
                child: Container( // bar background
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: HexColor('#7D7D7DFF').withOpacity(0.2),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: 1.5 * ratio,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            HexColor(color).withOpacity(0.4), HexColor(color),
                          ]),
                          borderRadius: BorderRadius.circular(10),
                          color: HexColor(color),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 0,
                        child: Text(
                            '$current g / $total g',
                            style: TextStyle(color: Color(0xFF3A5160)
                                .withOpacity(0.5),
                                fontWeight: FontWeight.w600,
                                fontSize: 12
                            )),
                      ),
                    ],
                  ),
                ))


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
                  left:5,
                  child: Text(
                      result.limit,style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)
                  ),
                ),
                Positioned(
                  top: 20,
                  child:
                  Container(
                    height: 10,
                    width: 200 * (bmi / 35), // 최대 BMI를 기준으로 계산
                    color: result.color,
                  ),),

                Positioned(

                  bottom:5,

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
        result: "고도비만", color: HexColor("b81414"), limit: "30");
  } else if (bmi >= 25) {
    return BMIResult(
        result: "비만", color: Colors.deepOrange, limit: "20");
  } else if (bmi >= 23) {
    return BMIResult(result: "과체중", color: Colors.orange, limit: "23");
  } else if (bmi >= 18.5) {
    return BMIResult(result: "정상", color: Colors.green, limit: "18.5");
  } else {
    return BMIResult(
        result: "저체중", color: Colors.lightBlue, limit: "0");
  }
}
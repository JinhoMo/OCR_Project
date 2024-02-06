import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class Event {
  String image;
  int number;
  double carbs;
  double protein;
  double fat;

  Event({
    required this.image,
    required this.number,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      image: json['image'] ?? "",
      number: json['number'] ?? 0,
      carbs: json['carbs'] ?? 0.0,
      protein: json['protein'] ?? 0.0,
      fat: json['fat'] ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'number': number,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
    };
  }
}
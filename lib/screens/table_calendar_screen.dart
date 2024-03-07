import 'package:flutter/material.dart';
import 'package:ocrapp/models/event.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TableCalendarScreen extends StatefulWidget {
  const TableCalendarScreen({Key? key}) : super(key: key);

  @override
  State<TableCalendarScreen> createState() => _TableCalendarScreenState();
}

class _TableCalendarScreenState extends State<TableCalendarScreen> {
  Map<DateTime, List<Event>> eventsByDate = {};
  DateTime? selectedDay, focusedDay;
  late Directory directory;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _getDirectory();
  }

  _loadEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? eventsMap = prefs.getString('events') != null
        ? jsonDecode(prefs.getString('events')!)
        : null;
    print(eventsMap);
    if (eventsMap != null) {
      eventsMap.forEach((dateString, eventsData) {
        DateTime date = DateTime.parse(dateString);
        List<Event> events = (eventsData as List)
            .map((eventJson) => Event.fromJson(eventJson))
            .toList();
        setState(() {
          eventsByDate[date] = events;
        });
      });
    }
  }

  _saveEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> eventsMap = {};

    eventsByDate.forEach((date, events) {
      eventsMap[date.toIso8601String()] = events.map((event) => event.toJson()).toList();
    });

    prefs.setString('events', jsonEncode(eventsMap));
  }

  _addEvent(DateTime date, Event event) {
    setState(() {
      if (!eventsByDate.containsKey(date)) {
        eventsByDate[date] = [];
      }

      // Check if there are events on the same date
      List<Event> eventsOnDate = eventsByDate[date]!;
      if (eventsOnDate.isNotEmpty) {
        // Find the maximum event number on the same date
        int maxEventNumber = eventsOnDate.map((e) => e.number).reduce((value, element) => value > element ? value : element);

        // Set the event number to the next sequential number
        event.number = maxEventNumber + 1;
      }

      eventsByDate[date]!.add(event);
      print(eventsByDate);
    });
    _saveEvents();
  }

  _editEvent(DateTime date, int index, Event event) {
    setState(() {
      eventsByDate[date]![index] = event;
    });
    _saveEvents();
  }

  _deleteEvent(DateTime date, int index) {
    setState(() {
      eventsByDate[date]!.removeAt(index);
    });
    _saveEvents();
  }

  _showEditEventDialog(DateTime date, int index) async {
    Event selectedEvent;
    selectedEvent = eventsByDate[date]![index];

    TextEditingController carbsController = TextEditingController(text: selectedEvent.carbs.toString());
    TextEditingController proteinController = TextEditingController(text: selectedEvent.protein.toString());
    TextEditingController fatController = TextEditingController(text: selectedEvent.fat.toString());

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Event"),
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
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Update the selected event with the new values
                selectedEvent.carbs = double.parse(carbsController.text);
                selectedEvent.protein = double.parse(proteinController.text);
                selectedEvent.fat = double.parse(fatController.text);

                _editEvent(date, index, selectedEvent);

                Navigator.of(context).pop();
              },
              child: Text("Save"),
            ),
            ElevatedButton(
              onPressed: () {
                // Delete the selected event
                _deleteEvent(date, index);

                Navigator.of(context).pop();
              },
              // style: ElevatedButton.styleFrom(primary: Colors.red), // Red color for delete button
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }


  Future<void> _getDirectory() async {
    directory = await getApplicationDocumentsDirectory();
    setState(() {}); // Rebuild the widget after getting the directory
  }

  int _getEventCount(DateTime date) {
    if (eventsByDate.containsKey(date)) {
      return eventsByDate[date]!.length;
    } else {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          TableCalendar(
            //... other properties
            firstDay: DateTime.utc(2021, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: DateTime.now(),
            headerStyle: HeaderStyle(
            formatButtonVisible: false,
          ),
            calendarStyle: CalendarStyle(
              markerSize: 8.0,
              markerDecoration: BoxDecoration(
                color: Colors.red[400],
                shape: BoxShape.circle,
              ),
              markerMargin: EdgeInsets.symmetric(horizontal: 1.0),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final eventCount = _getEventCount(date);
                if (eventCount > 0) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      '$eventCount', // 이벤트 개수를 표시
                      style: TextStyle(color: Colors.blue), // 적절한 스타일 적용
                    ),
                  );
                } else {
                  return Container(); // 이벤트 개수가 0이면 아무것도 반환하지 않음
                }
              },
            ),
            onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
              setState(() {
                this.selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                this.focusedDay = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
              });
            },
            selectedDayPredicate: (DateTime day) {
              return isSameDay(day, selectedDay ?? DateTime.now());
            },
          ),
          SizedBox(height: 16),
          _buildEventList(),
        ],
      ),

    );
  }

  Widget _buildEventList() {
    if (selectedDay != null && eventsByDate.containsKey(selectedDay)) {
      List<Event> events = eventsByDate[selectedDay] ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(8.0),
            child: Text(
              DateFormat('yyyy-MM-dd').format(selectedDay!), // Format the selected date as the title
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: events.map((event) {
                return GestureDetector(
                  onTap: () {
                    _showEditEventDialog(selectedDay!, events.indexOf(event));
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: EdgeInsets.all(8.0),
                    color: Colors.grey,
                    child: event.image != null && event.image.isNotEmpty
                        ? Image.file(
                      File('${directory.path}/${event.image}.jpg'), // Assuming image file extension is jpg
                      fit: BoxFit.cover,
                    )
                        : Center(
                      child: Text(
                        'Event ${events.indexOf(event) + 1}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    } else {
      return Container();
    }
  }
}

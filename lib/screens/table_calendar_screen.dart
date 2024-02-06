import 'package:flutter/material.dart';
import 'package:ocrapp/models/event.dart';
import 'package:ocrapp/widgets/event_list.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TableCalendarScreen extends StatefulWidget {
  const TableCalendarScreen({Key? key}) : super(key: key);

  @override
  State<TableCalendarScreen> createState() => _TableCalendarScreenState();
}


class _TableCalendarScreenState extends State<TableCalendarScreen> {
  Map<DateTime, List<Event>> eventsByDate = {};
  DateTime? selectedDay, focusedDay;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  _loadEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? eventsMap = prefs.getString('events') != null
        ? jsonDecode(prefs.getString('events')!)
        : null;

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
    Event selectedEvent = eventsByDate[date]![index];

    TextEditingController carbsController = TextEditingController(text: selectedEvent.carbs.toString());
    TextEditingController proteinController = TextEditingController(text: selectedEvent.protein.toString());
    TextEditingController fatController = TextEditingController(text: selectedEvent.fat.toString());

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Event"),
          content: Column(
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
            ],
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

                // Update the events list and save
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
              style: ElevatedButton.styleFrom(primary: Colors.red), // Red color for delete button
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  _showAddEventDialog(DateTime date) async {
    Event newEvent = Event(image: "", number: eventsByDate[date]?.length ?? 0 + 1, carbs: 0.0, protein: 0.0, fat: 0.0);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Event"),
          content: Column(
            children: [
              // Add UI components for event data input
              // (e.g., image, number, carbs, protein, fat)
            ],
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
                _addEvent(date, newEvent);
                Navigator.of(context).pop();
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
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
            onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
              setState(() {
                this.selectedDay = selectedDay;
                this.focusedDay = focusedDay;
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          DateTime currentDate = DateTime.now();
          DateTime dateOnly = DateTime(currentDate.year, currentDate.month, currentDate.day);
          _showAddEventDialog(dateOnly);
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEventList() {
    if (selectedDay != null && eventsByDate.containsKey(selectedDay)) {
      List<Event> events = eventsByDate[selectedDay] ?? [];

      return Expanded(
        child: ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            Event event = events[index];

            return ListTile(
              title: Text("Event ${index + 1}"),
              onTap: () {
                _showEditEventDialog(selectedDay!, index);
              },
            );
          },
        ),
      );
    } else {
      return Container();
    }
  }
}
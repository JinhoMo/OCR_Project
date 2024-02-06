import 'package:flutter/material.dart';
import 'package:ocrapp/models/event.dart';
import 'dart:typed_data';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final VoidCallback onEventDeleted;

  EventDetailScreen({required this.event, required this.onEventDeleted});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  TextEditingController _carbohydratesController = TextEditingController();
  TextEditingController _proteinController = TextEditingController();
  TextEditingController _fatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNutrientInfo();
  }

  void _loadNutrientInfo() {
    // Load nutrient information into controllers
    _carbohydratesController.text =
        widget.event.nutrients['carbohydrates']?.toString() ?? '';
    _proteinController.text = widget.event.nutrients['protein']?.toString() ?? '';
    _fatController.text = widget.event.nutrients['fat']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Detail'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildEventImage(),
          SizedBox(height: 16),
          _buildNutrientInfo(),
        ],
      ),
    );
  }

  Widget _buildEventImage() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.grey[300],
      ),
      child: widget.event.imageBytes != null
          ? Image.memory(Uint8List.fromList(widget.event.imageBytes!))
          : Center(child: Text('No Image')),
    );
  }

  Widget _buildNutrientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nutrient Information:'),
        SizedBox(height: 8),
        _buildNutrientField(
          label: 'Carbohydrates',
          controller: _carbohydratesController,
        ),
        _buildNutrientField(
          label: 'Protein',
          controller: _proteinController,
        ),
        _buildNutrientField(
          label: 'Fat',
          controller: _fatController,
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: _deleteEvent,
              child: Text('Delete'),
            ),
            ElevatedButton(
              onPressed: _updateEvent,
              child: Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutrientField({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Text('$label:'),
        SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  void _deleteEvent() async {
    await LocalStorage.deleteEvent(widget.event.index);
    widget.onEventDeleted(); // Reload events
    Navigator.pop(context); // Navigate back
  }

  void _updateEvent() async {
    // Implement updating event
    Event updatedEvent = Event(
      index: widget.event.index,
      imageName: widget.event.imageName,
      nutrients: {
        'carbohydrates': double.parse(_carbohydratesController.text),
        'protein': double.parse(_proteinController.text),
        'fat': double.parse(_fatController.text),
      },
      imageBytes: widget.event.imageBytes,
    );

    await LocalStorage.updateEvent(updatedEvent);
    widget.onEventDeleted(); // Reload events
    Navigator.pop(context); // Navigate back
  }
}

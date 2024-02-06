// import 'package:flutter/material.dart';
// import 'package:ocrapp/models/event.dart';
// import 'package:ocrapp/screens/image_detail_screen.dart';
// import 'dart:convert';
// import 'dart:typed_data';
//
// class EventListItem extends StatelessWidget {
//   final Event event;
//   final DateTime selectedDay;
//   const EventListItem({required this.selectedDay, required this.event});
//
//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Text("1"),
//       leading: _buildEventImage(event),
//       trailing: IconButton(
//         icon: Icon(Icons.delete),
//         onPressed: () {
//           // Show a confirmation dialog before deleting
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: Text("Delete Event"),
//                 content: Text("Are you sure you want to delete this event?"),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: Text("Cancel"),
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       // deleteEvent(selectedDay, event);
//                       Navigator.pop(context);
//                     },
//                     child: Text("Delete"),
//                   ),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildEventImage(Event event) {
//     return Container(
//       width: 80, // Adjust the size as needed
//       height: 80,
//       decoration: BoxDecoration(
//         shape: BoxShape.rectangle,
//         color: Colors.grey[300], // Placeholder color
//       ),
//       child: event.imageBytes != null
//           ? Image.memory(Uint8List.fromList(event.imageBytes!))
//           : Center(child: Text('No Image')),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:ocrapp/models/event.dart';
// import 'package:ocrapp/widgets/event_list_item.dart';
// import 'package:intl/intl.dart';
//
// // class EventList extends StatelessWidget {
// //   final DateTime selectedDay;
// //   final List<dynamic> events;
// //
// //   const EventList({required this.selectedDay, required this.events});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.symmetric(horizontal: 16),
// //           child: Text(
// //             DateFormat('yyyy-MM-dd').format(selectedDay),
// //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //           ),
// //         ),
// //         Expanded(
// //           child: GridView.builder(
// //             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //               crossAxisCount: 3, // Three images per row
// //               crossAxisSpacing: 8, // Adjust spacing as needed
// //               mainAxisSpacing: 8, // Adjust spacing as needed
// //             ),
// //             itemCount: events.length,
// //             itemBuilder: (context, index) {
// //               return EventListItem(
// //                   selectedDay: selectedDay,
// //                   event: events[index]
// //               );
// //             },
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }
//
// class EventList extends StatelessWidget {
//   final DateTime selectedDay;
//   final List<dynamic> events;
//
//   const EventList({required this.selectedDay, required this.events});
//
//   Widget _buildTotalNutrients() {
//     double totalCarbs = 0;
//     double totalProtein = 0;
//     double totalFat = 0;
//
//     for (var event in events) {
//       totalCarbs += event.nutrients['carbohydrates'] ?? 0;
//       totalProtein += event.nutrients['protein'] ?? 0;
//       totalFat += event.nutrients['fat'] ?? 0;
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Total Nutrients for $selectedDay:'),
//         Text('Carbohydrates: $totalCarbs'),
//         Text('Protein: $totalProtein'),
//         Text('Fat: $totalFat'),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Text(
//             DateFormat('yyyy-MM-dd').format(selectedDay),
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//         ),
//         _buildTotalNutrients(),
//         Expanded(
//           child: GridView.builder(
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 3,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemCount: events.length,
//             itemBuilder: (context, index) {
//               return GestureDetector(
//                 onTap: () {
//                   // Navigate to EventDetailScreen
//                 },
//                 child: EventListItem(
//                     selectedDay: selectedDay,
//                     event: events[index]
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
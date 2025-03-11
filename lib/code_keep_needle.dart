// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// /// アプリ本体
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: '地図上で針が回るサンプル',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const MapSpinPage(),
//     );
//   }
// }
//
// class MapSpinPage extends StatefulWidget {
//   const MapSpinPage({super.key});
//
//   @override
//   State<MapSpinPage> createState() => _MapSpinPageState();
// }
//
// class _MapSpinPageState extends State<MapSpinPage> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//
//   late Animation<double> _animation;
//
//   double _currentPointerAngle = 0.0;
//
//   double? finalPointerAngleDegrees;
//
//   final MapController _mapController = MapController();
//   double _currentZoom = 16.0;
//
//   final LatLng _tokyoStation = const LatLng(35.681236, 139.767125);
//
//   ///
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
//
//     _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
//
//     _animation.addStatusListener((AnimationStatus status) {
//       if (status == AnimationStatus.completed) {
//         double compassAngle = _animation.value % (2 * pi);
//         if (compassAngle < 0) {
//           compassAngle += 2 * pi;
//         }
//
//         setState(() => finalPointerAngleDegrees = compassAngle * 180 / pi);
//       }
//     });
//   }
//
//   ///
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   ///
//   void _spinPointer() {
//     final Random random = Random();
//
//     final double randomTurns = random.nextDouble() * 3 + 2;
//
//     final double newAngle = _currentPointerAngle + (2 * pi * randomTurns);
//
//     _animation = Tween<double>(begin: _currentPointerAngle, end: newAngle).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOut),
//     );
//
//     setState(() => finalPointerAngleDegrees = null);
//
//     _controller.reset();
//
//     _controller.forward();
//
//     _currentPointerAngle = newAngle;
//   }
//
//   ///
//   void _zoomIn() => setState(() {
//     _currentZoom += 1;
//     _mapController.move(_tokyoStation, _currentZoom);
//   });
//
//   ///
//   void _zoomOut() => setState(() {
//     _currentZoom -= 1;
//     _mapController.move(_tokyoStation, _currentZoom);
//   });
//
//   ///
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('地図上で針が回るサンプル')),
//       body: Stack(
//         children: <Widget>[
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: _tokyoStation,
//               initialZoom: _currentZoom,
//               onPositionChanged: (MapCamera position, bool isMoving) {
//                 if (isMoving) {
//                   _mapController.rotate(0);
//                 }
//               },
//             ),
//             children: <Widget>[
//               TileLayer(
//                 urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 userAgentPackageName: 'com.example.myapp',
//               ),
//               MarkerLayer(
//                 markers: <Marker>[
//                   Marker(
//                     point: _tokyoStation,
//                     width: 200,
//                     height: 200,
//                     child: AnimatedBuilder(
//                       animation: _animation,
//                       builder: (BuildContext context, Widget? child) =>
//                           Transform.rotate(angle: _animation.value, child: child),
//                       child: CustomPaint(painter: PointerPainter()),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           Positioned(
//             top: 20,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: finalPointerAngleDegrees == null
//                   ? Container()
//                   : Text(
//                 '針先の向き: ${finalPointerAngleDegrees!.toStringAsFixed(2)}° (${getCompassDirection(finalPointerAngleDegrees!)})',
//                 style: const TextStyle(
//                   fontSize: 20,
//                   color: Colors.black,
//                   backgroundColor: Colors.white70,
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 90,
//             left: 10,
//             child: Column(
//               children: <Widget>[
//                 FloatingActionButton(onPressed: _zoomIn, mini: true, child: const Icon(Icons.add)),
//                 const SizedBox(height: 10),
//                 FloatingActionButton(onPressed: _zoomOut, mini: true, child: const Icon(Icons.remove)),
//               ],
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(onPressed: _spinPointer, child: const Icon(Icons.refresh)),
//     );
//   }
// }
//
// ///
// String getCompassDirection(double degrees) {
//   const List<String> directions = <String>[
//     '北',
//     '北北東',
//     '北東',
//     '東北東',
//     '東',
//     '東南東',
//     '南東',
//     '南南東',
//     '南',
//     '南南西',
//     '南西',
//     '西南西',
//     '西',
//     '西北西',
//     '北西',
//     '北北西'
//   ];
//
//   final int index = (((degrees + 11.25) % 360) / 22.5).floor() % 16;
//
//   return directions[index];
// }
//
// class PointerPainter extends CustomPainter {
//   ///
//   @override
//   void paint(Canvas canvas, Size size) {
//     final Offset center = Offset(size.width / 2, size.height / 2);
//
//     final double needleLength = size.width * 0.8;
//
//     final Offset needleEnd = Offset(center.dx, center.dy - needleLength);
//
//     final Paint paint = Paint()
//       ..color = Colors.red
//       ..strokeWidth = 4.0
//       ..strokeCap = StrokeCap.round;
//
//     canvas.drawLine(center, needleEnd, paint);
//
//     canvas.drawCircle(center, 6.0, Paint()..color = Colors.black);
//   }
//
//   ///
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

///
Offset latLngToPixel(LatLng latlng, double zoom) {
  final double latRad = latlng.latitude * pi / 180;
  final num scale = 256 * pow(2, zoom);
  final double x = (latlng.longitude + 180) / 360 * scale;
  final double y = (1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * scale;
  return Offset(x, y);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '地図上で針が回るサンプル',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapSpinPage(),
    );
  }
}

class MapSpinPage extends StatefulWidget {
  const MapSpinPage({super.key});

  @override
  State<MapSpinPage> createState() => _MapSpinPageState();
}

class _MapSpinPageState extends State<MapSpinPage> with SingleTickerProviderStateMixin {
  final GlobalKey _mapKey = GlobalKey();

  late AnimationController _controller;

  late Animation<double> _animation;

  double _currentPointerAngle = 0.0;

  double? finalPointerAngleDegrees;

  double _needleFactor = 0.4;

  bool _showRectangle = false;

  final MapController _mapController = MapController();

  double _currentZoom = 16.0;

  final LatLng _centerCoord = const LatLng(35.718532, 139.586639);

  final List<LatLng> _additionalMarkers = <LatLng>[
    const LatLng(35.718662, 139.586794),
    const LatLng(35.718563, 139.586541),
    const LatLng(35.718332, 139.586443),
    const LatLng(35.718477, 139.586463),
    const LatLng(35.718447, 139.586812),
    const LatLng(35.71841, 139.586709),
    const LatLng(35.718362, 139.586482),
    const LatLng(35.718376, 139.586732),
    const LatLng(35.718505, 139.586702),
    const LatLng(35.718664, 139.586525),
    const LatLng(35.718729, 139.586664),
    const LatLng(35.718547, 139.586593),
    const LatLng(35.718592, 139.586624),
    const LatLng(35.718332, 139.586675),
    const LatLng(35.71866, 139.586578),
    const LatLng(35.718642, 139.58663),
    const LatLng(35.7185, 139.586516),
    const LatLng(35.71837, 139.586832),
    const LatLng(35.718532, 139.586811),
    const LatLng(35.718677, 139.586835)
  ];

  ///
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));

    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);

    _animation.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        double compassAngle = _animation.value % (2 * pi);

        if (compassAngle < 0) {
          compassAngle += 2 * pi;
        }

        setState(() => finalPointerAngleDegrees = compassAngle * 180 / pi);
      }
    });
  }

  ///
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ///
  void _spinPointer() {
    final Random random = Random();

    final double randomTurns = random.nextDouble() * 3 + 2;

    final double newAngle = _currentPointerAngle + (2 * pi * randomTurns);

    _animation = Tween<double>(begin: _currentPointerAngle, end: newAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    setState(() => finalPointerAngleDegrees = null);

    _controller.reset();

    _controller.forward();

    _currentPointerAngle = newAngle;
  }

  ///
  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
      _mapController.move(_centerCoord, _currentZoom);
    });
  }

  ///
  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
      _mapController.move(_centerCoord, _currentZoom);
    });
  }

  ///
  void _increaseNeedle() => setState(() => _needleFactor += 0.5);

  ///
  void _decreaseNeedle() => setState(() => _needleFactor = max(0.5, _needleFactor - 0.5));

  ///
  void _toggleRectangle() => setState(() => _showRectangle = !_showRectangle);

  ///
  void _checkMarkersInRectangle() {
    const double widgetSize = 200.0;

    const Offset widgetCenter = Offset(widgetSize / 2, widgetSize / 2);

    final double needleLength = widgetSize * _needleFactor;

    final double rectWidth = needleLength * 0.2;

    final Rect rect =
        Rect.fromLTWH(widgetCenter.dx - rectWidth / 2, widgetCenter.dy - needleLength, rectWidth, needleLength);

    final List<LatLng> insideMarkers = <LatLng>[];

    for (final LatLng marker in _additionalMarkers) {
      final Offset markerPixel = latLngToPixel(marker, _currentZoom);

      final Offset centerPixel = latLngToPixel(_centerCoord, _currentZoom);

      final Offset relative = Offset(markerPixel.dx - centerPixel.dx, markerPixel.dy - centerPixel.dy) + widgetCenter;

      final Offset unrotated = _rotateOffset(relative, -_animation.value, widgetCenter);

      if (rect.contains(unrotated)) {
        insideMarkers.add(marker);
      }
    }

    // ignore: inference_failure_on_function_invocation
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: insideMarkers.isEmpty
              ? const Text('長方形内にはマーカーがありません。')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('長方形内のマーカー：', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...insideMarkers.map((LatLng m) => Text('Lat: ${m.latitude}, Lng: ${m.longitude}'))
                  ],
                ),
        );
      },
    );
  }

  ///
  Offset _rotateOffset(Offset point, double angle, Offset center) {
    final Offset translated = point - center;

    final Offset rotated = Offset(
      translated.dx * cos(angle) - translated.dy * sin(angle),
      translated.dx * sin(angle) + translated.dy * cos(angle),
    );

    return rotated + center;
  }

  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('地図上で針が回るサンプル'),
        actions: <Widget>[
          IconButton(
            icon: Icon(_showRectangle ? Icons.visibility : Icons.visibility_off),
            tooltip: '長方形の表示切替',
            onPressed: _toggleRectangle,
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            key: _mapKey,
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerCoord,
              initialZoom: _currentZoom,
              minZoom: _currentZoom,
              maxZoom: _currentZoom,
              onPositionChanged: (MapCamera position, bool hasGesture) => _mapController.rotate(0),
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.myapp',
              ),
              MarkerLayer(
                markers: <Marker>[
                  Marker(
                    point: _centerCoord,
                    width: 200,
                    height: 200,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (BuildContext context, Widget? child) =>
                          Transform.rotate(angle: _animation.value, child: child),
                      child: CustomPaint(
                        painter: PointerPainter(needleFactor: _needleFactor, showRectangle: _showRectangle),
                      ),
                    ),
                  ),
                ],
              ),
              MarkerLayer(
                markers: _additionalMarkers.map((LatLng latlng) {
                  return Marker(
                    point: latlng,
                    width: 20,
                    height: 20,
                    child: Container(decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: finalPointerAngleDegrees == null
                  ? Container()
                  : Text(
                      '針先の向き: ${finalPointerAngleDegrees!.toStringAsFixed(2)}° (${getCompassDirection(finalPointerAngleDegrees!)})',
                      style: const TextStyle(fontSize: 20, color: Colors.black, backgroundColor: Colors.white70),
                    ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: 10,
            child: Column(
              children: <Widget>[
                FloatingActionButton(onPressed: _zoomIn, mini: true, child: const Icon(Icons.add)),
                const SizedBox(height: 10),
                FloatingActionButton(onPressed: _zoomOut, mini: true, child: const Icon(Icons.remove)),
              ],
            ),
          ),
          Positioned(
            bottom: 90,
            right: 10,
            child: Column(
              children: <Widget>[
                FloatingActionButton(
                  onPressed: _increaseNeedle,
                  mini: true,
                  backgroundColor: Colors.green,
                  tooltip: '針を長くする',
                  child: const Icon(Icons.arrow_upward),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _decreaseNeedle,
                  mini: true,
                  backgroundColor: Colors.orange,
                  tooltip: '針を短くする',
                  child: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(onPressed: _checkMarkersInRectangle, child: const Text('長方形内のマーカーをチェック')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _spinPointer, child: const Icon(Icons.refresh)),
    );
  }
}

///
String getCompassDirection(double degrees) {
  const List<String> directions = <String>[
    '北',
    '北北東',
    '北東',
    '東北東',
    '東',
    '東南東',
    '南東',
    '南南東',
    '南',
    '南南西',
    '南西',
    '西南西',
    '西',
    '西北西',
    '北西',
    '北北西'
  ];

  final int index = (((degrees + 11.25) % 360) / 22.5).floor() % 16;

  return directions[index];
}

class PointerPainter extends CustomPainter {
  const PointerPainter({required this.needleFactor, required this.showRectangle});

  final double needleFactor;

  final bool showRectangle;

  ///
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final double needleLength = size.width * needleFactor;

    final Offset needleEnd = Offset(center.dx, center.dy - needleLength);

    final Paint needlePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    canvas.drawCircle(center, 6.0, Paint()..color = Colors.black);

    if (showRectangle) {
      final double rectWidth = needleLength * 0.2;

      final Rect rect = Rect.fromLTWH(center.dx - rectWidth / 2, center.dy - needleLength, rectWidth, needleLength);

      final Paint rectPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(rect, rectPaint);
    }
  }

  ///
  @override
  bool shouldRepaint(covariant PointerPainter oldDelegate) =>
      oldDelegate.needleFactor != needleFactor || oldDelegate.showRectangle != showRectangle;
}

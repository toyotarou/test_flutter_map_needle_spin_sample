import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

/// Web Mercator 変換（緯度経度 → ピクセル座標）
Offset latLngToPixel(LatLng latlng, double zoom) {
  final latRad = latlng.latitude * pi / 180;
  final scale = 256 * pow(2, zoom);
  final x = (latlng.longitude + 180) / 360 * scale;
  final y = (1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * scale;
  return Offset(x, y);
}

/// Web Mercator 変換の逆（ピクセル座標 → 緯度経度）
LatLng pixelToLatLng(Offset pixel, double zoom) {
  final scale = 256 * pow(2, zoom);
  final lng = pixel.dx / scale * 360 - 180;
  final n = pi - 2 * pi * pixel.dy / scale;
  final lat = 180 / pi * atan(sinh(n));
  return LatLng(lat, lng);
}

/// Dart の math ライブラリに sinh がない場合は自前で定義（最新 SDK では不要）
double sinh(num x) => (exp(x) - exp(-x)) / 2.0;

/// 点 p と線分 AB の距離（緯度経度の単位で計算）
double distancePointToSegment(LatLng p, LatLng a, LatLng b) {
  if (a.latitude == b.latitude && a.longitude == b.longitude) {
    return sqrt(pow(p.latitude - a.latitude, 2) + pow(p.longitude - a.longitude, 2));
  }
  double dx = b.longitude - a.longitude;
  double dy = b.latitude - a.latitude;
  double t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) / (dx * dx + dy * dy);
  t = t.clamp(0.0, 1.0);
  double projX = a.longitude + t * dx;
  double projY = a.latitude + t * dy;
  return sqrt(pow(p.longitude - projX, 2) + pow(p.latitude - projY, 2));
}

/// 射影法に許容誤差を加えて、点がポリゴン内にあるか判定する関数
/// tolerance: 各辺との距離が tolerance 以下なら内部とみなす
bool isPointInsidePolygonWithTolerance(LatLng point, List<LatLng> polygon, double tolerance) {
  // まず、各辺との近接チェック
  for (int i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    if (distancePointToSegment(point, a, b) <= tolerance) {
      return true;
    }
  }
  int intersectCount = 0;
  for (int i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    bool cond1 = ((a.latitude > point.latitude) != (b.latitude > point.latitude));
    double intersectX =
        (b.longitude - a.longitude) * (point.latitude - a.latitude) / (b.latitude - a.latitude) + a.longitude;
    bool cond2 = point.longitude < intersectX;
    if (cond1 && cond2) {
      intersectCount++;
    }
  }
  return intersectCount.isOdd;
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
  // GlobalKey（型指定なし）
  final GlobalKey _mapKey = GlobalKey();

  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentPointerAngle = 0.0;
  double? finalPointerAngleDegrees;
  double _needleFactor = 0.4;
  bool _showRectangle = true;

  // 許容誤差を制御する変数（変更可能）
  double _tolerance = 0.000001;

  final MapController _mapController = MapController();
  double _currentZoom = 16.0;

  // 中心座標
  final LatLng _centerCoord = LatLng(35.718532, 139.586639);

  // 追加マーカー：中心座標付近にランダムなオフセットで20個生成
  final List<LatLng> _additionalMarkers = List.generate(20, (index) {
    final rand = Random(index);
    final offsetLat = 35.718532 + (rand.nextDouble() - 0.5) * 0.0004;
    final offsetLng = 139.586639 + (rand.nextDouble() - 0.5) * 0.0004;
    return LatLng(offsetLat, offsetLng);
  });

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        double compassAngle = _animation.value % (2 * pi);
        if (compassAngle < 0) compassAngle += 2 * pi;
        setState(() {
          finalPointerAngleDegrees = compassAngle * 180 / pi;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinPointer() {
    final random = Random();
    final randomTurns = random.nextDouble() * 3 + 2;
    final newAngle = _currentPointerAngle + (2 * pi * randomTurns);
    _animation = Tween<double>(begin: _currentPointerAngle, end: newAngle)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    setState(() {
      finalPointerAngleDegrees = null;
    });
    _controller.reset();
    _controller.forward();
    _currentPointerAngle = newAngle;
  }

  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
      _mapController.move(_centerCoord, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
      _mapController.move(_centerCoord, _currentZoom);
    });
  }

  void _increaseNeedle() {
    setState(() {
      _needleFactor += 0.05;
    });
  }

  void _decreaseNeedle() {
    setState(() {
      _needleFactor = max(0.05, _needleFactor - 0.05);
    });
  }

  void _toggleRectangle() {
    setState(() {
      _showRectangle = !_showRectangle;
    });
  }

  /// ポリゴン内判定：Pointer のウィジェット内の長方形（回転後）を緯度経度に変換してポリゴンを作成、
  /// 追加マーカーがその中に含まれるかを判定する
  void _checkMarkersInPolygon() {
    const widgetSize = 200.0;
    final widgetCenter = const Offset(widgetSize / 2, widgetSize / 2);
    final needleLength = widgetSize * _needleFactor;
    final rectWidth = needleLength * 0.2;
    final topLeft = Offset(widgetCenter.dx - rectWidth / 2, widgetCenter.dy - needleLength);
    final topRight = Offset(widgetCenter.dx + rectWidth / 2, widgetCenter.dy - needleLength);
    final bottomRight = Offset(widgetCenter.dx + rectWidth / 2, widgetCenter.dy);
    final bottomLeft = Offset(widgetCenter.dx - rectWidth / 2, widgetCenter.dy);
    final rotatedPoints = [
      _rotateOffset(topLeft, _animation.value, widgetCenter),
      _rotateOffset(topRight, _animation.value, widgetCenter),
      _rotateOffset(bottomRight, _animation.value, widgetCenter),
      _rotateOffset(bottomLeft, _animation.value, widgetCenter),
    ];

    final centerPixel = latLngToPixel(_centerCoord, _currentZoom);
    final polygonLatLng = rotatedPoints.map((pt) {
      final pixel = centerPixel + (pt - widgetCenter);
      return pixelToLatLng(pixel, _currentZoom);
    }).toList();

    List<LatLng> insideMarkers = [];
    for (var marker in _additionalMarkers) {
      if (isPointInsidePolygonWithTolerance(marker, polygonLatLng, _tolerance)) {
        insideMarkers.add(marker);
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: insideMarkers.isEmpty
              ? const Text("ポリゴン内にはマーカーがありません。")
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ポリゴン内のマーカー：",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 10),
                    ...insideMarkers.map((m) => Text("Lat: ${m.latitude}, Lng: ${m.longitude}"))
                  ],
                ),
        );
      },
    );
  }

  /// 指定された point を center を基準に angle だけ回転させた Offset を返す
  Offset _rotateOffset(Offset point, double angle, Offset center) {
    final translated = point - center;
    final rotated = Offset(
      translated.dx * cos(angle) - translated.dy * sin(angle),
      translated.dx * sin(angle) + translated.dy * cos(angle),
    );
    return rotated + center;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('地図上で針が回るサンプル'),
        actions: [
          IconButton(
            icon: Icon(_showRectangle ? Icons.visibility : Icons.visibility_off),
            tooltip: '長方形（ポリゴン）の表示切替',
            onPressed: _toggleRectangle,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            key: _mapKey,
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerCoord,
              initialZoom: _currentZoom,
              minZoom: _currentZoom,
              maxZoom: _currentZoom,
              onPositionChanged: (position, hasGesture) {
                _mapController.rotate(0);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.myapp',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _centerCoord,
                    width: 200,
                    height: 200,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _animation.value,
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                      child: CustomPaint(
                        painter: PointerPainter(
                          needleFactor: _needleFactor,
                          showRectangle: _showRectangle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              MarkerLayer(
                markers: _additionalMarkers.map((latlng) {
                  return Marker(
                    point: latlng,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
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
                      "針先の向き: ${finalPointerAngleDegrees!.toStringAsFixed(2)}° (${getCompassDirection(finalPointerAngleDegrees!)})",
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        backgroundColor: Colors.white70,
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _zoomIn,
                  mini: true,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _zoomOut,
                  mini: true,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 90,
            right: 10,
            child: Column(
              children: [
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
              child: ElevatedButton(
                onPressed: _checkMarkersInPolygon,
                child: const Text("ポリゴン内のマーカーをチェック"),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _spinPointer,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

/// 16方位を返すヘルパー関数
String getCompassDirection(double degrees) {
  const List<String> directions = [
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
  int index = (((degrees + 11.25) % 360) / 22.5).floor() % 16;
  return directions[index];
}

/// PointerPainter：針とその周りの長方形（ポリゴン）を描画する
class PointerPainter extends CustomPainter {
  final double needleFactor;
  final bool showRectangle;

  const PointerPainter({
    required this.needleFactor,
    required this.showRectangle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final needleLength = size.width * needleFactor;
    final needleEnd = Offset(center.dx, center.dy - needleLength);

    final needlePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 6.0, Paint()..color = Colors.black);

    if (showRectangle) {
      final rectWidth = needleLength * 0.2;
      final rect = Rect.fromLTWH(
        center.dx - rectWidth / 2,
        center.dy - needleLength,
        rectWidth,
        needleLength,
      );
      final rectPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(rect, rectPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PointerPainter oldDelegate) =>
      oldDelegate.needleFactor != needleFactor || oldDelegate.showRectangle != showRectangle;
}

// import 'dart:math';
// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// /// アプリ本体
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: '回転する針ルーレット',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const MyHomePage(),
//     );
//   }
// }
//
// /// ホーム画面
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({Key? key}) : super(key: key);
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   // 現在の針の回転角度（次回の開始角度用）
//   double _currentPointerAngle = 0.0;
//   // 20セグメントの場合、各セグメントに10点刻みの点数 (10, 20, …, 200)
//   final List<int> scores = List.generate(20, (index) => (index + 1) * 10);
//   // 回転停止時の当たり点数（未決定ならnull）
//   int? winningScore;
//
//   int get segmentCount => scores.length;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     );
//
//     // 初期は針の回転角度0
//     _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
//
//     _animation.addStatusListener((status) {
//       if (status == AnimationStatus.completed) {
//         // アニメーション完了後、針の現在角度を更新
//         _currentPointerAngle = _animation.value;
//         // 針は初期状態で上向き（先端が上＝-π/2）として描画しているので、
//         // 回転角度に-π/2を足したものが針の先端の向きとなる
//         double pointerTipAngle = (_animation.value - pi / 2) % (2 * pi);
//         if (pointerTipAngle < 0) pointerTipAngle += 2 * pi;
//         // 各セグメントの角度幅
//         double sweepAngle = 2 * pi / segmentCount;
//         // 針の先端がどのセグメントに入るか
//         int winningIndex = (pointerTipAngle / sweepAngle).floor() % segmentCount;
//         setState(() {
//           winningScore = scores[winningIndex];
//         });
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   /// 針を回転させる処理
//   void _spinPointer() {
//     // 2～5周（ランダムな複数周）回転させる
//     final random = Random();
//     final randomTurns = random.nextDouble() * 3 + 2; // 2〜5周
//     final newAngle = _currentPointerAngle + (2 * pi * randomTurns);
//
//     _animation = Tween<double>(begin: _currentPointerAngle, end: newAngle)
//         .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
//
//     setState(() {
//       winningScore = null;
//     });
//     _controller.reset();
//     _controller.forward();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('回転する針ルーレット'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Stackで固定の盤面と回転する針を重ねる
//             Stack(
//               alignment: Alignment.center,
//               children: [
//                 // 固定の盤面（各セグメントに点数表示）
//                 CustomPaint(
//                   size: const Size(300, 300),
//                   painter: BoardPainter(segmentCount: segmentCount, scores: scores),
//                 ),
//                 // 回転する針（中央から長い針）
//                 AnimatedBuilder(
//                   animation: _animation,
//                   builder: (context, child) {
//                     return Transform.rotate(
//                       angle: _animation.value,
//                       alignment: Alignment.center,
//                       child: child,
//                     );
//                   },
//                   child: SizedBox(
//                     width: 300,
//                     height: 300,
//                     child: CustomPaint(
//                       painter: PointerPainter(),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             // 当たり点数の表示
//             if (winningScore != null)
//               Text(
//                 '当たり: $winningScore',
//                 style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _spinPointer,
//         child: const Icon(Icons.play_arrow),
//       ),
//     );
//   }
// }
//
// /// 固定の盤面描画（各セグメントに点数表示）
// class BoardPainter extends CustomPainter {
//   final int segmentCount;
//   final List<int> scores;
//
//   BoardPainter({required this.segmentCount, required this.scores});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = min(size.width / 2, size.height / 2);
//     final paint = Paint()..style = PaintingStyle.fill;
//     final double sweepAngle = 2 * pi / segmentCount;
//
//     // 各セグメントを描画
//     for (int i = 0; i < segmentCount; i++) {
//       paint.color = HSVColor.fromAHSV(
//         1.0,
//         (360 / segmentCount) * i,
//         1.0,
//         1.0,
//       ).toColor();
//
//       final double startAngle = sweepAngle * i;
//       canvas.drawArc(
//         Rect.fromCircle(center: center, radius: radius),
//         startAngle,
//         sweepAngle,
//         true,
//         paint,
//       );
//
//       // セグメント中央に点数テキストを描画
//       double textAngle = startAngle + sweepAngle / 2;
//       Offset textPos = Offset(
//         center.dx + radius * 0.6 * cos(textAngle),
//         center.dy + radius * 0.6 * sin(textAngle),
//       );
//
//       TextSpan span = TextSpan(
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 14,
//           fontWeight: FontWeight.bold,
//         ),
//         text: '${scores[i]}',
//       );
//       TextPainter tp = TextPainter(
//         text: span,
//         textAlign: TextAlign.center,
//         textDirection: TextDirection.ltr,
//       );
//       tp.layout();
//       Offset textOffset = textPos - Offset(tp.width / 2, tp.height / 2);
//       tp.paint(canvas, textOffset);
//     }
//
//     // 盤面の外枠を描画
//     final outlinePaint = Paint()
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4.0;
//     canvas.drawCircle(center, radius, outlinePaint);
//
//     // 各セグメントの境界線を描画
//     for (int i = 0; i < segmentCount; i++) {
//       double angle = sweepAngle * i;
//       double x = center.dx + radius * cos(angle);
//       double y = center.dy + radius * sin(angle);
//       canvas.drawLine(center, Offset(x, y), outlinePaint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
//
// /// 針の描画（盤面中央から伸びる長い針）
// class PointerPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     // 針の長さは盤面の高さの45%程度
//     final needleLength = size.height * 0.45;
//     final needleEnd = Offset(center.dx, center.dy - needleLength);
//     final paint = Paint()
//       ..color = Colors.red
//       ..strokeWidth = 4.0
//       ..strokeCap = StrokeCap.round;
//     canvas.drawLine(center, needleEnd, paint);
//
//     // 中心部の固定点を表す小さな円を描画（任意）
//     canvas.drawCircle(center, 8.0, Paint()..color = Colors.black);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Alert UI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AlertScreen(),
    );
  }
}

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  _AlertScreenState createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      lowerBound: 0.8,
      upperBound: 1.2,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateBell() {
    _controller.forward().then((_) => _controller.reverse());
    Future.delayed(const Duration(milliseconds: 200), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SymbolScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50.0, left: 20.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.account_circle, size: 40, color: Colors.blue),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Hi, Student',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _animateBell,
                  child: ScaleTransition(
                    scale: _controller,
                    child: const Icon(
                      Icons.notifications,
                      size: 100,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Press the bell to report a threat to the school. Do not use this for personal purposes--this button may be pressed only in life-threatening instances. If you or someone you know needs assistance or someone to talk to, please contact the school’s counseling service or call the hotline: 988',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SymbolScreen extends StatefulWidget {
  const SymbolScreen({super.key});

  @override
  _SymbolScreenState createState() => _SymbolScreenState();
}

class _SymbolScreenState extends State<SymbolScreen> {
  Set<Offset> tracedPoints = {};
  Offset? blueDotPosition;
  final List<Offset> symbolPoints = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _generateSymbolPoints();
  }

  void _generateSymbolPoints() {
    double radius = 150; // Increased radius to make the infinity sign bigger
    double offsetX = MediaQuery.of(context).size.width / 2;
    double offsetY = 200;

    for (double t = 0; t < 2 * pi; t += 0.01) {
      double x = offsetX + radius * cos(t) / (1 + sin(t) * sin(t));
      double y = offsetY + radius * sin(t) * cos(t) / (1 + sin(t) * sin(t));
      symbolPoints.add(Offset(x, y));
    }

    blueDotPosition = symbolPoints[0];
  }

  Offset _constrainToPath(Offset position) {
    double minDistance = double.infinity;
    Offset constrainedPosition = position;

    for (var point in symbolPoints) {
      double distance = (position - point).distance;
      if (distance < minDistance) {
        minDistance = distance;
        constrainedPosition = point;
      }
    }
    return constrainedPosition;
  }

  bool _isSymbolCompleted() {
    if (tracedPoints.length < symbolPoints.length) return false;

    // Check if the last traced point is close to the starting point
    final double threshold = 10.0;
    return (tracedPoints.last - symbolPoints[0]).distance < threshold;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      blueDotPosition = _constrainToPath(details.localPosition);

      if (_isNearSymbolPath(blueDotPosition!)) {
        if (tracedPoints.isEmpty) {
          tracedPoints.add(blueDotPosition!);
        } else {
          int lastIndex = symbolPoints.indexOf(tracedPoints.last);
          int nextIndex = (lastIndex + 1) % symbolPoints.length;

          if ((blueDotPosition! - symbolPoints[nextIndex]).distance < 10.0) {
            tracedPoints.add(symbolPoints[nextIndex]);
          }
        }

        // Check if the symbol is completed
        if (_isSymbolCompleted()) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LockdownScreen()),
          );
        }
      }
    });
  }

  bool _isNearSymbolPath(Offset position) {
    const double threshold = 5.0;
    return symbolPoints.any((point) => (position - point).distance < threshold);
  }

  void _resetTracing() {
    setState(() {
      tracedPoints.clear();
      blueDotPosition = symbolPoints[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      body: Column(
        children: [
          // Container with fixed height for the CustomPaint and GestureDetector
          Container(
            height: MediaQuery.of(context).size.height * 0.7, // 70% of the screen height
            child: GestureDetector(
              onPanUpdate: _handlePanUpdate,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 300),
                painter: InfinityPainter(
                  tracedPoints: tracedPoints,
                  symbolPoints: symbolPoints,
                  blueDotPosition: blueDotPosition,
                ),
              ),
            ),
          ),
          // Text with reduced vertical padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0), // Reduced vertical padding
            child: Text(
              'Trace the symbol above to confirm your report. Once you have done so, follow the instructions given.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class LockdownScreen extends StatelessWidget {
  const LockdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDDD3FF), // Background color: #ddd3ff
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'The school is\nunder lock\ndown.',
                style: TextStyle(
                  fontSize: 32, // Larger font size
                  fontWeight: FontWeight.w900, // Thicker and bolder text
                  color: Color(0xFF6758EF), // Text color: #6758ef
                  height: 1.5, // Adjust line height for proper spacing
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20), // Spacing between the two text blocks
              Text(
                'Please\nremain calm\nand stay\nwhere you\nare.',
                style: TextStyle(
                  fontSize: 32, // Larger font size
                  fontWeight: FontWeight.w900, // Thicker and bolder text
                  color: Color(0xFF6758EF), // Text color: #6758ef
                  height: 1.5, // Adjust line height for proper spacing
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfinityPainter extends CustomPainter {
  final Set<Offset> tracedPoints;
  final List<Offset> symbolPoints;
  final Offset? blueDotPosition;

  InfinityPainter({
    required this.tracedPoints,
    required this.symbolPoints,
    this.blueDotPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0; // Increased stroke width to make the infinity sign thicker

    Path path = Path();

    // Draw the infinity symbol
    for (var i = 0; i < symbolPoints.length; i++) {
      if (i == 0) {
        path.moveTo(symbolPoints[i].dx, symbolPoints[i].dy);
      } else {
        path.lineTo(symbolPoints[i].dx, symbolPoints[i].dy);
      }
    }

    canvas.drawPath(path, paint);

    // Draw the blue trail
    Paint trailPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0; // Increased stroke width for the trail

    Path trailPath = Path();
    bool firstPoint = true;

    for (var point in tracedPoints) {
      if (firstPoint) {
        trailPath.moveTo(point.dx, point.dy);
        firstPoint = false;
      } else {
        trailPath.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(trailPath, trailPaint);

    // Draw the blue dot
    if (blueDotPosition != null) {
      Paint dotPaint = Paint()..color = Colors.blue;
      canvas.drawCircle(blueDotPosition!, 10.0, dotPaint); // Slightly larger blue dot
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
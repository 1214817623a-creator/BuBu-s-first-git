import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Original vector illustrations, bundled in the application and usable offline.
class FoodArt extends StatefulWidget {
  final String kind;
  final bool animate;
  const FoodArt(this.kind, {super.key, this.animate = false});
  @override
  State<FoodArt> createState() => _FoodArtState();
}

class _FoodArtState extends State<FoodArt> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  @override
  void initState() {
    super.initState();
    if (widget.animate) controller.repeat();
  }

  @override
  void didUpdateWidget(FoodArt old) {
    super.didUpdateWidget(old);
    if (widget.animate) {
      controller.repeat();
    } else {
      controller.stop();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => CustomPaint(
      painter: FoodPainter(
        widget.kind,
        MediaQuery.disableAnimationsOf(context) ? 0 : controller.value,
      ),
      size: Size.infinite,
    ),
  );
}

class FoodPainter extends CustomPainter {
  final String kind;
  final double phase;
  FoodPainter(this.kind, this.phase);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final scale = math.min(size.width / 300, size.height / 210);
    canvas.scale(scale);
    final p = Paint();
    void oval(double x, double y, double w, double h, Color color) {
      p.color = color;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        p,
      );
    }

    void rect(
      double x,
      double y,
      double w,
      double h,
      Color color,
      double radius,
    ) {
      p.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: w, height: h),
          Radius.circular(radius),
        ),
        p,
      );
    }

    const dark = Color(0xFF354434),
        green = Color(0xFF608E50),
        red = Color(0xFFE56D44),
        cream = Color(0xFFFFF7E3);
    oval(0, 76, 190, 18, const Color(0x16000000));
    if (kind == 'tomato' || kind == 'cut') {
      if (kind == 'cut') {
        rect(0, 39, 220, 85, const Color(0xFFB58B65), 18);
        rect(-43, 22, 66, 48, const Color(0xFFB36B52), 12);
        rect(17, 30, 42, 34, const Color(0xFFD68E72), 9);
        rect(62, 22, 43, 36, const Color(0xFFD68E72), 9);
        rect(37, -22, 99, 17, const Color(0xFFC5CEC6), 4);
        rect(-30, -22, 46, 17, dark, 6);
      } else {
        oval(-42, 18, 103, 108, red);
        oval(46, 35, 88, 91, const Color(0xFFF09261));
        oval(-55, 2, 18, 29, const Color(0xFFF8B08C));
        for (final x in [-42.0, 46.0]) {
          for (var i = 0; i < 5; i++) {
            canvas.save();
            canvas.translate(x, -22);
            canvas.rotate(i * math.pi * 2 / 5);
            oval(0, -12, 13, 35, green);
            canvas.restore();
          }
        }
        oval(-58, 27, 6, 8, dark);
        oval(-28, 27, 6, 8, dark);
        p
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(-43, 36), width: 15, height: 9),
          0,
          math.pi,
          false,
          p,
        );
        p.style = PaintingStyle.fill;
      }
    } else if (kind == 'greens') {
      oval(0, 58, 214, 40, cream);
      oval(0, 56, 175, 24, const Color(0xFFE2DEC9));
      for (var i = 0; i < 7; i++) {
        canvas.save();
        canvas.translate((i - 3) * 19, 25);
        canvas.rotate((i - 3) * 0.17);
        rect(0, 15, 10, 70, const Color(0xFFB1CB71), 5);
        oval(0, -10, 38, 68, i.isEven ? green : const Color(0xFF80AB65));
        canvas.restore();
      }
    } else if (kind == 'pumpkin') {
      oval(0, 24, 157, 104, const Color(0xFFF0A343));
      oval(-39, 23, 49, 101, const Color(0xFFE88E34));
      oval(37, 23, 47, 101, const Color(0xFFE88E34));
      oval(0, 23, 53, 104, const Color(0xFFF5B34E));
      rect(0, -35, 16, 25, green, 5);
      oval(-18, 22, 6, 8, dark);
      oval(18, 22, 6, 8, dark);
    } else {
      final egg = kind == 'egg';
      rect(-109, 18, 35, 20, dark, 9);
      rect(109, 18, 35, 20, dark, 9);
      rect(0, 34, 195, 80, egg ? const Color(0xFFF5F0DA) : green, 30);
      oval(0, 1, 195, 60, dark);
      oval(
        0,
        0,
        176,
        47,
        egg
            ? const Color(0xFFF0D477)
            : kind == 'soup'
            ? const Color(0xFFDDBF82)
            : const Color(0xFFB96237),
      );
      for (var i = 0; i < 8; i++) {
        final a = i * 2.4;
        final x = math.cos(a) * (i.isEven ? 59 : 30);
        final y = math.sin(a) * 14;
        if (kind == 'soup') {
          oval(x, y, 25, 16, cream);
          oval(x, y, 7, 5, const Color(0xFFD9BFA0));
        } else if (!egg) {
          rect(
            x,
            y,
            23,
            15,
            i.isEven ? const Color(0xFFF49C64) : const Color(0xFF854D32),
            5,
          );
        } else {
          rect(x, y, 9, 4, green, 2);
        }
      }
      oval(-20, 40, 6, 8, cream);
      oval(20, 40, 6, 8, cream);
      p
        ..color = cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(0, 47), width: 18, height: 10),
        0,
        math.pi,
        false,
        p,
      );
      p
        ..color = const Color(0x80FFFFFF)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final x = (i - 1) * 34.0;
        final shift = math.sin(phase * math.pi * 2 + i) * 5;
        final path = Path()
          ..moveTo(x, -29)
          ..cubicTo(x - 12, -40 + shift, x + 12, -49 + shift, x, -65 + shift);
        canvas.drawPath(path, p);
      }
      p.style = PaintingStyle.fill;
    }
    for (var i = 0; i < 3; i++) {
      final x = i == 0
          ? -113.0
          : i == 1
          ? 112.0
          : 90.0;
      final y = i == 0
          ? -58.0
          : i == 1
          ? -41.0
          : 74.0;
      p.color = const Color(0xFFF8F3D8);
      canvas.drawCircle(Offset(x, y), i == 1 ? 5 : 3, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FoodPainter old) => old.kind != kind || old.phase != phase;
}

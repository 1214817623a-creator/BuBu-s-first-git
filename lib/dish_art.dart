import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

/// Dish illustrations use the actual ingredients and plating of each recipe.
/// Step diagrams remain separate, so a preparation diagram is never a cover.
class DishArt extends StatelessWidget {
  final Recipe recipe;
  const DishArt(this.recipe, {super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${recipe.name} · 菜品示意插画',
    image: true,
    child: CustomPaint(painter: _DishPainter(recipe), size: Size.infinite),
  );
}

class _DishPainter extends CustomPainter {
  final Recipe recipe;
  _DishPainter(this.recipe);
  static const cream = Color(0xFFFFF5DA);
  static const green = Color(0xFF56824A);
  static const brown = Color(0xFF98522F);
  final paintBrush = Paint()..isAntiAlias = true;
  void oval(Canvas c, double x, double y, double w, double h, Color color) {
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: w, height: h),
      paintBrush
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void line(Canvas c, Offset a, Offset b, Color color, double width) {
    c.drawLine(
      a,
      b,
      paintBrush
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  String get style {
    if (recipe.dishStyle != 'plate') return recipe.dishStyle;
    return switch (recipe.art) {
      'stew' => 'cubes',
      'soup' => 'soup',
      'egg' => 'custard',
      'greens' => 'leaves',
      'pumpkin' => 'pumpkin',
      'chestnut' => 'cubes',
      _ => 'slices',
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    final scale = math.min(size.width / 320, size.height / 220);
    canvas.translate(
      (size.width - 320 * scale) / 2,
      (size.height - 220 * scale) / 2,
    );
    canvas.scale(scale);
    final c = canvas;
    final soup = [
      'soup',
      'porridge',
      'custard',
      'noodles',
      'meatballs',
      'curry',
    ].contains(style);
    oval(c, 163, 181, 235, 24, const Color(0x18000000));
    if (soup) {
      final bowl = Path()
        ..moveTo(42, 91)
        ..quadraticBezierTo(52, 195, 160, 196)
        ..quadraticBezierTo(268, 195, 278, 91)
        ..close();
      c.drawPath(
        bowl,
        paintBrush
          ..color = const Color(0xFFE7DDD0)
          ..style = PaintingStyle.fill,
      );
    }
    oval(c, 160, 108, 286, 154, const Color(0xFFFDFCF8));
    oval(c, 160, 108, 263, 132, const Color(0xFFD5C9B7));
    final sauce = style == 'custard'
        ? const Color(0xFFF3CE64)
        : style == 'porridge'
        ? cream
        : soup
        ? const Color(0xFFE6BE79)
        : const Color(0xFFEFE1C9);
    oval(c, 160, 108, 244, 117, sauce);
    c.save();
    c.clipPath(
      Path()..addOval(
        Rect.fromCenter(
          center: const Offset(160, 108),
          width: 240,
          height: 113,
        ),
      ),
    );
    if (style == 'whole-fish') {
      _wholeFish(c);
    } else if (style == 'noodles') {
      for (var i = 0; i < 25; i++) {
        final p = Path()
          ..moveTo(72 + i * 4.0, 75 + i % 3 * 9.0)
          ..cubicTo(
            245,
            40.0 + i * 3,
            60,
            130.0 + i,
            230.0 - i * 2,
            144 - i % 5 * 4.0,
          );
        c.drawPath(
          p,
          paintBrush
            ..color = const Color(0xFFB38939)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      _toppings(c);
    } else if (style == 'custard') {
      oval(c, 160, 108, 225, 103, const Color(0xFFF5D775));
      final p = Path()
        ..moveTo(99, 106)
        ..quadraticBezierTo(160, 127, 214, 95);
      c.drawPath(
        p,
        paintBrush
          ..color = const Color(0xAA9D682A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else if (style == 'fried-egg') {
      for (var i = 0; i < 2; i++) {
        oval(c, 119 + i * 77.0, 108, 112, 82, Colors.white);
        oval(c, 126 + i * 70.0, 105, 46, 40, const Color(0xFFF0AA28));
      }
    } else if (style == 'dumplings') {
      for (var i = 0; i < 9; i++) {
        final x = 79 + (i % 3) * 78.0, y = 81 + (i ~/ 3) * 27.0;
        final p = Path()
          ..moveTo(x - 27, y + 10)
          ..quadraticBezierTo(x - 25, y - 23, x + 24, y - 4)
          ..quadraticBezierTo(x + 33, y + 19, x - 27, y + 10)
          ..close();
        c.drawPath(
          p,
          paintBrush
            ..color = cream
            ..style = PaintingStyle.fill,
        );
        for (var j = 0; j < 5; j++) {
          line(
            c,
            Offset(x - 18 + j * 9, y - 5),
            Offset(x - 15 + j * 9, y + 1),
            const Color(0xFFCCB989),
            1.5,
          );
        }
      }
    } else {
      final ingredients = recipe.ingredients
          .where(
            (i) =>
                (i.amount >= 40 || i.unit == '个' || i.name.contains('木耳')) &&
                ![
                  '水',
                  '热水',
                  '温水',
                  '盐',
                  '糖',
                  '冰糖',
                  '葱',
                  '小葱',
                  '姜',
                  '蒜',
                  '食用油',
                  '生抽',
                  '老抽',
                  '淀粉',
                  '米醋',
                  '豆瓣酱',
                  '料酒',
                ].contains(i.name),
          )
          .take(4)
          .toList();
      final seed = recipe.id.codeUnits.fold<int>(0, (a, b) => a + b);
      final random = math.Random(seed);
      final count = style == 'rice'
          ? 100
          : style == 'porridge'
          ? 48
          : style == 'eggs'
          ? 8
          : style == 'ribs'
          ? 12
          : 28;
      for (var i = 0; i < count; i++) {
        final angle = random.nextDouble() * math.pi * 2,
            rad = math.sqrt(random.nextDouble());
        final x = 160 + math.cos(angle) * 108 * rad,
            y = 108 + math.sin(angle) * 49 * rad;
        final food = ingredients.isEmpty
            ? ''
            : ingredients[i % ingredients.length].name;
        _piece(c, x, y, food, style, random.nextDouble() * 1.4 - 0.7);
      }
    }
    // Distinct visible toppings help identify even dishes in the same category.
    if (style == 'noodles' ||
        style == 'soup' ||
        style == 'custard' ||
        style == 'porridge') {
      if (recipe.ingredients.any((i) => i.name.contains('南瓜'))) {
        for (var i = 0; i < 7; i++) {
          _piece(c, 102 + i * 18.0, 100 + (i % 2) * 22, '南瓜', 'cubes', 0);
        }
      }
      if (recipe.ingredients.any((i) => i.name.contains('莲藕'))) {
        for (var i = 0; i < 5; i++) {
          _lotus(c, 100 + i * 27.0, 100 + i % 2 * 21.0);
        }
      }
    }
    for (var i = 0; i < 10; i++) {
      final x = 86 + (i * 37 % 149).toDouble(),
          y = 79 + (i * 23 % 58).toDouble();
      line(c, Offset(x, y), Offset(x + 4, y + 2), green, 3);
    }
    c.restore();
    // Plate highlights are restrained; food remains the visual focus.
    final rim = Path()
      ..addArc(
        Rect.fromCenter(
          center: const Offset(160, 108),
          width: 279,
          height: 145,
        ),
        math.pi + .2,
        .8,
      );
    c.drawPath(
      rim,
      paintBrush
        ..color = Colors.white
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  void _wholeFish(Canvas c) {
    final tail = Path()
      ..moveTo(241, 108)
      ..lineTo(270, 88)
      ..lineTo(265, 131)
      ..close();
    c.drawPath(
      tail,
      paintBrush
        ..color = const Color(0xFF7E958A)
        ..style = PaintingStyle.fill,
    );
    final fishColor = recipe.name.contains('红烧')
        ? const Color(0xFFB96838)
        : const Color(0xFF9BB0A0);
    oval(c, 157, 109, 186, 65, fishColor);
    oval(c, 85, 110, 46, 50, const Color(0xFF8BA092));
    oval(c, 78, 101, 9, 9, const Color(0xFF273B32));
    for (var i = 0; i < 6; i++) {
      line(
        c,
        Offset(112 + i * 19.0, 88),
        Offset(102 + i * 19.0, 123),
        const Color(0xFFCED7BB),
        3,
      );
    }
    for (var i = 0; i < 5; i++) {
      line(
        c,
        Offset(125 + i * 21.0, 92 + i % 2 * 17),
        Offset(152 + i * 20.0, 86 + i % 2 * 17),
        green,
        3,
      );
    }
  }

  void _lotus(Canvas c, double x, double y) {
    oval(c, x, y, 33, 24, cream);
    for (var j = 0; j < 6; j++) {
      final a = j * math.pi / 3;
      oval(
        c,
        x + math.cos(a) * 9,
        y + math.sin(a) * 6,
        5,
        4,
        const Color(0xFFB7A17B),
      );
    }
  }

  void _toppings(Canvas c) {
    final pork = recipe.tags.contains('猪肉');
    for (var i = 0; i < 14; i++) {
      _piece(
        c,
        98 + i * 9.0,
        90 + i % 3 * 13.0,
        pork
            ? '猪肉末'
            : recipe.tags.contains('鸡蛋')
            ? '鸡蛋'
            : '葱',
        pork ? 'cubes' : 'scramble',
        0,
      );
    }
    if (recipe.tags.contains('蔬菜')) {
      for (var i = 0; i < 5; i++) {
        _piece(c, 91 + i * 31.0, 132, '青菜', 'leaves', .3);
      }
    }
  }

  void _piece(
    Canvas c,
    double x,
    double y,
    String food,
    String form,
    double angle,
  ) {
    c.save();
    c.translate(x, y);
    c.rotate(angle);
    Color color = brown;
    if (food.contains('番茄') || food.contains('红椒')) {
      color = const Color(0xFFD95837);
    } else if (food.contains('胡萝卜') || food.contains('南瓜')) {
      color = const Color(0xFFEBA343);
    } else if (food.contains('土豆') ||
        food.contains('山药') ||
        food.contains('米') ||
        food.contains('面')) {
      color = cream;
    } else if (food.contains('豆腐') || food.contains('香干')) {
      color = const Color(0xFFE6C589);
    } else if (food.contains('鸡蛋')) {
      color = const Color(0xFFF1C64E);
    } else if (food.contains('茄子')) {
      color = const Color(0xFF78516D);
    } else if (food.contains('木耳')) {
      color = const Color(0xFF51413C);
    } else if (food.contains('菇')) {
      color = const Color(0xFFA88162);
    } else if (food.contains('青') ||
        food.contains('菜') ||
        food.contains('瓜') ||
        food.contains('韭') ||
        food.contains('豆')) {
      color = green;
    } else if (food.contains('虾')) {
      color = const Color(0xFFE48C66);
    } else if (food.contains('鸡') || food.contains('鱼')) {
      color = const Color(0xFFD4A578);
    }
    if (form == 'rice' || form == 'porridge') {
      oval(c, 0, 0, form == 'rice' ? 6 : 8, 3, color);
    } else if (food.contains('虾')) {
      final p = Path()
        ..addArc(const Rect.fromLTWH(-12, -10, 25, 21), .2, math.pi * 1.5);
      c.drawPath(
        p,
        paintBrush
          ..color = color
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke,
      );
      line(c, const Offset(11, 5), const Offset(16, 11), color, 5);
    } else if (food.contains('莲藕')) {
      _lotus(c, 0, 0);
    } else if (form == 'leaves' ||
        food.contains('青菜') ||
        food.contains('空心') ||
        food.contains('生菜') ||
        food.contains('菠菜')) {
      oval(c, 0, -3, 26, 16, color);
      line(
        c,
        const Offset(-9, 0),
        const Offset(16, 7),
        const Color(0xFF9BAE58),
        3,
      );
    } else if (form == 'broccoli' &&
        (food.contains('花') || food.contains('兰'))) {
      line(
        c,
        const Offset(0, 8),
        const Offset(0, -3),
        const Color(0xFFA8B47C),
        5,
      );
      for (var j = 0; j < 3; j++) {
        oval(
          c,
          j * 8 - 8,
          -4 - j % 2 * 5,
          16,
          14,
          food.contains('西兰') ? green : cream,
        );
      }
    } else if (form == 'wings' && food.contains('翅')) {
      final p = Path()
        ..moveTo(-18, 5)
        ..quadraticBezierTo(-18, -15, 3, -12)
        ..quadraticBezierTo(20, -5, 18, 8)
        ..quadraticBezierTo(7, 19, -18, 5)
        ..close();
      c.drawPath(
        p,
        paintBrush
          ..color = brown
          ..style = PaintingStyle.fill,
      );
      line(
        c,
        const Offset(-7, -4),
        const Offset(8, 6),
        const Color(0xFFD69A63),
        3,
      );
    } else if (food.contains('栗')) {
      oval(c, 0, 0, 23, 21, const Color(0xFFB58145));
      oval(c, 0, 6, 15, 7, const Color(0xFFE0BD7F));
    } else if (food.contains('菇') && !food.contains('木耳')) {
      line(c, const Offset(0, 0), const Offset(0, 12), cream, 5);
      oval(c, 0, -1, 27, 17, const Color(0xFF91654C));
      line(
        c,
        const Offset(-8, -4),
        const Offset(8, -4),
        const Color(0xFFC89A72),
        2,
      );
    } else if (form == 'beans' && food.contains('豆')) {
      line(c, const Offset(-16, -3), const Offset(17, 5), green, 7);
      for (var j = 0; j < 4; j++) {
        oval(c, -10 + j * 7.0, j * 1.5, 5, 5, const Color(0xFF92A651));
      }
    } else if (form == 'ribs' && food.contains('排骨')) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-18, -9, 37, 20),
          const Radius.circular(6),
        ),
        paintBrush
          ..color = brown
          ..style = PaintingStyle.fill,
      );
      line(c, const Offset(-14, 0), const Offset(16, 0), cream, 6);
    } else if (form == 'eggs') {
      oval(
        c,
        0,
        0,
        30,
        26,
        food.contains('鸡蛋') ? const Color(0xFFB07737) : color,
      );
    } else if (form == 'meatballs' && food.contains('肉')) {
      oval(c, 0, 0, 30, 26, brown);
      oval(c, -6, -5, 8, 4, const Color(0xFFBC815A));
    } else if (form == 'strips' || food.contains('粉丝') || food.contains('蒜苔')) {
      line(c, const Offset(-16, -3), const Offset(17, 5), color, 6);
    } else if (form == 'cucumber' && food.contains('黄瓜')) {
      oval(c, 0, 0, 27, 18, green);
      oval(c, 0, 0, 19, 12, const Color(0xFFCBDC8A));
    } else if (form == 'slices' ||
        form == 'eggplant' ||
        form == 'pumpkin' ||
        form == 'beans' ||
        form == 'peppers') {
      oval(c, 0, 0, 31, 14, color);
      line(
        c,
        const Offset(-8, -3),
        const Offset(8, -3),
        Color.lerp(color, Colors.white, .25)!,
        2,
      );
    } else {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: food.contains('肉末') ? 9 : 24,
            height: food.contains('肉末') ? 7 : 18,
          ),
          const Radius.circular(4),
        ),
        paintBrush
          ..color = color
          ..style = PaintingStyle.fill,
      );
      line(
        c,
        const Offset(-6, -5),
        const Offset(6, -5),
        Color.lerp(color, Colors.white, .25)!,
        2,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _DishPainter oldDelegate) =>
      oldDelegate.recipe.id != recipe.id;
}

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// An obstacle rendered as a cols×rows grid of ASCII characters.
/// Supports sizes from 1×1 up to 6×6. Collision hitbox covers the full area.
class ObstacleComponent extends PositionComponent with CollisionCallbacks {
  // Approximate monospace character cell at fontSize 16.
  static const double charW = 10.0;
  static const double charH = 18.0;
  static const double fontSize = 16.0;

  final String char;  // the single character to tile
  final int cols;     // 1-6
  final int rows;     // 1-6

  static final TextPaint _paint = TextPaint(
    style: const TextStyle(
      fontFamily: 'Courier',
      fontSize: fontSize,
      color: Colors.white,
      height: 1.0,
    ),
  );

  ObstacleComponent({
    required Vector2 position,
    required this.char,
    required this.cols,
    required this.rows,
  }) : super(
          position: position,
          size: Vector2(cols * charW, rows * charH),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Fill cols × rows grid with the chosen character.
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        add(
          TextComponent(
            text: char,
            textRenderer: _paint,
            position: Vector2(c * charW, r * charH),
          ),
        );
      }
    }

    // Solid hitbox for collision with player.
    add(RectangleHitbox(size: size, isSolid: true));
  }
}

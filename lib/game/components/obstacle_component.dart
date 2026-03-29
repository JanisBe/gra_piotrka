import 'dart:math';
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

  late final TextPaint _paint;

  static const List<Color> _obstacleColors = [
    Color(0xFFDE1040),
    Color(0xFF07F2C7),
    Color(0xFFE6FF05),
    Color(0xFF5BA0F5),
    Color(0xFFF77205),
  ];
  static final _random = Random();

  ObstacleComponent({
    required Vector2 position,
    required this.char,
    required this.cols,
    required this.rows,
  }) : super(
          position: position,
          size: Vector2(cols * charW, rows * charH),
        ) {
    final color = _obstacleColors[_random.nextInt(_obstacleColors.length)];
    _paint = TextPaint(
      style: TextStyle(
        fontFamily: 'Courier',
        fontSize: fontSize,
        color: color,
        height: 1.0,
      ),
    );
  }

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
    // Zmniejszamy hitbox, by kolizje nie były odczytywane przedwcześnie (margines na puste znaki)
    const shrinkY = 4.0;
    const shrinkX = 4.0;
    add(
      RectangleHitbox(
        size: Vector2(size.x - 2 * shrinkX, size.y - 2 * shrinkY),
        position: Vector2(shrinkX, shrinkY),
        isSolid: true,
      ),
    );
  }

  void takeHit(double hitY) {
    // 60px hole centered at hitY 
    final holeTop = hitY - 30; // Absolute Y
    final holeBottom = hitY + 30; // Absolute Y

    final myTop = position.y;
    final myBottom = position.y + size.y;

    // We split into top piece and bottom piece
    // Top piece goes from myTop to holeTop
    if (holeTop > myTop + charH) {
      final topRows = ((holeTop - myTop) / charH).floor();
      if (topRows > 0) {
        parent?.add(ObstacleComponent(
          position: Vector2(position.x, position.y),
          char: char,
          cols: cols,
          rows: topRows,
        ));
      }
    }

    // Bottom piece goes from holeBottom to myBottom
    if (myBottom > holeBottom + charH) {
      final bottomRows = ((myBottom - holeBottom) / charH).floor();
      if (bottomRows > 0) {
        // bottom Y
        final bottomPieceY = myBottom - (bottomRows * charH);
        parent?.add(ObstacleComponent(
          position: Vector2(position.x, bottomPieceY),
          char: char,
          cols: cols,
          rows: bottomRows,
        ));
      }
    }

    // Replace myself with the pieces
    removeFromParent();
  }
}


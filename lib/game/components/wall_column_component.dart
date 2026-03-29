import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// A wall column rendered as a vertical strip of '#' characters.
/// Each column has a RectangleHitbox so the player can collide with it.
class WallColumnComponent extends PositionComponent with CollisionCallbacks {
  static final TextPaint _wallPaint = TextPaint(
    style: const TextStyle(
      fontFamily: 'Courier',
      fontSize: 14,
      color: Colors.white,
      height: 1.0,
    ),
  );

  late final RectangleHitbox _hitbox;

  WallColumnComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Build a column of '#' characters.
    final rows = (size.y / 14).ceil();
    for (var i = 0; i < rows; i++) {
      add(
        TextComponent(
          text: '#',
          textRenderer: _wallPaint,
          position: Vector2(0, i * 14.0),
        ),
      );
    }

    _hitbox = RectangleHitbox(size: size, isSolid: true);
    await add(_hitbox);
  }
}

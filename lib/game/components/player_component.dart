import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:gra_piotrka/game/corridor_game.dart';

/// ASCII airplane controlled by the player.
/// Supports on-screen buttons AND arrow keys (via Flutter Focus in _GamePage).
class PlayerComponent extends PositionComponent with CollisionCallbacks {
  static const double _verticalSpeed = 220;

  bool _movingUp = false;
  bool _movingDown = false;

  final CorridorGame gameRef;

  static const double _fontSize = 20;
  static const double _glyphWidth = 80;
  static const double _glyphHeight = 24;

  PlayerComponent({
    required this.gameRef,
    required double startX,
    required double startY,
  }) : super(
          position: Vector2(startX, startY),
          size: Vector2(_glyphWidth, _glyphHeight),
          anchor: Anchor.centerLeft,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final paint = TextPaint(
      style: const TextStyle(
        fontFamily: 'Courier',
        fontSize: _fontSize,
        color: Colors.white,
        height: 1.2,
      ),
    );

    await add(
      TextComponent(
        text: '>==>', 
        textRenderer: paint,
        anchor: Anchor.centerLeft,
        position: Vector2(0, _glyphHeight / 2),
      ),
    );

    await add(
      RectangleHitbox(
        size: Vector2(_glyphWidth, _glyphHeight - 8),
        position: Vector2(0, 4),
        anchor: Anchor.topLeft,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    final topMargin = gameRef.corridorGenerator.topMargin;
    final bottomMargin = gameRef.corridorGenerator.bottomMargin;
    final minY = topMargin + _glyphHeight;
    final maxY = gameRef.size.y - bottomMargin - _glyphHeight;

    if (_movingUp) {
      position.y = (position.y - _verticalSpeed * dt).clamp(minY, maxY);
    }
    if (_movingDown) {
      position.y = (position.y + _verticalSpeed * dt).clamp(minY, maxY);
    }
  }

  // ── on-screen button callbacks ─────────────────────────────────────────────
  void startMovingUp() => _movingUp = true;
  void stopMovingUp() => _movingUp = false;
  void startMovingDown() => _movingDown = true;
  void stopMovingDown() => _movingDown = false;

// ── collision ──────────────────────────────────────────────────────────────
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    gameRef.triggerGameOver();
  }
}

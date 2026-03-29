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

    final tailPaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'Courier',
        fontSize: _fontSize,
        color: Colors.yellow,
        height: 1.2,
      ),
    );
    final bodyPaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'Courier',
        fontSize: _fontSize,
        color: Colors.orange,
        height: 1.2,
      ),
    );
    final nosePaint = TextPaint(
      style: const TextStyle(
        fontFamily: 'Courier',
        fontSize: _fontSize,
        color: Colors.red,
        height: 1.2,
      ),
    );

    final tailComp = TextComponent(
      text: '>',
      textRenderer: tailPaint,
      anchor: Anchor.centerLeft,
    );
    final bodyComp = TextComponent(
      text: '==',
      textRenderer: bodyPaint,
      anchor: Anchor.centerLeft,
    );
    final noseComp = TextComponent(
      text: '>',
      textRenderer: nosePaint,
      anchor: Anchor.centerLeft,
    );

    tailComp.position = Vector2(0, _glyphHeight / 2);
    bodyComp.position = Vector2(tailComp.size.x, _glyphHeight / 2);
    noseComp.position =
        Vector2(tailComp.size.x + bodyComp.size.x, _glyphHeight / 2);

    await add(tailComp);
    await add(bodyComp);
    await add(noseComp);

    await add(
      RectangleHitbox(
        // Zmniejszamy hitbox statku by obejmował faktyczny znak '>==>' (okrągło 45x12px).
        size: Vector2(45, 12),
        position: Vector2(2, 6),
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

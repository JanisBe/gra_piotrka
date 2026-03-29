import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:gra_piotrka/game/components/obstacle_component.dart';

class BulletComponent extends PositionComponent with CollisionCallbacks {
  static const double _speed = 400.0;
  
  BulletComponent({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(30, 24),
          anchor: Anchor.centerLeft,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final paint = TextPaint(
      style: const TextStyle(
        fontFamily: 'Courier',
        fontSize: 20,
        color: Colors.white, // Pocisk jako jasny znak
        height: 1.2,
      ),
    );

    await add(
      TextComponent(
        text: '->',
        textRenderer: paint,
      ),
    );

    await add(
      RectangleHitbox(
        size: Vector2(25, 10),
        position: Vector2(0, 8),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Zapiernicz do przodu
    position.x += _speed * dt;

    // Usuń jak wyleci poza ekran
    if (position.x > 1500) { // Wystarczający margines, by zniknęło poza ekranem
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is ObstacleComponent) {
      removeFromParent(); // Destroy bullet
      other.takeHit(position.y); // Create hole
    }
  }
}

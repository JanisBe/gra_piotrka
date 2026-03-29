import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gra_piotrka/game/components/corridor_generator.dart';
import 'package:gra_piotrka/game/components/player_component.dart';
import 'package:gra_piotrka/game/components/explosion_component.dart';
import 'package:gra_piotrka/game/components/bullet_component.dart';

abstract class GameObserver {
  void onGameUpdate();
}

/// Main Flame game class.
class CorridorGame extends FlameGame with HasCollisionDetection {
  final int level;
  final VoidCallback onExit;
  final VoidCallback onNextLevel;
  final int initialBullets;

  static const double levelDurationSeconds = 50.0;
  double _elapsed = 0;
  double get progress => (_elapsed / levelDurationSeconds).clamp(0.0, 1.0);
  bool _levelComplete = false;
  bool _gameOver = false;

  double _shakeTimer = 0;
  final double _shakeDuration = 0.4;
  final double _shakeMagnitude = 6.0;
  final Random _rng = Random();

  int bullets = 10;

  // NOTE: NOT final – must be reassignable on restart.
  late PlayerComponent player;
  late CorridorGenerator corridorGenerator;

  final List<GameObserver> _observers = [];
  void addObserver(GameObserver o) => _observers.add(o);
  void removeObserver(GameObserver o) => _observers.remove(o);

  CorridorGame({
    required this.level,
    required this.onExit,
    required this.onNextLevel,
    required this.initialBullets,
  }) {
    bullets = initialBullets;
  }

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    corridorGenerator = CorridorGenerator(level: level);
    await add(corridorGenerator);
    player = PlayerComponent(
      gameRef: this,
      startX: size.x * 0.20,
      startY: size.y * 0.50,
    );
    await add(player);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver || _levelComplete) return;

    _elapsed += dt;

    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      camera.viewfinder.position = Vector2(
        _rng.nextDouble() * _shakeMagnitude * 2 - _shakeMagnitude,
        _rng.nextDouble() * _shakeMagnitude * 2 - _shakeMagnitude,
      );
    } else {
      camera.viewfinder.position = Vector2.zero();
    }

    // Iterate over a copy so observers can be removed during notification.
    for (final o in List.of(_observers)) {
      o.onGameUpdate();
    }

    if (_elapsed >= levelDurationSeconds) {
      _triggerLevelComplete();
    }
  }

  /// Arrow-key handling forwarded from Flutter's keyboard.
  void onArrowKey(LogicalKeyboardKey key, bool pressed) {
    if (_gameOver || _levelComplete) return;
    if (key == LogicalKeyboardKey.arrowUp) {
      pressed ? player.startMovingUp() : player.stopMovingUp();
    } else if (key == LogicalKeyboardKey.arrowDown) {
      pressed ? player.startMovingDown() : player.stopMovingDown();
    }
  }

  void triggerGameOver() {
    if (_gameOver || _levelComplete) return;
    _gameOver = true;
    _shakeTimer = _shakeDuration;

    // Spawn ASCII explosion at player position
    add(ExplosionComponent(position: player.position.clone()));

    // Remove the player so it looks like they exploded
    player.removeFromParent();

    Future.delayed(const Duration(milliseconds: 800), () {
      overlays.remove('hud');
      overlays.add('gameOver');
      pauseEngine();
    });
  }

  void _triggerLevelComplete() {
    _levelComplete = true;
    overlays.remove('hud');
    overlays.add('levelComplete');
    pauseEngine();
  }

  void restartGame() {
    _elapsed = 0;
    _gameOver = false;
    _levelComplete = false;
    _shakeTimer = 0;
    bullets = initialBullets; // Reset to what it was at start of level
    camera.viewfinder.position = Vector2.zero();

    removeAll(children.toList());

    corridorGenerator = CorridorGenerator(level: level);
    add(corridorGenerator);
    player = PlayerComponent(
      gameRef: this,
      startX: size.x * 0.20,
      startY: size.y * 0.50,
    );
    add(player);

    overlays.add('hud');
    resumeEngine();
  }

  void fireBullet() {
    if (bullets > 0 && !_gameOver && !_levelComplete) {
      bullets--;
      // Spawn bullet at player's nose
      add(
        BulletComponent(
          position: player.position.clone()..add(Vector2(player.size.x, 0)),
        ),
      );
    }
  }
}

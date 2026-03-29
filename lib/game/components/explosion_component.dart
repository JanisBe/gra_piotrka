import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// A burst of ASCII characters that scatters from a point.
/// Automatically removes itself once all effects are finished.
class ExplosionComponent extends PositionComponent {
  static final Random _rng = Random();
  static const List<String> _chars = ['*', '#', '@', '%', '+', '!', '?', 'O'];
  static const List<Color> _colors = [
    Colors.yellow,
    Colors.orange,
    Colors.orangeAccent,
    Color(0xFFFFD700), // Gold
  ];

  ExplosionComponent({required Vector2 position}) : super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Spawn 20-30 individual particle characters
    final particleCount = 25 + _rng.nextInt(10);

    for (var i = 0; i < particleCount; i++) {
      final char = _chars[_rng.nextInt(_chars.length)];
      final color = _colors[_rng.nextInt(_colors.length)];

      // Random direction and distance
      final angle = _rng.nextDouble() * 2 * pi;
      final distance = 40.0 + _rng.nextDouble() * 100.0;
      final target = Vector2(cos(angle) * distance, sin(angle) * distance);

      final particle = _FadingTextComponent(
        text: char,
        textRenderer: TextPaint(
          style: TextStyle(
            color: color,
            fontSize: 14.0 + _rng.nextDouble() * 12.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
        anchor: Anchor.center,
      );

      await add(particle);

      // Add movement, fade, and scale effects
      particle.add(
        MoveEffect.to(
          target,
          EffectController(
            duration: 0.5 + _rng.nextDouble() * 0.3,
            curve: Curves.easeOutCubic,
          ),
        ),
      );

      particle.add(
        OpacityEffect.fadeOut(
          EffectController(
            duration: 0.4 + _rng.nextDouble() * 0.4,
            startDelay: 0.1,
          ),
        ),
      );

      particle.add(
        ScaleEffect.by(
          Vector2.all(0.5),
          EffectController(
            duration: 0.6,
          ),
        ),
      );
    }

    // Auto-remove the whole explosion after the longest possible effect duration
    add(
      RemoveEffect(
        delay: 0.9,
      ),
    );
  }
}

/// Helper component that allows OpacityEffect to work with TextComponent.
class _FadingTextComponent extends TextComponent implements OpacityProvider {
  _FadingTextComponent({
    required super.text,
    required super.textRenderer,
    required super.anchor,
  });

  @override
  double get opacity => (textRenderer as TextPaint).style.color?.a ?? 1.0;

  @override
  set opacity(double value) {
    textRenderer = (textRenderer as TextPaint).copyWith(
      (style) => style.copyWith(color: style.color?.withValues(alpha: value)),
    );
  }
}

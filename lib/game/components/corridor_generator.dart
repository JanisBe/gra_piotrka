import 'dart:math';
import 'package:flame/components.dart';
import 'package:gra_piotrka/game/components/obstacle_component.dart';
import 'package:gra_piotrka/game/components/wall_column_component.dart';

/// Procedurally generates and scrolls wall columns + obstacles.
/// Uses [HasGameReference] so it can read the screen dimensions at runtime.
class CorridorGenerator extends Component with HasGameReference {
  final int level;

  late final double scrollSpeed;
  late final double wallHeight;
  late final double obstacleChance;

  /// Width of each wall column tile in px.
  static const double columnWidth = 20;

  /// Minimum number of columns between consecutive obstacles.
  static const int _minColsBetweenObstacles = 2;

  final Random _rng = Random();

  /// Virtual X position of the next column to spawn (screen coords,
  /// decremented by scroll each frame so it stays aligned with the right edge).
  double _nextColumnX = 0;

  /// Column count since the last obstacle was placed.
  int _colsSinceObstacle = 0;

  double get topMargin => wallHeight;
  double get bottomMargin => wallHeight;

  CorridorGenerator({required this.level}) {
    scrollSpeed = 150 + (level - 1) * 30.0;
    wallHeight = (60 + (level - 1) * 15.0).clamp(60.0, 200.0);
    obstacleChance = (0.35 + (level - 1) * 0.05).clamp(0.35, 0.75);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _nextColumnX = 0;
    _colsSinceObstacle = 0;
    _fillScreen();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final moved = scrollSpeed * dt;

    // Scroll all children left.
    for (final child in children) {
      if (child is PositionComponent) {
        child.position.x -= moved;
      }
    }

    // Remove fully off-screen children.
    removeAll(
      children
          .where((c) => c is PositionComponent && c.position.x + columnWidth < 0)
          .toList(),
    );

    // Advance the virtual spawn pointer by the same amount as the scroll,
    // then spawn new columns until the right-side buffer is filled.
    _nextColumnX -= moved;
    final screenW = game.size.x;
    while (_nextColumnX < screenW + columnWidth * 2) {
      _nextColumnX += columnWidth;
      _spawnColumn(_nextColumnX);
    }
  }

  void _fillScreen() {
    final screenW = game.size.x;
    while (_nextColumnX < screenW + columnWidth) {
      _nextColumnX += columnWidth;
      _spawnColumn(_nextColumnX);
    }
  }

  void _spawnColumn(double x) {
    final screenH = game.size.y;

    add(WallColumnComponent(
      position: Vector2(x, 0),
      size: Vector2(columnWidth, wallHeight),
    ));
    add(WallColumnComponent(
      position: Vector2(x, screenH - wallHeight),
      size: Vector2(columnWidth, wallHeight),
    ));

    // Obstacle inside the gap, gated by:
    // 1. Safe zone (don't spawn at the start)
    // 2. Gap size
    // 3. Column counter
    // 4. Random chance
    final gapStart = wallHeight;
    final gapEnd = screenH - wallHeight;
    final gapSize = gapEnd - gapStart;

    final safeZoneX = game.size.x * 0.4;
    _colsSinceObstacle++;
    if (x > safeZoneX &&
        gapSize > 60 &&
        _colsSinceObstacle >= _minColsBetweenObstacles &&
        _rng.nextDouble() < obstacleChance) {
      _colsSinceObstacle = 0;
      _spawnObstacle(x, gapStart, gapSize);
    }
  }

  void _spawnObstacle(double x, double gapStart, double gapSize) {
    const chars = ['X', '#', '+', '@', '=', '*', 'O', '%'];
    final char = chars[_rng.nextInt(chars.length)];

    // Random size 1–6 cols and 1–6 rows (ASCII char grid).
    final cols = _rng.nextInt(6) + 1;
    final rows = _rng.nextInt(6) + 1;
    final h = rows * ObstacleComponent.charH;

    // Ensure obstacle fits inside the gap with some breathing room.
    if (h >= gapSize - 20) return;

    final cy = gapStart + _rng.nextDouble() * (gapSize - h - 10);

    add(ObstacleComponent(
      position: Vector2(x, cy),
      char: char,
      cols: cols,
      rows: rows,
    ));
  }
}

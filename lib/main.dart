import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gra_piotrka/game/corridor_game.dart';
import 'package:gra_piotrka/screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const AirplaneApp());
}

class AirplaneApp extends StatefulWidget {
  const AirplaneApp({super.key});

  @override
  State<AirplaneApp> createState() => _AirplaneAppState();
}

class _AirplaneAppState extends State<AirplaneApp> {
  bool _gameStarted = false;
  int _currentLevel = 1;
  int _bullets = 10;

  void _startGame(int level, {int carriedBullets = 0}) {
    setState(() {
      _currentLevel = level;
      _gameStarted = true;
      if (level == 1) {
        _bullets = 10;
      } else {
        _bullets = carriedBullets + 10;
      }
    });
  }

  void _exitToMenu() {
    setState(() {
      _gameStarted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gra Piotrka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          surface: Colors.black,
          primary: Colors.white,
        ),
      ),
      home: _gameStarted
          ? _GamePage(
              key: ValueKey(_currentLevel),
              level: _currentLevel,
              initialBullets: _bullets,
              onExit: _exitToMenu,
              onNextLevel: (remaining) =>
                  _startGame(_currentLevel + 1, carriedBullets: remaining),
            )
          : MainMenuScreen(onStart: () => _startGame(1)),
    );
  }
}

/// Widget that hosts the Flame game with Flutter overlays.
class _GamePage extends StatefulWidget {
  final int level;
  final int initialBullets;
  final VoidCallback onExit;
  final void Function(int) onNextLevel;

  const _GamePage({
    super.key,
    required this.level,
    required this.initialBullets,
    required this.onExit,
    required this.onNextLevel,
  });

  @override
  State<_GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<_GamePage> {
  late CorridorGame _game;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _game = CorridorGame(
      level: widget.level,
      onExit: widget.onExit,
      onNextLevel: () => widget.onNextLevel(_game.bullets),
      initialBullets: widget.initialBullets,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: _game,
      focusNode: _focusNode,
      autofocus: true,
      overlayBuilderMap: {
        'hud': (context, game) {
          final g = game as CorridorGame;
          return _HudOverlay(game: g);
        },
        'gameOver': (context, game) {
          final g = game as CorridorGame;
          return _GameOverOverlay(
            onRestart: () {
              g.overlays.remove('gameOver');
              g.restartGame();
            },
            onExit: widget.onExit,
          );
        },
        'levelComplete': (context, game) {
          final g = game as CorridorGame;
          return _LevelCompleteOverlay(
            onNextLevel: () {
              g.overlays.remove('levelComplete');
              widget.onNextLevel(g.bullets);
            },
            onExit: widget.onExit,
          );
        },
      },
      initialActiveOverlays: const ['hud'],
    );
  }

}

// ---------------------------------------------------------------------------
// HUD Overlay: progress bar + up/down buttons
// ---------------------------------------------------------------------------
class _HudOverlay extends StatefulWidget {
  final CorridorGame game;
  const _HudOverlay({required this.game});

  @override
  State<_HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<_HudOverlay> implements GameObserver {
  @override
  void initState() {
    super.initState();
    // Rebuild the HUD every frame so the progress bar animates.
    widget.game.addObserver(this);
  }

  @override
  void dispose() {
    widget.game.removeObserver(this);
    super.dispose();
  }

  /// Called by the game to signal a repaint is needed.
  @override
  void onGameUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    return SafeArea(
      child: Stack(
        children: [
          // -------- Progress bar --------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ProgressBar(progress: widget.game.progress),
          ),
          // -------- Level label --------
          Positioned(
            top: 28,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'LEVEL ${widget.game.level}',
                style: const TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          // -------- Ammo label --------
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'AMUNICJA: ${widget.game.bullets}',
                style: const TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.white,
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (isMobile) ...[
            // -------- UP button --------
            Positioned(
              bottom: 114,
              right: 24,
              child: _GameButton(
                label: '▲ GÓRA',
                onDown: () => widget.game.player.startMovingUp(),
                onUp: () => widget.game.player.stopMovingUp(),
              ),
            ),
            // -------- DOWN button --------
            Positioned(
              bottom: 24,
              right: 24,
              child: _GameButton(
                label: '▼ DÓŁ',
                onDown: () => widget.game.player.startMovingDown(),
                onUp: () => widget.game.player.stopMovingDown(),
              ),
            ),
            // -------- FIRE button --------
            Positioned(
              bottom: 24,
              left: 24,
              child: _GameButton(
                label: 'OGIEŃ',
                onDown: () => widget.game.fireBullet(),
                onUp: () {},
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(color: Colors.white24),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontFamily: 'Courier',
                color: Colors.white,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameButton extends StatelessWidget {
  final String label;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const _GameButton({
    required this.label,
    required this.onDown,
    required this.onUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54, width: 1.5),
          color: Colors.white10,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Courier',
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game Over Overlay
// ---------------------------------------------------------------------------
class _GameOverOverlay extends StatelessWidget {
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _GameOverOverlay({required this.onRestart, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        color: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'KOOONIEC',
              style: TextStyle(
                fontFamily: 'Courier',
                color: Colors.white,
                fontSize: 32,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 32),
            _MenuButton(label: 'JESZCZE RAZ', onTap: onRestart),
            const SizedBox(height: 16),
            _MenuButton(label: 'MENU', onTap: onExit),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level Complete Overlay
// ---------------------------------------------------------------------------
class _LevelCompleteOverlay extends StatelessWidget {
  final VoidCallback onNextLevel;
  final VoidCallback onExit;

  const _LevelCompleteOverlay({
    required this.onNextLevel,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        color: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'BRAWO!',
              style: TextStyle(
                fontFamily: 'Courier',
                color: Colors.white,
                fontSize: 40,
                letterSpacing: 10,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'POZIOM UKOŃCZONY',
              style: TextStyle(
                fontFamily: 'Courier',
                color: Colors.white54,
                fontSize: 16,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 32),
            _MenuButton(label: 'NASTĘPNY POZIOM', onTap: onNextLevel),
            const SizedBox(height: 16),
            _MenuButton(label: 'MENU', onTap: onExit),
          ],
        ),
      ),
    );
  }
}

/// Reusable bordered text button for overlays.
class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54, width: 1.5),
          color: Colors.white10,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Courier',
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

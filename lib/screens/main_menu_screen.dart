import 'dart:io' show exit;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen main menu with ASCII art title and START / EXIT buttons.
class MainMenuScreen extends StatefulWidget {
  final VoidCallback onStart;

  const MainMenuScreen({super.key, required this.onStart});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;
  late final Animation<double> _blink;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _blink = CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000000),
              Color(0xFF0A0A0A),
              Color(0xFF1A1A1A),
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ASCII title art
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: _FancyAsciiArt(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '>===>  SAMOLOTY  <===<',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _blink,
                  child: Text(
                    '~ Moja gra o lataniu samolotem ~',
                    style: GoogleFonts.robotoMono(
                      color: Colors.white54,
                      fontSize: 13,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _AsciiButton(label: '[ START ]', onTap: widget.onStart),
                const SizedBox(height: 24),
                _AsciiButton(
                  label: '[ KONIEC ]',
                  onTap: () => exit(0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FancyAsciiArt extends StatelessWidget {
  const _FancyAsciiArt();

  static const List<String> _lines = [
    ' ██████╗ ██████╗  █████╗     ██████╗ ██╗ ██████╗ ████████╗██████╗ ██╗  ██╗ █████╗ ',
    '██╔════╝ ██╔══██╗██╔══██╗    ██╔══██╗██║██╔═══██╗╚══██╔══╝██╔══██╗██║ ██╔╝██╔══██╗',
    '██║  ███╗██████╔╝███████║    ██████╔╝██║██║   ██║   ██║   ██████╔╝█████╔╝ ███████║',
    '██║   ██║██╔══██╗██╔══██║    ██╔═══╝ ██║██║   ██║   ██║   ██╔══██╗██╔═██╗ ██╔══██║',
    '╚██████╔╝██║  ██║██║  ██║    ██║     ██║╚██████╔╝   ██║   ██║  ██║██║  ██╗██║  ██║',
    ' ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _lines.map((line) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: line.split('').map((char) {
            return SizedBox(
              width: 10,
              height: 12,
              child: Center(
                child: Text(
                  char,
                  style: GoogleFonts.robotoMono(
                    color: Colors.white,
                    fontSize: 10,
                    height: 1.0,
                    fontWeight:
                        char == '█' ? FontWeight.bold : FontWeight.normal,
                    shadows: char == '█'
                        ? [
                            const Shadow(
                              color: Colors.white38,
                              blurRadius: 4,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _AsciiButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AsciiButton({required this.label, required this.onTap});

  @override
  State<_AsciiButton> createState() => _AsciiButtonState();
}

class _AsciiButtonState extends State<_AsciiButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _pressed ? Colors.white : Colors.white54,
            width: 1.5,
          ),
          color: _pressed ? Colors.white12 : Colors.transparent,
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.robotoMono(
            color: _pressed ? Colors.white : Colors.white70,
            fontSize: 20,
            letterSpacing: 5,
          ),
        ),
      ),
    );
  }
}

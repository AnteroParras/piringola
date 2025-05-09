import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'GamePainter.dart';
import 'frutaBase.dart';
import 'frutas.dart';


class GameScreen extends StatefulWidget {
  final String mode;
  const GameScreen({super.key, required this.mode});
  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  static const int rows = 20, cols = 20;
  final Duration tickRate = const Duration(milliseconds: 200);
  late List<Point<int>> snake;
  late Point<int> dir;
  late Fruta fruta;
  Timer? timer;
  bool paused = false;
  bool gameOver = false;
  int growQueue = 0;
  int score = 0;
  bool invertirControles = false;
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startGame();
    RawKeyboard.instance.addListener(_onKey);
  }

  @override
  void dispose() {
    timer?.cancel();
    RawKeyboard.instance.removeListener(_onKey);
    super.dispose();
  }

  void _startGame() {
    snake = [const Point(10, 10)];
    dir = const Point(0, -1);
    score = 0;
    gameOver = false;
    paused = false;
    growQueue = 0;
    fruta = _genFruta();
    timer?.cancel();
    timer = Timer.periodic(tickRate, (_) => _tick());
    focusNode.requestFocus();
  }

  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey.keyLabel.toLowerCase();
      final inv = invertirControles;
      Point<int> newDir = dir;
      if (key == 'w') newDir = inv ? const Point(0, 1) : const Point(0, -1);
      if (key == 's') newDir = inv ? const Point(0, -1) : const Point(0, 1);
      if (key == 'a') newDir = inv ? const Point(1, 0) : const Point(-1, 0);
      if (key == 'd') newDir = inv ? const Point(-1, 0) : const Point(1, 0);
      if ((newDir.x + dir.x != 0) || (newDir.y + dir.y != 0)) {
        setState(() => dir = newDir);
      }
    }
  }

  void _tick() {
    if (paused || gameOver) return;
    setState(() {
      final next = Point(
        (snake.first.x + dir.x + cols) % cols,
        (snake.first.y + dir.y + rows) % rows,
      );
      if (snake.contains(next)) {
        gameOver = true;
        timer?.cancel();
        _gameOverDialog();
        return;
      }
      snake.insert(0, next);
      if (next == fruta.posicion) {
        fruta.aplicarEfecto(this);
        fruta = _genFruta();
      }
      if (growQueue > 0) {
        growQueue--;
      } else {
        snake.removeLast();
      }
    });
  }

  Fruta _genFruta() {
    final rand = Random();
    Point<int> p;
    do {
      p = Point(rand.nextInt(cols), rand.nextInt(rows));
    } while (snake.contains(p));
    switch (widget.mode) {
      case 'rojo':
        return FrutaRoja(p);
      case 'azul':
        return FrutaAzul(p);
      case 'amarillo':
        return FrutaAmarilla(p);
      case 'random':
        cargarFrutas();
        return Fruta.generarFrutaRandom(p);
      default:
        return FrutaRoja(p);
    }
  }

  void invertDirections() {
    setState(() {
      invertirControles = !invertirControles;
    });
  }

  void _gameOverDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Puntuación: $score'),
            TextField(
              controller: controller,
              maxLength: 3,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Tus iniciales'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _saveScore(controller.text.toUpperCase());
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveScore(String initials) async {
    final prefs = await SharedPreferences.getInstance();
    final scores = prefs.getStringList('highScores') ?? [];
    scores.add(jsonEncode({'initials': initials, 'score': score}));
    await prefs.setStringList('highScores', scores);
  }

  void _togglePause() {
    setState(() {
      paused = !paused;
    });
  }

  void _promptExit() {
    setState(() => paused = true);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Salir del juego'),
        content: const Text('¿Estás seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final squareSize = min(MediaQuery.of(context).size.width / cols,
        MediaQuery.of(context).size.height / rows);
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: cols * squareSize,
                height: rows * squareSize,
                child: CustomPaint(
                  painter: GamePainter(
                      snake: snake,
                      fruta: fruta,
                      squareSize: squareSize),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Text(
                'Puntos: $score',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildGameBoyControls(),
            )
          ],
        ),
        onKey: (event) => _onKey(event),
      ),
    );
  }


  Widget _buildGameBoyControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: () => _changeDirWithInvert(const Point(0, -1)),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _changeDirWithInvert(const Point(-1, 0)),
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => _changeDirWithInvert(const Point(1, 0)),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              onPressed: () => _changeDirWithInvert(const Point(0, 1)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: _togglePause, child: const Text('Start')),
            ElevatedButton(onPressed: _togglePause, child: const Text('Select')),
            ElevatedButton(onPressed: () {}, child: const Text('A')),
            ElevatedButton(onPressed: _promptExit, child: const Text('B')),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _changeDirWithInvert(Point<int> newDir) {
    final inv = invertirControles;
    final dirToSet = inv
        ? Point(-newDir.x, -newDir.y)
        : newDir;
    if ((dirToSet.x + dir.x != 0) || (dirToSet.y + dir.y != 0)) {
      setState(() => dir = dirToSet);
    }
  }
}

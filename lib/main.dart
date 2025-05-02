import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SnakeGameApp());

// CLASE BASE FRUTA Y SUBCLASES
abstract class Fruta {
  Point<int> posicion;
  Color color;
  Fruta(this.posicion, this.color);
  void aplicarEfecto(_GameScreenState state);
}

class FrutaRoja extends Fruta {
  FrutaRoja(Point<int> posicion) : super(posicion, Colors.redAccent);
  @override
  void aplicarEfecto(_GameScreenState state) {
    state.score++;
    state.growQueue += 1;

    // Crece por 1 (la inserción de la cabeza ya lo hace)
  }
}

class FrutaAzul extends Fruta {
  FrutaAzul(Point<int> posicion) : super(posicion, Colors.blueAccent);
  @override
  void aplicarEfecto(_GameScreenState state) {
    state.score++;
    // Invierte controles
    state._invertDirections();
    state.growQueue += 1;
  }
}

class FrutaAmarilla extends Fruta {
  FrutaAmarilla(Point<int> posicion) : super(posicion, Colors.yellowAccent);
  @override
  void aplicarEfecto(_GameScreenState state) {
    state.score++;
    // Crecer aleatorio 1-3 bloques adicionales
    final extra = Random().nextInt(3) + 1;
    state.growQueue += extra;
  }
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Snake Game',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
    home: const MainMenu(),
  );
}

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});
  void _start(BuildContext c, String mode) => Navigator.push(
      c,
      MaterialPageRoute(
        builder: (_) => GameScreen(mode: mode),
      ));

  Future<List<Map<String, dynamic>>> _getScores() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('highScores') ?? [])
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  void _showScores(BuildContext c) async {
    final list = await _getScores();
    list.sort((a, b) => b['score'].compareTo(a['score']));
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('Top 10 Puntuaciones'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: min(10, list.length),
            itemBuilder: (ctx, i) {
              final e = list[i];
              return ListTile(
                leading: Text('${i + 1}'),
                title: Text(e['initials']),
                trailing: Text('${e['score']}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SNAKE GAME',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _start(context, 'rojo'),
            child: const Text('Frutas Rojas'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _start(context, 'azul'),
            child: const Text('Frutas Azules'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _start(context, 'amarillo'),
            child: const Text('Frutas Amarillas'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _start(context, 'random'),
            child: const Text('Modo Aleatorio'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showScores(context),
            child: const Text('Top Puntuaciones'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Salir'),
          ),
        ],
      ),
    ),
  );
}

class GameScreen extends StatefulWidget {
  final String mode;
  const GameScreen({super.key, required this.mode});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
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
        final t = rand.nextInt(3);
        return t == 0
            ? FrutaRoja(p)
            : t == 1
            ? FrutaAzul(p)
            : FrutaAmarilla(p);
      default:
        return FrutaRoja(p);
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

  void _invertDirections() {
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
                  painter: _GamePainter(
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

class _GamePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Fruta fruta;
  final double squareSize;

  _GamePainter({required this.snake, required this.fruta, required this.squareSize});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF1E1E1E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final paintSnake = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.greenAccent;
    for (final s in snake) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s.x * squareSize, s.y * squareSize, squareSize, squareSize),
          const Radius.circular(4),
        ),
        paintSnake,
      );
    }

    final paintFruit = Paint()..color = fruta.color;
    final p = fruta.posicion;
    canvas.drawOval(
      Rect.fromLTWH(p.x * squareSize, p.y * squareSize, squareSize, squareSize),
      paintFruit,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
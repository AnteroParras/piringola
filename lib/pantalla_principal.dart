import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'GameScreen.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: PaginaPrincipalState(onToggleTheme: _toggleTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PaginaPrincipalState extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const PaginaPrincipalState({super.key, required this.onToggleTheme});

  @override
  State<PaginaPrincipalState> createState() => _PaginaPrincipalStateState();
}

class _PaginaPrincipalStateState extends State<PaginaPrincipalState> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _tiltController;
  late Animation<double> _tiltAnimation;
  late AudioPlayer _audioPlayer;

  bool _isMuted = false;
  bool girl = false;

  String get _videoAsset => girl ? 'ContenidoVisual/introgirl.mp4' : 'ContenidoVisual/videointro.mp4';
  String get _musicAsset => girl ? 'ContenidoVisual/Girl.wav' : 'ContenidoVisual/RICK.wav';

  void _start(BuildContext c, String mode) => Navigator.push(
      c,
      MaterialPageRoute(
        builder: (_) => GameScreen(mode: mode),
      ));

  @override
  void initState() {
    super.initState();

    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _tiltAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _tiltController, curve: Curves.easeInOut));

    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    _initVideoAndMusic();
  }

  Future<void> _initVideoAndMusic() async {
    // Inicializa el video
    _controller = VideoPlayerController.asset(_videoAsset);

    // Escucha el estado
    _controller.addListener(() {
      if (_controller.value.isInitialized && !_controller.value.isPlaying) {
        _controller.play();  // Asegúrate de que empiece a reproducirse si no lo está
        setState(() {});     // Forzar reconstrucción del widget
      }
    });

    await _controller.initialize();
    _controller.setLooping(true);
    await _controller.play();
    setState(() {});

  }


  @override
  void dispose() {
    _controller.dispose();
    _tiltController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
      _audioPlayer.setVolume(_isMuted ? 0 : 1);
    });
  }

  Future<void> _setGirlMode(bool value) async {
    if (girl == value) return;
    setState(() {
      girl = value;
    });
    await _controller.pause();
    await _controller.dispose();
    await _audioPlayer.stop();
    await _initVideoAndMusic();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _controller.value.isInitialized
              ? FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          )
              : Container(color: Colors.black),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
                  child: AnimatedBuilder(
                    animation: _tiltAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _tiltAnimation.value,
                        child: child,
                      );
                    },
                    child: Image.asset(
                      isDarkMode
                          ? 'ContenidoVisual/SNAKEoscuro.png'
                          : 'ContenidoVisual/SNAKE.jpg',
                      height: 400,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildButton('JUGAR', Icons.play_arrow, () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('🍓 Elige tu tipo de fruta'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.favorite, color: Colors.red),
                                    title: const Text('Frutas Rojas'),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _start(context, 'rojo');
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.water, color: Colors.blue),
                                    title: const Text('Frutas Azules'),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _start(context, 'azul');
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.star, color: Colors.yellow),
                                    title: const Text('Frutas Amarillas'),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _start(context, 'amarillo');
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.casino, color: Colors.purple),
                                    title: const Text('Modo Aleatorio'),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _start(context, 'random');
                                    },
                                  ),
                                ],
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                      _buildButton('CONFIGURACIÓN', Icons.settings, _mostrarConfiguracion),
                      const SizedBox(height: 16),
                      _buildButton('VER PUNTUACIONES', Icons.leaderboard, () => _mostrarPuntuaciones()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botón de ayuda (izquierda, azul, redondo)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: FloatingActionButton(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                tooltip: 'Ayuda',
                heroTag: 'ayuda',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('🆘 Ayuda'),
                      content: const Text(
                        '📖 *¡Bienvenido al juego de la serpiente!*\n\n'
                            '🎮 Controles:\n'
                            '   ➡️ Usa las teclas de flecha para mover la serpiente.\n'
                            '   🍎 Come frutas para crecer y ganar puntos.\n'
                            '   🌀 Puedes atravesar las paredes y aparecer por el lado contrario.\n'
                            '   💀 Si te chocas contigo mismo... ¡Game over!\n\n'
                            '🕹️ Modos de juego:\n'
                            '   🍒 Modo Fruta Roja: El clásico comecocos de toda la vida.\n'
                            '   🫐 Modo Fruta Azul: Los controles están invertidos 🌀.\n'
                            '   🍌 Modo Fruta Amarilla:Crece de forma aleatoria entre 1️⃣ y 3️⃣... ¡Cuidado!\n'
                            '   🎲 Modo Aleatorio: ¡Todo mezclado! Una experiencia impredecible 🤯.\n\n'
                            '🎵 Música:\n'
                            '   ¿Te molesta la música? Puedes silenciarla o bajar el volumen en Configuración ⚙️.\n\n'
                            '🍀 ¡Mucha suerte y a disfrutar! 🐍🔥',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(Icons.help),
              ),
            ),
            // Botón de volumen (derecha)
            Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
              child: FloatingActionButton(
                elevation: 0,
                shape: const CircleBorder(),
                onPressed: _toggleMute,
                backgroundColor: Colors.black.withOpacity(0.7),
                heroTag: 'volumen',
                child: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildButton(String text, IconData icon, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white.withOpacity(0.85),
          foregroundColor: isDark ? Colors.white : Colors.black,
        ),
        onPressed: onPressed,
      ),
    );
  }

  // Funciones para el snake game

  Future<List<Map<String, dynamic>>> _getScores() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('highScores') ?? [])
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  void _mostrarConfiguracion() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.volume_up, color: Colors.white),
                title: const Text('Configurar Volumen', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _ajustarVolumen();
                },
              ),
              ListTile(
                leading: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                title: Text(
                  _isMuted ? 'Activar Sonido' : 'Silenciar',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleMute();
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode, color: Colors.white),
                title: const Text('Cambiar Modo Oscuro', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onToggleTheme();
                },
              ),
              ListTile(
                leading: const Icon(Icons.brush, color: Colors.pink), // Icono pintauñas
                title: Text(
                  girl ? 'Desactivar Modo Girl' : 'Activar Modo Girl',
                  style: const TextStyle(color: Colors.pink),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _setGirlMode(!girl);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _mostrarPuntuaciones() async {
    final list = await _getScores();
    list.sort((a, b) => b['score'].compareTo(a['score']));

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color bgColor = isDarkMode ? Colors.grey[900]! : Colors.white;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Puntuaciones',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: list.length,
              itemBuilder: (context, index) {
                final jugador = list[index];
                return ListTile(
                  leading: Icon(Icons.person, color: textColor),
                  title: Text(
                    jugador['initials'],
                    style: TextStyle(color: textColor),
                  ),
                  trailing: Text(
                    '${jugador['score']} pts',
                    style: TextStyle(color: textColor),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar', style: TextStyle(color: textColor)),
            ),
          ],
        );
      },
    );
  }

  void _ajustarVolumen() {
    double volumenActual = _controller.value.volume;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajustar Volumen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.volume_up, size: 40),
              Slider(
                value: volumenActual,
                min: 0,
                max: 1,
                divisions: 10,
                label: (volumenActual * 100).toInt().toString(),
                onChanged: (nuevoVolumen) {
                  setState(() {
                    volumenActual = nuevoVolumen;
                    _controller.setVolume(volumenActual);
                    _audioPlayer.setVolume(_isMuted ? 0 : volumenActual);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

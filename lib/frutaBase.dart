import 'dart:math';
import 'dart:ui';
import 'GameScreen.dart';

/// Clase abstracta que da acceso a las variables del estado del juego para implementar nuevas frutas

abstract class Fruta {
  static final List<Fruta Function(Point<int>)> _tipoRegistrado = [];

  static void registrarTipo(Fruta Function(Point<int>) creador) {
    _tipoRegistrado.add(creador);
  }

  static Fruta generarFrutaRandom(Point<int> posicion) {
    final rand = Random();
    final tipo = _tipoRegistrado[rand.nextInt(_tipoRegistrado.length)];
    return tipo(posicion);
  }

  Point<int> posicion; /// Posición de la fruta
  Color color;  /// Color tipo Material

  Fruta(this.posicion, this.color);

  /// Metodo llamado por GameScreen cuando la serpiente come la fruta
  void aplicarEfecto(GameScreenState state) {
    state.score++;
    state.growQueue += 1;
  }
}
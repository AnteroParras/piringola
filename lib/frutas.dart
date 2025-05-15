import 'dart:math';
import 'package:flutter/material.dart';
import 'frutaBase.dart';
import 'GameScreen.dart';

/// Fruta normal, al ser comida, hace crecer la serpiente en 1 bloque
class FrutaRoja extends Fruta {
  FrutaRoja(Point<int> posicion) : super(posicion, Colors.redAccent);
}

/// Al ser comida, los controles de la serpiente son invertidos (izquierda es derecha, arriba es abajo y viceversa para ambos)
/// El efecto es revertido al comer otra fruta azul
class FrutaAzul extends Fruta {
  FrutaAzul(Point<int> posicion) : super(posicion, Colors.blueAccent);
  @override
  void aplicarEfecto(GameScreenState state) {
    state.score++;
    // Invierte controles
    state.invertDirections();
    state.growQueue += 1;
  }
}

/// Al ser comida, la serpiente crece 1-3 bloques adicionales
class FrutaAmarilla extends Fruta {
  FrutaAmarilla(Point<int> posicion) : super(posicion, Colors.yellowAccent);
  @override
  void aplicarEfecto(GameScreenState state) {
    state.score++;
    // Crecer aleatorio 1-3 bloques adicionales
    final extra = Random().nextInt(3) + 1;
    state.growQueue += extra;
  }
}

/// Función para cargar las frutas disponibles en el modo aleatorio
void cargarFrutas() {
  Fruta.registrarTipo((p) => FrutaRoja(p));
  Fruta.registrarTipo((p) => FrutaAzul(p));
  Fruta.registrarTipo((p) => FrutaAmarilla(p));
}
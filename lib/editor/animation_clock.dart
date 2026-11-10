import 'package:flutter/foundation.dart';

/// Relógio das animações do mapa. Só o canvas o ouve, para o painel não reconstruir a cada quadro.
class AnimationClock extends ChangeNotifier {
  double seconds = 0;

  void tick(double newSeconds) {
    seconds = newSeconds;
    notifyListeners();
  }
}

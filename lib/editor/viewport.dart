import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../geometry/iso.dart';

/// Câmera do mapa: deslocamento, zoom, tamanho da janela e tile sob o cursor.
/// Notifica só o canvas, sem reconstruir o painel.
class Viewport extends ChangeNotifier {
  static const double maxZoom = 3.0;

  /// Zoom mínimo padrão e piso absoluto. Mapas grandes (Valkaria, 84 blocos) precisam afastar
  /// bem mais: o mínimo acompanha o zoom que enquadra o mapa inteiro: dá para afastar até um quarto dele.
  static const double _baseMinZoom = 0.25, _floorZoom = 0.02;
  double _fitZoom = 1;

  double get minZoom => min(_baseMinZoom, _fitZoom * .25).clamp(_floorZoom, _baseMinZoom).toDouble();

  Offset pan = Offset.zero;
  double zoom = 0.8;
  Size size = Size.zero;
  Point<int>? hover;
  bool _isFitted = false;

  Offset toScene(Offset screen) => (screen - pan) / zoom;

  /// Enquadra o mapa inteiro na primeira vez (ou depois de [requestFit]).
  void fit(int tiles, Size available, {int? tilesY}) {
    size = available;
    if (available.isEmpty) return;
    final map = Iso.mapSize(tiles, tilesY);
    final fitAll =
        min(available.width / map.width, available.height / (map.height + 120));
    _fitZoom = fitAll; // atualizado sempre: o mapa pode crescer pelas setas
    if (_isFitted) return;
    _isFitted = true;
    // abre mais perto que o mapa inteiro, mas nunca além do que enquadra mapas pequenos
    zoom = (fitAll * 1.5).clamp(min(0.3, fitAll), 2.0).toDouble();
    // centraliza o mapa: na isométrica o centro do chão está em x = 0 (num mapa quadrado)
    final left = Iso.isTopDown
        ? (available.width - map.width * zoom) / 2
        : available.width / 2 - Iso.groundCenterX(tiles, tilesY) * zoom;
    pan = Offset(left, available.height / 2 - (map.height / 2) * zoom + 20);
  }

  void requestFit() => _isFitted = false;

  void moveTo(Offset newPan, double newZoom) {
    pan = newPan;
    zoom = newZoom;
    notifyListeners();
  }

  /// Zoom mantendo o ponto [focal] (em coordenadas de tela) parado.
  void zoomAround(Offset focal, double newZoom) => pinch(
      startFocal: focal,
      startPan: pan,
      startZoom: zoom,
      focal: focal,
      scale: newZoom / zoom);

  /// Gesto de pinça/arrasto: o ponto da cena sob [startFocal] acompanha [focal].
  void pinch({
    required Offset startFocal,
    required Offset startPan,
    required double startZoom,
    required Offset focal,
    required double scale,
  }) {
    final z = (startZoom * scale).clamp(minZoom, maxZoom).toDouble();
    final scenePoint = (startFocal - startPan) / startZoom;
    moveTo(focal - scenePoint * z, z);
  }

  void setHover(Point<int>? tile) {
    if (tile == hover) return;
    hover = tile;
    notifyListeners();
  }
}

import 'dart:math';
import 'dart:ui';

/// Imagem pronta de uma parte do mapa. Desenhar uma imagem custa uma operação só,
/// em vez de repetir milhares de traços a cada quadro.
class RasterImage {
  Image? _image;
  Rect _bounds = Rect.zero;
  static final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  bool get isEmpty => _image == null;

  /// Grava [record] (em coordenadas da cena) numa imagem com o fator [scale].
  void build(Rect bounds, double scale, void Function(Canvas) record) {
    dispose();
    final w = max(1, (bounds.width * scale).ceil()),
        h = max(1, (bounds.height * scale).ceil());
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(w / bounds.width, h / bounds.height)
      ..translate(-bounds.left, -bounds.top);
    record(canvas);
    final picture = recorder.endRecording();
    _image = picture.toImageSync(w, h);
    picture.dispose();
    _bounds = bounds;
  }

  void paint(Canvas cv) {
    final image = _image;
    if (image == null) return;
    cv.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        _bounds,
        _paint);
  }

  void dispose() {
    _image?.dispose();
    _image = null;
  }
}

/// Escolhe a resolução das imagens de cache conforme o zoom, com histerese para não
/// refazer tudo a cada passo de zoom, e dentro de um orçamento de memória.
class RasterScaler {
  static const _steps = [.5, .75, 1.0, 1.5, 2.0];

  /// Orçamento total de pixels de todas as imagens de cache (~100 MB).
  static const double _pixelBudget = 24e6;

  double _scale = 0;
  double get scale => _scale;

  double update(
      {required double zoom,
      required double devicePixelRatio,
      required double sceneArea}) {
    final budget = sqrt(_pixelBudget / max(1, sceneArea * 1.6));
    final cap = min(2.0, budget);
    final target = min(zoom * min(devicePixelRatio, 2), cap);
    var want = _steps.first;
    for (final s in _steps) {
      if (s <= target * 1.15 && s <= cap) want = s;
    }
    if (_scale == 0 ||
        want > _scale * 1.3 ||
        want < _scale * .45 ||
        _scale > cap) {
      _scale = want;
    }
    return _scale;
  }
}

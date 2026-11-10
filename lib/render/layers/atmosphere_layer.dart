import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import '../../domain/city.dart';
import '../../geometry/iso.dart';
import '../draw_helpers.dart';
import '../scene_view.dart';

/// Efeitos animados do ambiente: brilho na água e nuvens em volta da ilha flutuante.
class AtmosphereLayer {
  City? _city;
  int _version = -1;
  final List<(int, int, double)> _sparkles = [];

  /// Sorteia de uma vez só os pontos de brilho da água (no máximo 90), em vez de varrer o mapa a cada quadro.
  void _sync(City city) {
    if (identical(_city, city) && _version == city.water.version) return;
    _city = city;
    _version = city.water.version;
    _sparkles.clear();
    for (var x = 0; x < city.size && _sparkles.length < 90; x++) {
      for (var y = 0; y < city.size && _sparkles.length < 90; y++) {
        if (!city.water.at(x, y)) continue;
        final h = tileHash(x, y);
        if (h % 3 == 0) _sparkles.add((x, y, (h % 628) / 100));
      }
    }
  }

  void paint(Canvas cv, SceneView scene) {
    final city = scene.city, t = scene.time;
    _sync(city);
    if (_sparkles.isNotEmpty && city.islandRadius == 0) {
      final view = scene.visibleScene.inflate(40);
      final lines = <double>[];
      for (final (x, y, ph) in _sparkles) {
        if (sin(t * 1.3 + ph) < .35) continue;
        final o = Iso.pt(x + .5 + sin(t * .4 + ph) * .2, y + .5);
        if (!view.contains(o)) continue;
        lines
          ..add(o.dx - 5)
          ..add(o.dy)
          ..add(o.dx + 5)
          ..add(o.dy);
      }
      if (lines.isNotEmpty) {
        cv.drawRawPoints(
          PointMode.lines,
          Float32List.fromList(lines),
          Paint()
            ..color = const Color.fromRGBO(255, 255, 255, .45)
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    if (scene.settlement.floating) _clouds(cv, max(city.tilesX, city.tilesY).toDouble(), t);
  }

  /// Nuvens passando por baixo e em volta da ilha.
  void _clouds(Canvas cv, double nd, double t) {
    final paint = Paint()..color = const Color.fromRGBO(255, 255, 255, .55);
    for (var i = 0; i < 9; i++) {
      final ph = i * 1.7;
      final drift = ((t * (6 + i % 3 * 2) + i * 70) % 520) - 140;
      final base = Iso.pt(nd * .5, nd * .5, -70 - (i % 4) * 22);
      final c = base.translate(drift - 200 + sin(ph) * 40, (i % 3 - 1) * 26);
      for (final (dx, dy, r) in const [
        (0.0, 0.0, 26.0),
        (26.0, -6.0, 32.0),
        (58.0, 2.0, 24.0)
      ]) {
        cv.drawOval(
            Rect.fromCenter(
                center: c.translate(dx, dy), width: r * 2.4, height: r * 1.1),
            paint);
      }
    }
  }
}

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/painting.dart' show RadialGradient;
import '../../domain/city.dart';
import '../../geometry/iso.dart';
import '../../systems/art_profile.dart';
import '../draw_helpers.dart';
import '../scene_view.dart';

/// Efeito animado da área especial (tempestade de Tormenta, campo do Loop, véu, névoa...).
///
/// Para ser leve, os tiles da área são agrupados em poucos `Path`s (um desenho por grupo,
/// com a transparência animada) e as partículas saem em poucas chamadas em lote.
class ZoneEffectsLayer {
  City? _city;
  int _version = -1;

  /// Vista usada ao montar os `Path`s: eles já estão projetados, então trocar de 3D para 2D
  /// (ou o contrário) precisa refazer tudo.
  ViewMode _mode = Iso.mode;
  int _rot = 0;
  final List<Path> _byHash = List.generate(3, (_) => Path());
  final List<Path> _byDiagonal = List.generate(14, (_) => Path());
  Path _all = Path();
  final List<(int, int, int)> _tiles = [];
  Offset _center = Offset.zero;
  double _radius = 0;

  void _sync(City city) {
    if (identical(_city, city) &&
        _version == city.zone.version &&
        _mode == Iso.mode &&
        _rot == Iso.rot) {
      return;
    }
    _city = city;
    _version = city.zone.version;
    _mode = Iso.mode;
    _rot = Iso.rot;
    for (final p in [..._byHash, ..._byDiagonal]) {
      p.reset();
    }
    _all = Path();
    _tiles.clear();
    var sx = 0.0, sy = 0.0;
    for (var y = 0; y < city.size; y++) {
      for (var x = 0; x < city.size; x++) {
        if (!city.zone.at(x, y)) continue;
        final h = tileHash(x, y);
        _tiles.add((x, y, h));
        final tile = Iso.diamond(x.toDouble(), y.toDouble(), 1, 1);
        _byHash[h % 3].addPath(tile, Offset.zero);
        _byDiagonal[(x + y) % 14].addPath(tile, Offset.zero);
        _all.addPath(tile, Offset.zero);
        sx += x + .5;
        sy += y + .5;
      }
    }
    if (_tiles.isEmpty) return;
    _center = Iso.pt(sx / _tiles.length, sy / _tiles.length);
    _radius = max(60, sqrt(_tiles.length.toDouble()) * 34);
  }

  void paintGround(Canvas cv, SceneView scene) {
    final effect = scene.system.art.zoneEffect;
    if (effect == ZoneEffect.none || effect == ZoneEffect.wildMotes) return;
    _sync(scene.city);
    if (_tiles.isEmpty) return;
    final t = scene.time;
    switch (effect) {
      case ZoneEffect.stormRift:
        for (var g = 0; g < 3; g++) {
          final a = .10 + .16 * (.5 + .5 * sin(t * 1.3 + g * 2.1));
          cv.drawPath(
              _byHash[g], Paint()..color = Color.fromRGBO(200, 20, 40, a));
        }
      case ZoneEffect.loopField:
        for (var s = 0; s < 14; s++) {
          final band = (s * .5 - t * 1.6) % 7;
          if (band < 1.2) {
            cv.drawPath(
                _byDiagonal[s],
                Paint()
                  ..color =
                      Color.fromRGBO(120, 220, 255, .28 * (1 - band / 1.2)));
          }
        }
      case ZoneEffect.thinVeil:
        for (var g = 0; g < 3; g++) {
          cv.drawPath(
              _byHash[g],
              Paint()
                ..color = Color.fromRGBO(150, 60, 190,
                    .08 + .14 * (.5 + .5 * sin(t * 1.1 + g * 2.0))));
        }
      case ZoneEffect.cultFog:
        for (var g = 0; g < 3; g++) {
          cv.drawPath(
              _byHash[g],
              Paint()
                ..color = Color.fromRGBO(
                    30, 70, 50, .10 + .12 * (.5 + .5 * sin(t * .7 + g * 1.7))));
        }
      case ZoneEffect.combatSparks:
        for (var g = 0; g < 3; g++) {
          if (sin(t * 6 + g * 2.3) > .93) {
            cv.drawPath(_byHash[g],
                Paint()..color = const Color.fromRGBO(255, 200, 60, .30));
          }
        }
      case ZoneEffect.wildMotes || ZoneEffect.none:
        break;
    }
  }

  void paintAir(Canvas cv, SceneView scene) {
    final effect = scene.system.art.zoneEffect;
    if (effect == ZoneEffect.none) return;
    _sync(scene.city);
    if (_tiles.isEmpty) return;
    final view = scene.visibleScene.inflate(100);
    if (!view
        .overlaps(Rect.fromCircle(center: _center, radius: _radius + 220))) {
      return;
    }
    final t = scene.time;
    switch (effect) {
      case ZoneEffect.stormRift:
        _storm(cv, t);
      case ZoneEffect.loopField:
        _points(
            cv,
            t,
            PointMode.points,
            6,
            3.2,
            (life) => Color.fromRGBO(170, 235, 255, sin(life * pi) * .9),
            (o, ph, life) => o.translate(sin(ph * 3) * 8, -8 - life * 46),
            speed: .12);
      case ZoneEffect.thinVeil:
        _points(
            cv,
            t,
            PointMode.points,
            5,
            4.4,
            (life) => Color.fromRGBO(220, 150, 255, sin(life * pi) * .9),
            (o, ph, life) =>
                o.translate(cos(ph * 4 + life * 4) * 8, -6 - life * 54),
            speed: .2);
      case ZoneEffect.cultFog:
        _fog(cv, t);
      case ZoneEffect.combatSparks:
        _points(
            cv,
            t,
            PointMode.points,
            7,
            2.6,
            (life) => life > .35
                ? const Color(0x00000000)
                : Color.fromRGBO(255, 210, 90, 1 - life / .35),
            (o, ph, life) => o.translate(sin(ph * 7) * 10, -10 - life * 30),
            speed: .9);
      case ZoneEffect.wildMotes:
        _motes(cv, t);
      case ZoneEffect.none:
        break;
    }
  }

  /// Partículas em lote: uma chamada de desenho por cor/transparência média.
  void _points(
      Canvas cv,
      double t,
      PointMode mode,
      int every,
      double size,
      Color Function(double) color,
      Offset Function(Offset, double, double) place,
      {required double speed}) {
    final pts = <double>[];
    var alpha = 0.0;
    var count = 0;
    Color last = const Color(0x00000000);
    for (final (x, y, h) in _tiles) {
      if (h % every != 0) continue;
      final ph = (h % 628) / 100;
      final life = (t * speed + ph) % 1;
      final c = color(life);
      if (c.a == 0) continue;
      final p = place(Iso.pt(x + .5, y + .5), ph, life);
      pts
        ..add(p.dx)
        ..add(p.dy);
      alpha += c.a;
      last = c;
      if (++count >= 90) break;
    }
    if (count == 0) return;
    cv.drawRawPoints(
      mode,
      Float32List.fromList(pts),
      Paint()
        ..color = last.withValues(alpha: min(1, alpha / count + .15))
        ..strokeWidth = size
        ..strokeCap = StrokeCap.round,
    );
  }

  void _fog(Canvas cv, double t) {
    final paint = Paint()..color = const Color.fromRGBO(190, 215, 200, .13);
    var n = 0;
    for (final (x, y, h) in _tiles) {
      if (h % 4 != 0) continue;
      final ph = (h % 628) / 100;
      final drift = ((t * .08 + ph) % 1) * 70 - 35;
      cv.drawOval(
          Rect.fromCenter(
              center: Iso.pt(x + .5, y + .5).translate(drift, -6 + sin(ph) * 6),
              width: 54,
              height: 18),
          paint);
      if (++n >= 50) break;
    }
  }

  void _motes(Canvas cv, double t) {
    final glow = Paint()..color = const Color.fromRGBO(210, 255, 130, .12);
    final core = <double>[];
    var n = 0;
    for (final (x, y, h) in _tiles) {
      if (h % 4 != 0) continue;
      final ph = (h % 628) / 100;
      final p = Iso.pt(x + .5, y + .5)
          .translate(sin(t * .6 + ph) * 12, -14 + cos(t * .8 + ph * 2) * 8);
      cv.drawCircle(p, 5, glow);
      core
        ..add(p.dx)
        ..add(p.dy);
      if (++n >= 60) break;
    }
    cv.drawRawPoints(
        PointMode.points,
        Float32List.fromList(core),
        Paint()
          ..color = const Color.fromRGBO(240, 255, 170, .9)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
  }

  // ------------------------------------------------------------------ Tormenta
  /// Tempestade vermelha: nuvens escuras girando sobre a área, chuva rubra, brasas e relâmpagos.
  void _storm(Canvas cv, double t) {
    final glowPulse = .5 + .5 * sin(t * 1.7);
    // nuvens em espiral, com bordas macias (degradê radial)
    for (var i = 0; i < 9; i++) {
      final a = t * .16 + i * 2 * pi / 9;
      final r = _radius * (.3 + .22 * ((i % 3) / 2));
      final c = _center.translate(cos(a) * r * 1.1, -250 + sin(a) * r * .45);
      final size = Size(170 + (i % 3) * 40, 78);
      final rect =
          Rect.fromCenter(center: c, width: size.width, height: size.height);
      cv.drawOval(
        rect,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0x8C2A0610), Color(0x00300812)])
              .createShader(rect),
      );
    }
    cv.drawCircle(_center.translate(0, -185), 26 + glowPulse * 10,
        Paint()..color = Color.fromRGBO(255, 70, 60, .10 + .12 * glowPulse));
    // chuva vermelha
    final drops = <double>[];
    final count = min(110, _tiles.length * 2);
    for (var i = 0; i < count; i++) {
      final (x, y, h) = _tiles[(i * 7919) % _tiles.length];
      final ph = ((h + i * 131) % 1000) / 1000;
      final u = (t * 1.25 + ph) % 1;
      final ground = Iso.pt(x + .15 + (i % 7) * .11, y + .15 + (i % 5) * .15);
      final head = ground.translate(0, -200 * (1 - u));
      drops
        ..add(head.dx)
        ..add(head.dy)
        ..add(head.dx - 3)
        ..add(head.dy - 15);
    }
    cv.drawRawPoints(
      PointMode.lines,
      Float32List.fromList(drops),
      Paint()
        ..color = const Color.fromRGBO(235, 60, 60, .55)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    // brasas
    final embers = <double>[];
    for (var i = 0; i < min(40, _tiles.length); i++) {
      final (x, y, h) = _tiles[(i * 104729) % _tiles.length];
      final ph = (h % 628) / 100;
      final life = (t * .3 + ph) % 1;
      final p = Iso.pt(x + .5, y + .5)
          .translate(sin(ph * 5 + life * 5) * 6, -life * 70);
      embers
        ..add(p.dx)
        ..add(p.dy);
    }
    cv.drawRawPoints(
        PointMode.points,
        Float32List.fromList(embers),
        Paint()
          ..color = const Color.fromRGBO(255, 130, 90, .85)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round);
    _lightning(cv, t);
  }

  /// Relâmpago vermelho com ramificações, que ilumina a área por um instante.
  void _lightning(Canvas cv, double t) {
    final slot = (t / 2.2).floor();
    final into = t - slot * 2.2;
    if (into > .28) return;
    final a = 1 - into / .28;
    final (x, y, _) = _tiles[(slot * 2654435761) % _tiles.length];
    final r = Random(slot);
    final end = Iso.pt(x + .5, y + .5);
    var p = end.translate((r.nextDouble() - .5) * 30, -240);
    final main = Path()..moveTo(p.dx, p.dy);
    final branches = <Path>[];
    for (var i = 0; i < 8; i++) {
      p = Offset(
          p.dx + (r.nextDouble() - .5) * 28, p.dy + (end.dy - p.dy) / (8 - i));
      main.lineTo(p.dx, p.dy);
      if (i % 3 == 1) {
        final b = Path()..moveTo(p.dx, p.dy);
        var q = p;
        for (var k = 0; k < 3; k++) {
          q = Offset(q.dx + (r.nextDouble() - .2) * 18,
              q.dy + 14 + r.nextDouble() * 10);
          b.lineTo(q.dx, q.dy);
        }
        branches.add(b);
      }
    }
    cv.drawPath(_all, Paint()..color = Color.fromRGBO(255, 90, 80, .22 * a));
    final glow = Paint()
      ..color = Color.fromRGBO(255, 50, 50, .4 * a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeJoin = StrokeJoin.round;
    final core = Paint()
      ..color = Color.fromRGBO(255, 235, 225, a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    cv.drawPath(main, glow);
    cv.drawPath(main, core);
    for (final b in branches) {
      cv.drawPath(b, glow..strokeWidth = 4);
      cv.drawPath(b, core..strokeWidth = 1.2);
    }
    cv.drawOval(Rect.fromCenter(center: end, width: 70, height: 34),
        Paint()..color = Color.fromRGBO(255, 80, 80, .35 * a));
  }
}

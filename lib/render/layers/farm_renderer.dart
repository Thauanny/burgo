import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../geometry/iso.dart';
import '../../systems/art_profile.dart';
import '../draw_helpers.dart';
import 'prop_renderer.dart';

/// Desenha plantações e pastos: solo, fileiras, cultivo, cerca e animais.
class FarmRenderer {
  const FarmRenderer({this.props = const PropRenderer()});
  final PropRenderer props;

  /// Só o pasto tem partes animadas (os animais); o resto da fazenda é estático.
  static bool hasAnimals(Farm f) => f.crop == CropType.pasture;

  void paint(Canvas cv, Farm f) {
    final x = f.x.toDouble(),
        y = f.y.toDouble(),
        w = f.width.toDouble(),
        d = f.depth.toDouble();
    final look = _looks[f.crop]!;
    _fence(cv, x, y, w, d, back: true);
    fillPoly(cv, Iso.diamond(x + .06, y + .06, w - .12, d - .12), look.soil,
        line: shade(look.soil, -.18), lw: 1);
    _soilTexture(cv, f, look);
    switch (f.crop) {
      case CropType.wheat:
        _rows(cv, f, spacing: .2, step: .13, draw: _wheat);
      case CropType.corn:
        _rows(cv, f, spacing: .34, step: .3, draw: _corn);
      case CropType.vineyard:
        _vineyard(cv, f);
      case CropType.vegetables:
        _rows(cv, f, spacing: .3, step: .28, draw: _vegetable);
      case CropType.orchard:
        _orchard(cv, f);
      case CropType.pasture:
        _pasture(cv, f);
      case CropType.rice:
        _rows(cv, f, spacing: .26, step: .2, draw: _rice);
      case CropType.cotton:
        _rows(cv, f, spacing: .32, step: .26, draw: _cotton);
    }
    _fence(cv, x, y, w, d, back: false);
  }

  // ------------------------------------------------------------- solo
  static const _looks = {
    CropType.wheat: _Look(Color(0xFFD2B26C)),
    CropType.corn: _Look(Color(0xFFA6825A)),
    CropType.vineyard: _Look(Color(0xFF9A8860)),
    CropType.vegetables: _Look(Color(0xFF86603F)),
    CropType.orchard: _Look(Color(0xFFA5D788)),
    CropType.pasture: _Look(Color(0xFF9AD57F)),
    CropType.rice: _Look(Color(0xFF9CCFD2)),
    CropType.cotton: _Look(Color(0xFFCBB07C)),
  };

  void _soilTexture(Canvas cv, Farm f, _Look look) {
    final line = Paint()
      ..color = shade(look.soil, -.07)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < f.width * 4; i++) {
      final u = i / 4;
      cv.drawLine(
          Iso.pt(f.x + u, f.y + .1), Iso.pt(f.x + u, f.y + f.depth - .1), line);
    }
  }

  // ------------------------------------------------------------- fileiras
  void _rows(Canvas cv, Farm f,
      {required double spacing,
      required double step,
      required void Function(Canvas, Offset, int) draw}) {
    final x0 = f.x + .22,
        x1 = f.x + f.width - .22,
        y0 = f.y + .22,
        y1 = f.y + f.depth - .22;
    var yy = y0;
    var row = 0;
    while (yy <= y1) {
      var xx = x0;
      var col = 0;
      while (xx <= x1) {
        draw(cv, Iso.pt(xx, yy), tileHash(row * 7 + col, row + col * 3));
        xx += step;
        col++;
      }
      yy += spacing;
      row++;
    }
  }

  static void _wheat(Canvas cv, Offset o, int h) {
    final c = h % 3 == 0 ? const Color(0xFFE4C55A) : const Color(0xFFD6AE45);
    final p = Paint()
      ..color = ink(c).withValues(alpha: 1)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    cv.drawLine(
        o,
        o.translate(0, -6 - (h % 3)),
        Paint()
          ..color = c
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round);
    cv.drawCircle(
        o.translate(0, -7 - (h % 3)), 1.5, p..color = const Color(0xFFF1D97A));
  }

  static void _corn(Canvas cv, Offset o, int h) {
    final leaf = Paint()
      ..color = const Color(0xFF5E9F4E)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final top = o.translate(0, -12 - (h % 3));
    cv.drawLine(o, top, leaf);
    cv.drawLine(
        o.translate(0, -5), o.translate(-5, -9), leaf..strokeWidth = 1.4);
    cv.drawLine(o.translate(0, -6), o.translate(5, -10), leaf);
    cv.drawLine(
        top,
        top.translate(0, -3),
        Paint()
          ..color = const Color(0xFFE8D27A)
          ..strokeWidth = 1.4);
    cv.drawOval(
        Rect.fromCenter(center: o.translate(2, -7), width: 2.6, height: 4.2),
        Paint()..color = const Color(0xFFF2D45E));
  }

  static void _vegetable(Canvas cv, Offset o, int h) {
    cv.drawOval(Rect.fromCenter(center: o.translate(0, 1), width: 9, height: 4),
        Paint()..color = const Color(0xFF6E4C32));
    switch (h % 3) {
      case 0:
        cv.drawCircle(
            o.translate(0, -3), 3.8, Paint()..color = const Color(0xFF7FC05E));
        cv.drawCircle(
            o.translate(-1, -4), 2.2, Paint()..color = const Color(0xFFA4D87E));
      case 1:
        cv.drawLine(
            o,
            o.translate(0, -4),
            Paint()
              ..color = const Color(0xFF4E9A48)
              ..strokeWidth = 1.6);
        cv.drawCircle(
            o.translate(0, -5), 2.4, Paint()..color = const Color(0xFFE9873A));
      default:
        cv.drawCircle(
            o.translate(0, -3), 3, Paint()..color = const Color(0xFFD9473F));
        cv.drawCircle(o.translate(0, -5.5), 1.4,
            Paint()..color = const Color(0xFF4E9A48));
    }
  }

  static void _rice(Canvas cv, Offset o, int h) {
    final p = Paint()
      ..color = const Color(0xFF6FB24F)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    cv.drawLine(o, o.translate(-1.5, -6), p);
    cv.drawLine(o, o.translate(1.5, -6), p);
    cv.drawLine(o, o.translate(0, -7), p);
  }

  static void _cotton(Canvas cv, Offset o, int h) {
    cv.drawCircle(
        o.translate(0, -3), 3.5, Paint()..color = const Color(0xFF6FA55A));
    cv.drawCircle(
        o.translate(-1.5, -5), 1.9, Paint()..color = const Color(0xFFFFFFFF));
    cv.drawCircle(
        o.translate(1.8, -4), 1.7, Paint()..color = const Color(0xFFFFFFFF));
  }

  // ------------------------------------------------------------- vinha
  void _vineyard(Canvas cv, Farm f) {
    final post = Paint()
      ..color = const Color(0xFF6B4A33)
      ..strokeWidth = 1.6;
    final wire = Paint()
      ..color = const Color(0xFF5E9A44)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    for (var u = f.y + .5; u < f.y + f.depth; u += .75) {
      final a = Iso.pt(f.x + .3, u), b = Iso.pt(f.x + f.width - .3, u);
      for (var t = 0.0; t <= 1.001; t += .25) {
        final p = Offset.lerp(a, b, t)!;
        cv.drawLine(p, p.translate(0, -9), post);
      }
      cv.drawLine(a.translate(0, -7), b.translate(0, -7), wire);
      for (var t = .08; t < 1; t += .13) {
        final p = Offset.lerp(a, b, t)!.translate(0, -4);
        cv.drawCircle(
            p,
            1.7,
            Paint()
              ..color = (u * 10).floor().isEven
                  ? const Color(0xFF7A3E8E)
                  : const Color(0xFF9BC64F));
      }
    }
  }

  // ------------------------------------------------------------- pomar
  void _orchard(Canvas cv, Farm f) {
    for (var yy = 0; yy < f.depth; yy++) {
      for (var xx = 0; xx < f.width; xx++) {
        final o = Iso.pt(f.x + xx + .5, f.y + yy + .5);
        final h = tileHash(f.x + xx, f.y + yy);
        cv.drawOval(
            Rect.fromCenter(center: o.translate(3, 2), width: 22, height: 10),
            Paint()..color = const Color(0x22000000));
        cv.drawLine(
            o,
            o.translate(0, -9),
            Paint()
              ..color = const Color(0xFF7A5638)
              ..strokeWidth = 2.4);
        final crown = o.translate(0, -17);
        cv.drawCircle(crown, 9, Paint()..color = const Color(0xFF63B05A));
        cv.drawCircle(crown.translate(-2, -2), 6,
            Paint()..color = const Color(0xFF7CC66E));
        final fruit =
            h % 2 == 0 ? const Color(0xFFE0503F) : const Color(0xFFF2B63A);
        for (final (dx, dy) in const [(-4.0, 1.0), (3.0, -3.0), (4.0, 3.0)]) {
          cv.drawCircle(crown.translate(dx, dy), 1.5, Paint()..color = fruit);
        }
      }
    }
  }

  // ------------------------------------------------------------- pasto
  void _pasture(Canvas cv, Farm f) {
    final tuft = Paint()
      ..color = const Color(0xFF6FB75A)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < f.width * f.depth * 2; i++) {
      final h = tileHash(f.x * 31 + i, f.y * 17 + i * 3);
      final o = Iso.pt(f.x + .2 + (h % 100) / 100 * (f.width - .4),
          f.y + .2 + ((h >> 7) % 100) / 100 * (f.depth - .4));
      cv.drawLine(o, o.translate(-1.5, -4), tuft);
      cv.drawLine(o, o.translate(1.5, -4), tuft);
    }
  }

  /// Animais do pasto, desenhados a cada quadro.
  /// Os animais ficam a pelo menos meio tile da cerca: o passeio deles não a atravessa.
  void paintAnimals(Canvas cv, Farm f,
      {required double time,
      required Color zoneColor,
      required AnomalyStyle anomaly,
      double scale = 1}) {
    final count = max(1, (f.width * f.depth) ~/ 5);
    final innerW = max(1, f.width - 2), innerD = max(1, f.depth - 2);
    final ox = f.width > 2 ? 1 : 0, oy = f.depth > 2 ? 1 : 0;
    for (var i = 0; i < count; i++) {
      final h = tileHash(f.x * 13 + i * 5, f.y * 7 + i);
      final tx = f.x + ox + (h % innerW), ty = f.y + oy + ((h >> 5) % innerD);
      final type = const [
        PropType.cow,
        PropType.sheep,
        PropType.sheep,
        PropType.horse
      ][h % 4];
      props.paint(cv, Prop(id: f.id * 131 + i, x: tx, y: ty, type: type),
          zoneColor: zoneColor, time: time, anomaly: anomaly, scale: scale);
    }
  }

  // ------------------------------------------------------------- cerca
  void _fence(Canvas cv, double x, double y, double w, double d,
      {required bool back}) {
    final rail = Paint()
      ..color = const Color(0xFF8A6A4A)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final post = Paint()
      ..color = const Color(0xFF6B4E34)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    void run(Offset a, Offset b, int n) {
      for (var i = 0; i <= n; i++) {
        final p = Offset.lerp(a, b, i / n)!;
        cv.drawLine(p, p.translate(0, -7), post);
      }
      cv.drawLine(a.translate(0, -3), b.translate(0, -3), rail);
      cv.drawLine(a.translate(0, -6), b.translate(0, -6), rail);
    }

    if (back) {
      run(Iso.pt(x, y), Iso.pt(x + w, y), (w * 2).round());
      run(Iso.pt(x, y), Iso.pt(x, y + d), (d * 2).round());
    } else {
      run(Iso.pt(x, y + d), Iso.pt(x + w, y + d), (w * 2).round());
      run(Iso.pt(x + w, y), Iso.pt(x + w, y + d), (d * 2).round());
    }
  }
}

class _Look {
  const _Look(this.soil);
  final Color soil;
}

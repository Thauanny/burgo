import 'dart:math';
import 'dart:ui';

import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../geometry/iso.dart';
import 'entities_layer.dart' show EntitiesLayer;
import 'market_props.dart' show propHeights;

/// Setas de girar sobre o objeto selecionado (ou o último colocado): a seta da esquerda vira a
/// frente para a face da esquerda da construção, a da direita para a face da direita. Girar uma
/// construção 90° troca a largura pela profundidade; um objeto é espelhado.
abstract final class RotateHandles {
  /// Objetos sem frente (plantas, relevo, cercas, luzes) não ganham setas.
  static const _noFront = {
    PropType.tree,
    PropType.pine,
    PropType.sakura,
    PropType.autumnTree,
    PropType.frostTree,
    PropType.bush,
    PropType.cactus,
    PropType.giantFlower,
    PropType.fairyLight,
    PropType.fairyRing,
    PropType.mountain,
    PropType.mesa,
    PropType.skyIsle,
    PropType.fence,
    PropType.hedge,
    PropType.fenceGate,
    PropType.hedgeGate,
    PropType.dungeonEntrance,
    PropType.eclipse,
    PropType.campfire,
    PropType.anomaly,
  };

  static bool canRotate(MapItem item) => switch (item) {
        Building _ => true,
        Farm _ => false,
        final Prop p => !EntitiesLayer.walks(p.type) && !_noFront.contains(p.type),
      };

  /// Giro atual do item (0 a 3).
  static int turnOf(MapItem item) => switch (item) {
        final Building b => b.turn,
        final Prop p => p.turn,
        _ => 0,
      };

  /// Para onde a frente está virada, em palavras.
  static String facingLabel(int turn) => const ['sul (frente à esquerda)', 'oeste (frente para trás)',
      'norte (frente para trás)', 'leste (frente à direita)'][turn % 4];

  /// Raio e distância ao centro das setas, em pixels da tela (o tamanho não muda com o zoom).
  static const double radiusPx = 15, gapPx = 20;

  /// Ponto da cena logo acima do item, onde ficam as setas.
  static Offset anchor(MapItem item) => switch (item) {
        final Building b => Iso.pt(b.x + b.width / 2, b.y + b.depth / 2, Iso.height(b) + Iso.roofRise(b) + 22),
        final Prop p => Iso.pt(p.x + .5, p.y + .5, (propHeights[p.type] ?? 34) + 22),
        _ => Iso.pt(item.x + .5, item.y + .5, 30),
      };

  /// Centros (na cena) das duas setas: esquerda e direita.
  static (Offset, Offset) centers(MapItem item, double zoom) {
    final a = anchor(item);
    final g = gapPx / zoom;
    return (a.translate(-g, 0), a.translate(g, 0));
  }

  /// Seta sob [scene]: -1 = girar no sentido anti-horário (esquerda), +1 = horário (direita).
  static int? hit(MapItem item, Offset scene, double zoom) {
    final (l, r) = centers(item, zoom);
    final reach = radiusPx * 1.1 / zoom;
    if ((scene - l).distance <= reach) return -1;
    if ((scene - r).distance <= reach) return 1;
    return null;
  }

  static const _mustard = Color(0xFFE0A93B), _cream = Color(0xFFFBF6EA), _ink = Color(0xFF2B2A33);

  /// [hovered]: a seta sob o mouse (-1 ou +1), desenhada maior e em mostarda.
  static void paint(Canvas cv, MapItem item, double zoom, {int? hovered}) {
    final (l, r) = centers(item, zoom);
    _button(cv, l, zoom, clockwise: false, hot: hovered == -1);
    _button(cv, r, zoom, clockwise: true, hot: hovered == 1);
  }

  /// Botão redondo com uma seta circular (↺ ou ↻), como o "girar" dos editores de imagem.
  static void _button(Canvas cv, Offset c, double zoom, {required bool clockwise, bool hot = false}) {
    final u = 1 / zoom, rad = radiusPx * u * (hot ? 1.15 : 1);
    cv.drawCircle(c.translate(0, 2 * u), rad, Paint()..color = const Color(0x44000000));
    cv.drawCircle(c, rad, Paint()..color = hot ? _mustard : _cream);
    cv.drawCircle(
        c,
        rad,
        Paint()
          ..color = _mustard
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * u);
    cv.drawCircle(
        c,
        rad + 1.5 * u,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * u);
    // arco de 270° com a ponta da seta no fim
    final r = rad * .52;
    final pen = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * u
      ..strokeCap = StrokeCap.round;
    const start = -pi / 2 + .35, sweep = pi * 1.45;
    final s0 = clockwise ? start : pi - start;
    final sw = clockwise ? sweep : -sweep;
    cv.drawArc(Rect.fromCircle(center: c, radius: r), s0, sw, false, pen);
    final end = s0 + sw;
    final tip = c + Offset(cos(end), sin(end)) * r;
    // direção da tangente no fim do arco
    final dir = clockwise ? Offset(-sin(end), cos(end)) : Offset(sin(end), -cos(end));
    final side = Offset(-dir.dy, dir.dx);
    final head = Path()
      ..moveTo(tip.dx + dir.dx * 3.6 * u, tip.dy + dir.dy * 3.6 * u)
      ..lineTo(tip.dx - dir.dx * 2.4 * u + side.dx * 3.4 * u, tip.dy - dir.dy * 2.4 * u + side.dy * 3.4 * u)
      ..lineTo(tip.dx - dir.dx * 2.4 * u - side.dx * 3.4 * u, tip.dy - dir.dy * 2.4 * u - side.dy * 3.4 * u)
      ..close();
    cv.drawPath(head, Paint()..color = _ink);
  }
}

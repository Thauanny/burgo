import 'dart:ui';
import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../geometry/iso.dart';
import '../draw_helpers.dart';
import 'building_painters.dart';

/// Desenha uma construção: sombra, lote e o desenho da sua família ([BuildingKind]).
class BuildingRenderer {
  const BuildingRenderer();

  static const _noLot = {
    BuildingKind.castle,
    BuildingKind.lab,
    BuildingKind.skyscraper
  };

  void paint(Canvas cv, Building b, double time) {
    final x = b.x.toDouble(),
        y = b.y.toDouble(),
        w = b.width.toDouble(),
        d = b.depth.toDouble();
    fillPoly(
        cv,
        Iso.poly([
          Iso.pt(x, y),
          Iso.pt(x + w + .4, y),
          Iso.pt(x + w + .4, y + d + .4),
          Iso.pt(x, y + d + .4)
        ]),
        const Color.fromRGBO(0, 0, 0, 0.14));
    if (!_noLot.contains(b.kind)) {
      fillPoly(cv, Iso.diamond(x - .12, y - .12, w + .24, d + .24),
          const Color(0xFFEADFC4),
          line: const Color(0xFFCFC2A4), lw: 1);
    }
    buildingPainters[b.kind]!(cv, b, time);
  }
}

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/geometry/iso.dart';
import 'package:burgo/render/city_painter.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const size = ui.Size(600, 500);

  Future<(Uint8List, EditorState)> render(double zoom, {required bool withPerson, bool withHouse = true}) async {
    final e = EditorState(generator: const ProceduralCityGenerator(), systems: const BuiltInSystemRepository())
      ..configure(systemId: 'generico', mode: SettlementMode.blank)
      ..generate(seed: 4242);
    for (var x = 4; x < 30; x++) {
      for (var y = 4; y < 30; y++) {
        e.city.water.set(x, y, false);
        for (final p in e.city.props.where((p) => p.x == x && p.y == y).toList()) {
          e.city.remove(p);
        }
      }
    }
    if (withHouse) e.city.add(const Building(id: 900, x: 10, y: 10, width: 2, depth: 2, floors: 2, kind: BuildingKind.cottage));
    // pessoa parada (raio 0) logo atrás da casa
    if (withPerson) e.city.add(const Prop(id: 901, x: 10, y: 9, type: PropType.guard, roam: 0));
    e.setShowScaleBar(false);
    e.activateProjection();
    e.viewport.fit(e.city.size, size, tilesY: e.city.tilesY);
    e.viewport.zoom = zoom;
    e.viewport.pan = size.center(ui.Offset.zero) - Iso.pt(11, 10.5, 20) * zoom;
    final painter = CityPainter(e, repaint: e);
    late ui.Image img;
    for (var i = 0; i < 3; i++) {
      final rec = ui.PictureRecorder();
      painter.paint(ui.Canvas(rec), size);
      img = await rec.endRecording().toImage(size.width.toInt(), size.height.toInt());
    }
    final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    return (bytes!.buffer.asUint8List(), e);
  }

  for (final zoom in [.3, .45, 1.0]) {
    test('quem anda atrás da casa fica atrás dela, não por cima do telhado (zoom $zoom)', () async {
      final (ground, _) = await render(zoom, withPerson: false, withHouse: false);
      final (plain, _) = await render(zoom, withPerson: false);
      final (person, _) = await render(zoom, withPerson: true);
      final w = size.width.toInt(), h = size.height.toInt();
      int diff(Uint8List a, Uint8List b, int i) =>
          (a[i] - b[i]).abs() + (a[i + 1] - b[i + 1]).abs() + (a[i + 2] - b[i + 2]).abs();
      // onde a casa pinta de verdade (casa x só o chão), sem a borda (antisserrilhado e sombra)
      bool house(int x, int y) =>
          x >= 0 && y >= 0 && x < w && y < h && diff(plain, ground, (y * w + x) * 4) > 40;
      var inside = 0, changedInside = 0, changedOutside = 0;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final i = (y * w + x) * 4;
          final changed = diff(plain, person, i) > 24;
          final core = house(x, y) && house(x + 3, y) && house(x - 3, y) && house(x, y + 3) && house(x, y - 3);
          if (core) {
            inside++;
            if (changed) changedInside++;
          } else if (changed) {
            changedOutside++;
          }
        }
      }
      expect(inside, greaterThan(100));
      expect(changedOutside, greaterThan(0), reason: 'a pessoa aparece onde a casa não cobre');
      // sobra só ruído de borda (o redesenho por cima do cache varia alguns pixels nas janelas e
      // na empena: ~1%); a pessoa por cima do telhado passa de 6% da casa
      expect(changedInside, lessThan(inside * .03), reason: 'dentro da casa não pode aparecer pedaço da pessoa');
    });
  }
}

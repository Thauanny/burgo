import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:burgo/domain/city_types.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/geometry/iso.dart';
import 'package:burgo/render/city_painter.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<int>> _frame(CityPainter painter, EditorState e, [String? png]) async {
  const size = ui.Size(700, 500);
  e.viewport.fit(e.city.size, size);
  e.clock.seconds = 1;
  final rec = ui.PictureRecorder();
  painter.paint(ui.Canvas(rec), size);
  final img = await rec.endRecording().toImage(700, 500);
  if (png != null) {
    final p = await img.toByteData(format: ui.ImageByteFormat.png);
    File(png).writeAsBytesSync(p!.buffer.asUint8List());
  }
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List().toList();
}

void main() {
  test('trocar de 3D para 2D refaz a marca da área especial (sem sobra da vista anterior)',
      () async {
    const systems = BuiltInSystemRepository();
    final e = EditorState(
        generator: const ProceduralCityGenerator(),
        systems: systems,
        random: Random(3))
      ..setSystem(systems.byId('t20'))
      ..generate(seed: 11, size: CitySize.village);
    expect(e.city.zone.version, greaterThanOrEqualTo(0));

    final reused = CityPainter(e, repaint: e);
    await _frame(reused, e); // aquece o cache na vista isométrica
    e.setViewMode(ViewMode.topDown);
    final afterSwitch = await _frame(reused, e, Platform.environment['VS_DIR'] == null ? null : '${Platform.environment['VS_DIR']}/after.png');

    final fresh = CityPainter(e, repaint: e);
    final expected = await _frame(fresh, e, Platform.environment['VS_DIR'] == null ? null : '${Platform.environment['VS_DIR']}/fresh.png');
    Iso.mode = ViewMode.isometric;
    // fração de pixels bem diferentes (a marca isométrica errada muda milhares de pixels)
    var diff = 0;
    for (var i = 0; i < afterSwitch.length; i += 4) {
      final d = (afterSwitch[i] - expected[i]).abs() +
          (afterSwitch[i + 1] - expected[i + 1]).abs() +
          (afterSwitch[i + 2] - expected[i + 2]).abs();
      if (d > 60) diff++;
    }
    final frac = diff / (afterSwitch.length / 4);
    expect(frac, lessThan(.004),
        reason: 'a área especial ficou desenhada na vista anterior ($diff px)');
  });
}

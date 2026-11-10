import 'dart:io';
import 'dart:ui' as ui;

import 'package:burgo/domain/city_types.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/render/city_painter.dart';
import 'package:burgo/render/layers/entities_layer.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quadros da caminhada', () async {
    const dir = '/private/tmp/claude-501/-Users-thauannyramos-burgo/258e82c3-abf1-4330-8cf6-ad9413a4313f/scratchpad/e30';
    const systems = BuiltInSystemRepository();
    final sys = systems.byId('t20');
    final editor = EditorState(generator: const ProceduralCityGenerator(), systems: systems)..setSystem(sys);
    editor.setSettlement(sys.art.settlements.firstWhere((s) => s.id == 'cidade_livre'));
    editor.generate(seed: 2024, size: CitySize.town);
    const size = ui.Size(1400, 900);
    editor.viewport.fit(editor.city.size, size);
    editor.viewport.zoomAround(size.center(ui.Offset.zero), editor.viewport.zoom * 2.6);
    EntitiesLayer.debugClips = true;
    final painter = CityPainter(editor, repaint: editor);
    for (final t in [6.5]) {
      editor.clock.seconds = t;
      final rec = ui.PictureRecorder();
      painter.paint(ui.Canvas(rec), size);
      final img = await rec.endRecording().toImage(1400, 900);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/walk_$t.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }
    editor.dispose();
  }, timeout: const Timeout(Duration(minutes: 3)));
}

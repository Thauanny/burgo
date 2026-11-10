import 'dart:io';
import 'dart:ui' as ui;

import 'package:burgo/domain/city_types.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/render/city_painter.dart';
import 'package:burgo/render/layers/entities_layer.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mede o custo de um quadro do mapa (gravar os comandos e rasterizar a imagem), com os
/// objetos vivos desenhados ao vivo e como sprites. Só informativo.
void main() {
  test('custo por quadro', () {
    const systems = BuiltInSystemRepository();
    final lines = <String>[];
    const size = ui.Size(1400, 900);
    for (final sys in systems.all) {
      final editor = EditorState(
          generator: const ProceduralCityGenerator(), systems: systems)
        ..setSystem(sys)
        ..generate(seed: 5, size: CitySize.metropolis);
      editor.viewport.fit(48, size);
      editor.viewport.zoomAround(size.center(ui.Offset.zero), 2.2);
      final results = <String>[];
      for (final sprites in [false, true]) {
        final entities = EntitiesLayer(useSprites: sprites);
        final painter = CityPainter(editor, entities: entities, repaint: editor);
        // aquece os caches (terreno, faixas e um ciclo inteiro de sprites)
        for (var i = 0; i < 12; i++) {
          editor.clock.seconds = i / 30;
          final rec = ui.PictureRecorder();
          painter.paint(ui.Canvas(rec), size);
          rec.endRecording().dispose();
        }
        const frames = 30;
        final record = Stopwatch(), raster = Stopwatch();
        for (var i = 0; i < frames; i++) {
          editor.clock.seconds = 1 + i / 30;
          final rec = ui.PictureRecorder();
          record.start();
          painter.paint(ui.Canvas(rec), size);
          final pic = rec.endRecording();
          record.stop();
          raster.start();
          pic.toImageSync(size.width.toInt(), size.height.toInt()).dispose();
          raster.stop();
          pic.dispose();
        }
        results.add('${sprites ? 'sprites' : 'ao vivo'}: '
            'gravar ${(record.elapsedMicroseconds / frames / 1000).toStringAsFixed(1)} ms, '
            'rasterizar ${(raster.elapsedMicroseconds / frames / 1000).toStringAsFixed(1)} ms'
            '${sprites ? ' (${entities.sprites.length} sprites)' : ''}');
        entities.dispose();
      }
      lines.add('${sys.id} (${editor.city.buildings.length} construções, '
          '${editor.city.props.length} objetos)\n  ${results.join('\n  ')}');
      editor.dispose();
    }
    stdout.writeln(lines.join('\n'));
  });
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:burgo/domain/city.dart';
import 'package:burgo/domain/city_types.dart';
import 'package:burgo/domain/dungeon.dart';
import 'package:burgo/domain/map_item.dart';
import 'package:burgo/dungeon/dungeon_generator.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/editor/viewport.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/geometry/iso.dart';
import 'package:burgo/render/city_painter.dart';
import 'package:burgo/render/dungeon/dungeon_painter.dart';
import 'package:burgo/render/dungeon/dungeon_scene.dart';
import 'package:burgo/systems/dungeon_profile.dart';
import 'package:burgo/systems/dungeon_profiles.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gera PNGs de cada sistema para revisão visual.
/// Uso: SNAPSHOT_DIR=/caminho flutter test test/render_snapshot_test.dart
void main() {
  final dir = Platform.environment['SNAPSHOT_DIR'];
  final only = Platform.environment['SNAPSHOT_SYSTEM'];
  final seconds =
      double.tryParse(Platform.environment['SNAPSHOT_TIME'] ?? '') ?? 0;

  test('snapshots', () async {
    const systems = BuiltInSystemRepository();
    for (final sys in systems.all) {
      if (only != null && only != sys.id) continue;
      for (final type in sys.art.settlements) {
        final editor = EditorState(
            generator: const ProceduralCityGenerator(), systems: systems)
          ..setSystem(sys)
          ..setSettlement(type)
          ..generate(seed: 2024, size: CitySize.town);
        if (Platform.environment['SNAPSHOT_VIEW'] == 'top') {
          editor.setViewMode(ViewMode.topDown);
        }
        const size = ui.Size(1400, 900);
        editor.viewport.fit(editor.city.size, size);
        editor.clock.seconds = seconds;
        final recorder = ui.PictureRecorder();
        CityPainter(editor, repaint: editor).paint(ui.Canvas(recorder), size);
        final image = await recorder.endRecording().toImage(1400, 900);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$dir/${sys.id}_${type.id}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        editor.dispose();
        Iso.mode = ViewMode.isometric;
      }
    }
  }, skip: dir == null ? 'defina SNAPSHOT_DIR' : false);

  test('vitrine de construções e objetos', () async {
    const systems = BuiltInSystemRepository();
    final sys = systems.byId(only ?? 't20');
    final editor = EditorState(
        generator: const ProceduralCityGenerator(), systems: systems)
      ..setSystem(sys);
    final city = City(name: 'Vitrine', seed: 1, size: 24, systemId: sys.id);
    var id = 1;
    var col = 1, row = 1;
    final kinds = Platform.environment['SNAPSHOT_KINDS']?.split(',');
    for (final kind in BuildingKind.values) {
      if (kinds != null && !kinds.contains(kind.name)) continue;
      final spec = BuildingKindSpec.of(kind);
      final (w, d) = spec.footprints.last;
      if (col + w > 23) {
        col = 1;
        row += 5;
      }
      city.add(Building(
        id: id++,
        x: col,
        y: row,
        width: w,
        depth: d,
        floors: spec.maxFloors,
        kind: kind,
        roof: spec.roofs.first,
        wall: sys.walls.first,
        roofColor: sys.roofs.first,
        chimney: true,
      ));
      col += w + 1;
    }
    row += 5;
    col = 1;
    for (final type in kinds != null ? <PropType>[] : PropType.values) {
      if (col > 22) {
        col = 1;
        row += 2;
      }
      city.add(Prop(id: id++, x: col, y: row, type: type));
      col += 2;
    }
    editor.city = city;
    const size = ui.Size(1600, 1000);
    editor.viewport
      ..zoom = kinds != null ? 1.25 : 1.05
      ..pan = kinds != null ? const ui.Offset(560, 260) : const ui.Offset(800, 40);
    editor.clock.seconds = seconds;
    final recorder = ui.PictureRecorder();
    CityPainter(editor, repaint: editor).paint(ui.Canvas(recorder), size);
    final image = await recorder.endRecording().toImage(1600, 1000);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/showcase_${sys.id}.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    editor.dispose();
  },
      skip: dir == null || Platform.environment['SNAPSHOT_SHOWCASE'] == null
          ? 'defina SNAPSHOT_SHOWCASE'
          : false);

  test('masmorras', () async {
    for (final sysId in ['t20', 'loop', 'dnd5e']) {
      final d = const RoomsAndCorridorsGenerator().generate(
        DungeonRequest(
            seed: 7,
            size: 36,
            systemId: sysId,
            profile: DungeonProfiles.of(sysId)),
      );
      final scene = _FakeDungeonScene(
          d,
          DungeonProfiles.of(sysId),
          seconds,
          Platform.environment['SNAPSHOT_VIEW'] == 'top'
              ? ViewMode.topDown
              : ViewMode.isometric);
      Iso.mode = scene.viewMode;
      final vp = Viewport()..fit(d.size, const ui.Size(1400, 900));
      scene
        ..pan = vp.pan
        ..zoom = vp.zoom;
      final recorder = ui.PictureRecorder();
      DungeonPainter(scene, repaint: vp)
          .paint(ui.Canvas(recorder), const ui.Size(1400, 900));
      final image = await recorder.endRecording().toImage(1400, 900);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/dungeon_$sysId.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      Iso.mode = ViewMode.isometric;
    }
  },
      skip: dir == null || Platform.environment['SNAPSHOT_DUNGEON'] == null
          ? 'defina SNAPSHOT_DUNGEON'
          : false);
}

class _FakeDungeonScene implements DungeonScene {
  _FakeDungeonScene(this.dungeon, this.profile, this.time, this.viewMode);
  @override
  final Dungeon dungeon;
  @override
  final DungeonProfile profile;
  @override
  final double time;
  @override
  final ViewMode viewMode;
  @override
  ui.Offset pan = ui.Offset.zero;
  @override
  double zoom = 1;
  @override
  ui.Rect get visibleScene => const ui.Rect.fromLTRB(-1e9, -1e9, 1e9, 1e9);
  @override
  int get rotation => 0;
  @override
  (int, int)? get hoverCell => (12, 12);
  @override
  Object? get previewMonster => null;
  @override
  DungeonPropType? get previewProp => DungeonPropType.chest;
}

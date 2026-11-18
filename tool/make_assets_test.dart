// Gera o ícone (aba, manifesto, README), a imagem de compartilhamento e as capturas do README.
// Os nomes do mapa são tirados das capturas: o ambiente de teste não tem fontes.
// A galeria da página sobre.html usa as capturas de docs/img/galeria/, convertidas para JPEG em web/img/.
// Uso: flutter test tool/make_assets_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:burgo/domain/dungeon.dart';
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
import 'package:burgo/ui/brand_icon.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _png(String path, int w, int h, void Function(ui.Canvas) draw) async {
  final rec = ui.PictureRecorder();
  draw(ui.Canvas(rec));
  final img = await rec.endRecording().toImage(w, h);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

ui.Image? _last;

Future<ui.Image> _city(String sys, String? st, {required double zoom, int seed = 2024, ui.Size size = const ui.Size(1400, 820), double t = 2}) async {
  const systems = BuiltInSystemRepository();
  final e = EditorState(generator: const ProceduralCityGenerator(), systems: systems)..setSystem(systems.byId(sys));
  if (st != null) e.setSettlement(e.system.art.settlements.firstWhere((s) => s.id == st));
  e.generate(seed: seed);
  // sem nomes no mapa (o ambiente de teste não tem fontes)
  for (final l in e.city.labels.toList()) {
    e.city.removeLabel(l.id);
  }
  e.viewport.fit(e.city.size, size, tilesY: e.city.tilesY);
  e.viewport.zoomAround(size.center(ui.Offset.zero), e.viewport.zoom * zoom);
  e.clock.seconds = t;
  // os testes não têm fontes: sem textos (régua) nas capturas
  e.setShowScaleBar(false);
  final painter = CityPainter(e, repaint: e);
  final rec = ui.PictureRecorder();
  painter.paint(ui.Canvas(rec), size);
  final img = await rec.endRecording().toImage(size.width.toInt(), size.height.toInt());
  e.dispose();
  Iso.mode = ViewMode.isometric;
  return _last = img;
}

Future<void> _save(ui.Image img, String path) async {
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('ícones', () async {
    for (final (path, size) in const [
      ('web/favicon.png', 64),
      ('web/icons/Icon-192.png', 192),
      ('web/icons/Icon-512.png', 512),
      ('docs/img/icon.png', 256),
    ]) {
      await _png(path, size, size, (c) => BrandIconPainter.paintIcon(c, size.toDouble()));
    }
    for (final (path, size) in const [('web/icons/Icon-maskable-192.png', 192), ('web/icons/Icon-maskable-512.png', 512)]) {
      await _png(path, size, size, (c) => BrandIconPainter.paintIcon(c, size.toDouble(), background: false, safeZone: .78));
    }
  });

  test('capturas do README', () async {
    await _save(await _city('t20', 'cidade_livre', zoom: 1.7), 'docs/img/cidade-t20.png');
    await _save(await _city('dnd5e', 'vila_fronteira', zoom: 1.6, seed: 77), 'docs/img/vila-dnd.png');
    await _save(await _city('loop', 'fazendas_loop', zoom: 1.5, seed: 11), 'docs/img/loop.png');
    // masmorra
    final d = const RoomsAndCorridorsGenerator()
        .generate(DungeonRequest(seed: 7, size: 36, systemId: 't20', profile: DungeonProfiles.of('t20')));
    final scene = _DungeonShot(d);
    final vp = Viewport()..fit(d.size, const ui.Size(1400, 820));
    scene.pan = vp.pan;
    scene.zoom = vp.zoom;
    final rec = ui.PictureRecorder();
    DungeonPainter(scene, repaint: vp).paint(ui.Canvas(rec), const ui.Size(1400, 820));
    await _save(await rec.endRecording().toImage(1400, 820), 'docs/img/masmorra-t20.png');

    // imagem de compartilhamento (Open Graph): ícone à esquerda, cidade à direita
    final city = await _city('t20', 'cidade_livre', zoom: 2.1, size: const ui.Size(760, 630), t: 3);
    await _png('web/icons/og-image.png', 1200, 630, (c) {
      c.drawRect(const ui.Rect.fromLTWH(0, 0, 1200, 630), ui.Paint()..color = const ui.Color(0xFFF3EBDA));
      c.drawImage(city, const ui.Offset(440, 0), ui.Paint());
      c.drawRect(const ui.Rect.fromLTWH(436, 0, 6, 630), ui.Paint()..color = const ui.Color(0xFF2B2A33));
      c.save();
      c.translate(70, 165);
      BrandIconPainter.paintIcon(c, 300);
      c.restore();
    });
    expect(_last, isNotNull);
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('galeria da página sobre', () async {
    for (final (sys, st, zoom, seed, name) in const [
      ('t20', 'voadora', 1.0, 4, 'vectora'),
      ('t20', 'oriental', 1.7, 5, 'nitamura'),
      ('t20', 'feerica', 1.25, 6, 'pondsmania'),
      ('t20', 'elfica', 1.7, 2, 'lenorienn'),
      ('t20', 'oeste', 1.6, 4, 'smokestone'),
      ('t20', 'porto', 1.6, 3, 'malpetrim'),
      ('dnd5e', 'bryn_shander', 1.5, 2, 'bryn-shander'),
      ('loop', 'malaren', 1.3, 2, 'malaren'),
    ]) {
      await _save(await _city(sys, st, zoom: zoom, seed: seed), 'docs/img/galeria/$name.png');
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}

class _DungeonShot implements DungeonScene {
  _DungeonShot(this.dungeon);
  @override
  final Dungeon dungeon;
  @override
  DungeonProfile get profile => DungeonProfiles.of(dungeon.systemId);
  @override
  double get time => 1.3;
  @override
  ViewMode get viewMode => ViewMode.isometric;
  @override
  ui.Offset pan = ui.Offset.zero;
  @override
  double zoom = 1;
  @override
  ui.Rect get visibleScene => const ui.Rect.fromLTRB(-1e9, -1e9, 1e9, 1e9);
  @override
  int get rotation => 0;
  @override
  (int, int)? get hoverCell => null;
  @override
  Object? get previewMonster => null;
  @override
  DungeonPropType? get previewProp => null;
}

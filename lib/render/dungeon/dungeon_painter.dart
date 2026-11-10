import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import '../../domain/city_types.dart';
import '../../domain/dungeon.dart';
import '../../domain/map_item.dart';
import '../../geometry/iso.dart';
import '../../systems/art_profile.dart' show AnomalyStyle;
import '../layers/compass_layer.dart';
import '../layers/paper_layer.dart';
import '../layers/prop_renderer.dart';
import '../raster_image.dart';
import '../sprite_cache.dart';
import 'dungeon_art.dart';
import 'dungeon_scene.dart';

/// Guarda a cópia girada da masmorra, a imagem em cache dela, as luzes e os monstros.
class DungeonRaster {
  final RasterImage _image = RasterImage();
  final RasterScaler scaler = RasterScaler();
  final SpriteCache sprites = SpriteCache();
  late final PropRenderer props = PropRenderer(sprites: sprites);
  Dungeon? _source, shown;
  int _version = -1, _rot = -1;
  String _key = '';
  double _scale = 0;

  /// Luzes (x, y, tipo) e monstros (x, y, tipo) na vista girada.
  final List<(int, int, DungeonPropType)> lights = [];
  final List<Prop> monsters = [];

  /// Atualiza a cópia girada e a imagem se a masmorra, o giro, a vista ou o zoom mudaram.
  void sync(DungeonScene scene, double scale) {
    final d = scene.dungeon;
    final key = '${scene.profile.title}/${Iso.mode.name}';
    final rot = scene.rotation;
    if (shown == null || !identical(_source, d) || _version != d.version || _rot != rot) {
      shown = d.displayed(Iso.displayTile);
      lights
        ..clear()
        ..addAll([
          for (final p in shown!.props)
            if (dungeonLights.contains(p.type)) (p.x, p.y, p.type)
        ]);
      monsters
        ..clear()
        ..addAll([
          for (final p in shown!.props)
            if (p.type == DungeonPropType.monster && p.monster != null)
              Prop(id: p.id, x: p.x, y: p.y, type: p.monster!)
        ])
        ..sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
      _image.dispose();
    }
    if (_image.isEmpty || _key != key || _scale != scale) {
      Iso.raw(() => _image.build(DungeonArt.boundsOf(shown!), scale,
          (c) => DungeonArt.paintStatic(c, shown!, scene.profile)));
      _key = key;
      _scale = scale;
    }
    _source = d;
    _version = d.version;
    _rot = rot;
  }

  void paintImage(Canvas cv) => _image.paint(cv);

  void dispose() {
    _image.dispose();
    sprites.clear();
  }
}

/// Desenha a masmorra: fundo escuro, imagem em cache, monstros animados, chamas, escuridão
/// com círculos de luz, pré-visualização, bússola e papel.
class DungeonPainter extends CustomPainter {
  DungeonPainter(this.scene,
      {required Listenable repaint, DungeonRaster? raster, PaperLayer? paper})
      : raster = raster ?? DungeonRaster(),
        paper = paper ?? PaperLayer(),
        super(repaint: repaint);

  final DungeonScene scene;
  final DungeonRaster raster;
  final PaperLayer paper;
  final CompassLayer _compass = CompassLayer();

  @override
  void paint(Canvas canvas, Size size) {
    final d = scene.dungeon;
    Iso.configure(scene.viewMode, scene.rotation, d.size, d.size);
    final rect = Offset.zero & size;
    final sky = scene.profile.sky;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height),
            [Color.lerp(sky, const Color(0xFF000000), .35)!, sky]),
    );
    final dpr = ui.PlatformDispatcher.instance.views.isEmpty
        ? 1.0
        : ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    // célula do cursor já na vista girada (antes de desenhar sem giro)
    final hover = scene.hoverCell;
    final hoverShown = hover == null ? null : Iso.displayTile(hover.$1, hover.$2);
    final savedRot = Iso.rot;
    try {
      Iso.rot = 0;
      final bounds = DungeonArt.boundsOf(d);
      final scale = raster.scaler.update(
          zoom: scene.zoom, devicePixelRatio: dpr, sceneArea: bounds.width * bounds.height);
      raster.sync(scene, scale);
      final shown = raster.shown!;
      canvas
        ..save()
        ..translate(scene.pan.dx, scene.pan.dy)
        ..scale(scene.zoom);
      raster.paintImage(canvas);
      _monsters(canvas, scale);
      _flames(canvas, shown);
      _darkness(canvas, DungeonArt.boundsOf(shown));
      _preview(canvas, shown, hoverShown);
      canvas.restore();
    } finally {
      Iso.rot = savedRot;
    }
    _compass.paint(canvas, size);
    paper.paint(canvas, size);
  }

  void _monsters(Canvas cv, double scale) {
    final view = scene.visibleScene.inflate(120);
    raster.sprites.beginFrame();
    for (final m in raster.monsters) {
      if (!view.contains(Iso.pt(m.x + .5, m.y + .5))) continue;
      raster.props.paint(cv, m,
          zoneColor: scene.profile.accent,
          time: scene.time,
          anomaly: AnomalyStyle.none,
          scale: scale);
    }
  }

  static Offset lightPoint(Dungeon d, int x, int y, DungeonPropType type) {
    final onNorth = !d.isOpen(x, y - 1);
    return switch (type) {
      DungeonPropType.torch =>
        (onNorth ? Iso.pt(x + .5, y + .02, 20) : Iso.pt(x + .02, y + .5, 20)).translate(0, -4),
      DungeonPropType.brazier => Iso.pt(x + .5, y + .5).translate(0, -16),
      DungeonPropType.crystal => Iso.pt(x + .5, y + .5).translate(0, -10),
      DungeonPropType.mushroom => Iso.pt(x + .5, y + .5).translate(0, -5),
      DungeonPropType.console => Iso.pt(x + .5, y + .65, 12),
      _ => Iso.pt(x + .5, y + .5).translate(0, -6),
    };
  }

  void _flames(Canvas cv, Dungeon d) {
    final view = scene.visibleScene.inflate(60);
    final t = scene.time;
    final pr = scene.profile;
    for (final (x, y, type) in raster.lights) {
      final p = lightPoint(d, x, y, type);
      if (!view.contains(p)) continue;
      switch (type) {
        case DungeonPropType.torch || DungeonPropType.brazier:
          final big = type == DungeonPropType.brazier;
          final flick = .75 + .25 * sin(t * 9 + x * 3.1 + y * 1.7) + .1 * sin(t * 23 + x);
          final s = big ? 1.7 : 1.0;
          cv.drawCircle(p, 16 * flick * s, Paint()..color = pr.torch.withValues(alpha: .16));
          final flame = Path()
            ..moveTo(p.dx - 3 * s, p.dy + 3)
            ..quadraticBezierTo(p.dx - 4 * s, p.dy - 4 * s, p.dx + sin(t * 8 + x) * 1.5, p.dy - 10 * flick * s)
            ..quadraticBezierTo(p.dx + 4 * s, p.dy - 4 * s, p.dx + 3 * s, p.dy + 3)
            ..close();
          cv.drawPath(flame, Paint()..color = pr.torch);
          cv.drawPath(flame.shift(const Offset(0, 2)), Paint()..color = const Color(0xFFFFF2C4));
          // faíscas
          for (var i = 0; i < 2; i++) {
            final ph = (t * .8 + i / 2 + x * .1) % 1;
            cv.drawCircle(p.translate(sin(ph * 7 + y) * 4, -8 * s - ph * 18), 1 - ph * .5,
                Paint()..color = pr.torch.withValues(alpha: 1 - ph));
          }
        case DungeonPropType.crystal:
          final pulse = .6 + .4 * sin(t * 2.2 + x + y);
          cv.drawCircle(p, 10 + 4 * pulse, Paint()..color = pr.accent.withValues(alpha: .12 * pulse));
        case DungeonPropType.mushroom:
          final pulse = .6 + .4 * sin(t * 1.4 + x * .7);
          cv.drawCircle(p, 9, Paint()..color = pr.accent.withValues(alpha: .1 * pulse));
        case DungeonPropType.console:
          if (sin(t * 3 + x) > 0) {
            cv.drawCircle(p.translate(4, -4), 1.2, Paint()..color = const Color(0xFF6DAF5A));
          }
        default:
          break;
      }
    }
  }

  /// Escuridão da masmorra: tudo escurece, menos círculos em volta das luzes.
  void _darkness(Canvas cv, Rect bounds) {
    final pr = scene.profile;
    if (pr.darkness <= 0) return;
    final view = scene.visibleScene.inflate(300);
    final area = bounds.intersect(view);
    if (area.isEmpty) return;
    cv.saveLayer(area, Paint());
    cv.drawRect(area, Paint()..color = Color.fromRGBO(6, 4, 10, pr.darkness));
    final t = scene.time;
    final d = raster.shown!;
    for (final (x, y, type) in raster.lights) {
      final p = lightPoint(d, x, y, type);
      final base = switch (type) {
        DungeonPropType.torch => 128.0,
        DungeonPropType.brazier => 165.0,
        DungeonPropType.crystal => 95.0,
        DungeonPropType.mushroom => 60.0,
        DungeonPropType.console => 90.0,
        _ => 110.0,
      };
      final flick = type == DungeonPropType.torch || type == DungeonPropType.brazier
          ? 1 + .06 * sin(t * 9 + x * 3.1 + y * 1.7)
          : 1 + .04 * sin(t * 2 + x);
      final r = base * flick;
      final rect = Rect.fromCircle(center: p, radius: r);
      if (!rect.overlaps(area)) continue;
      cv.drawCircle(
          p,
          r,
          Paint()
            ..blendMode = BlendMode.dstOut
            ..shader = const RadialGradient(
              colors: [Color(0xFFFFFFFF), Color(0xB3FFFFFF), Color(0x00FFFFFF)],
              stops: [0, .45, 1],
            ).createShader(rect));
    }
    cv.restore();
  }

  void _preview(Canvas cv, Dungeon shown, (int, int)? cell) {
    if (cell == null || !shown.inBounds(cell.$1, cell.$2)) return;
    final (x, y) = cell;
    final tile = Iso.diamond(x.toDouble(), y.toDouble(), 1, 1);
    cv.drawPath(tile, Paint()..color = const Color(0x55FFFFFF));
    cv.drawPath(
      tile,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final type = scene.previewProp;
    if (type != null && shown.isOpen(x, y) && shown.propAt(x, y) == null) {
      final c = Iso.pt(x + .5, y + .5, 20);
      cv.saveLayer(Rect.fromCenter(center: c, width: 200, height: 200),
          Paint()..color = const Color.fromARGB(170, 255, 255, 255));
      final monster = scene.previewMonster;
      if (type == DungeonPropType.monster && monster is PropType) {
        raster.props.paint(cv, Prop(id: -1, x: x, y: y, type: monster),
            zoneColor: scene.profile.accent, time: scene.time, anomaly: AnomalyStyle.none, scale: raster.scaler.scale);
      } else {
        DungeonArt.paintProp(cv, shown, scene.profile, type, x, y);
      }
      cv.restore();
    }
  }

  @override
  bool shouldRepaint(covariant DungeonPainter old) => true;
}

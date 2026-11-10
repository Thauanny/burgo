import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../domain/city.dart';
import '../domain/dungeon.dart';
import '../domain/map_item.dart';
import '../domain/placement_preview.dart';
import '../dungeon/dungeon_editor.dart';
import '../editor/editor_state.dart';
import '../geometry/iso.dart';
import '../project/project_editor.dart';
import '../systems/dungeon_profile.dart';
import '../systems/rpg_system.dart';
import '../systems/settlement_type.dart';
import 'city_painter.dart';
import 'dungeon/dungeon_art.dart';
import 'dungeon/dungeon_painter.dart';
import 'dungeon/dungeon_scene.dart';
import 'layers/entities_layer.dart';
import 'layers/ground_layer.dart';
import 'layers/paper_layer.dart';
import 'scene_view.dart';

/// Renderiza o mapa inteiro de um projeto (cidade ou masmorra) numa imagem PNG, na vista
/// pedida, sem cursor, seleção nem pré-visualização. Não mexe na vista do editor.
abstract final class MapImageExport {
  /// Pixels por unidade da cena (um tile isométrico tem 64 unidades de largura).
  static const double pixelsPerUnit = 2;

  /// Lado máximo da imagem, em pixels (limite dos navegadores para `canvas`).
  static const int maxSide = 8192;

  static Future<Uint8List> png(ProjectEditor editor, {required ViewMode mode}) async {
    final image = switch (editor) {
      final EditorState e => await _city(e, mode),
      final DungeonEditor d => await _dungeon(d, mode),
      _ => throw UnsupportedError('projeto sem imagem'),
    };
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes!.buffer.asUint8List();
    } finally {
      image.dispose();
      editor.activateProjection();
    }
  }

  static (double, ui.Size, ui.Offset) _frame(ui.Rect bounds) {
    final zoom = min(pixelsPerUnit, maxSide / max(bounds.width, bounds.height));
    final size = ui.Size((bounds.width * zoom).ceilToDouble(), (bounds.height * zoom).ceilToDouble());
    return (zoom, size, -bounds.topLeft * zoom);
  }

  static Future<ui.Image> _city(EditorState editor, ViewMode mode) async {
    Iso.configure(mode, editor.rotation, editor.city.tilesX, editor.city.tilesY);
    final bounds = GroundLayer.boundsOf(editor.city, editor.settlement.floating).inflate(48);
    final (zoom, size, pan) = _frame(bounds);
    final scene = _CityExportScene(editor, mode: mode, zoom: zoom, pan: pan, bounds: bounds);
    final ground = GroundLayer(), entities = EntitiesLayer(), paper = PaperLayer();
    final painter = CityPainter(scene, repaint: editor, ground: ground, entities: entities, paper: paper);
    try {
      final rec = ui.PictureRecorder();
      painter.paint(ui.Canvas(rec), size);
      final picture = rec.endRecording();
      try {
        return await picture.toImage(size.width.toInt(), size.height.toInt());
      } finally {
        picture.dispose();
      }
    } finally {
      ground.dispose();
      entities.dispose();
      paper.dispose();
    }
  }

  static Future<ui.Image> _dungeon(DungeonEditor editor, ViewMode mode) async {
    Iso.configure(mode, editor.rotation, editor.dungeon.size, editor.dungeon.size);
    final bounds = DungeonArt.boundsOf(editor.dungeon).inflate(40);
    final (zoom, size, pan) = _frame(bounds);
    final scene = _DungeonExportScene(editor, mode: mode, zoom: zoom, pan: pan, bounds: bounds);
    final raster = DungeonRaster(), paper = PaperLayer();
    final painter = DungeonPainter(scene, repaint: editor, raster: raster, paper: paper);
    try {
      final rec = ui.PictureRecorder();
      painter.paint(ui.Canvas(rec), size);
      final picture = rec.endRecording();
      try {
        return await picture.toImage(size.width.toInt(), size.height.toInt());
      } finally {
        picture.dispose();
      }
    } finally {
      raster.dispose();
      paper.dispose();
    }
  }
}

/// A cena do editor vista inteira, parada e sem marcas de edição.
class _CityExportScene implements SceneView {
  _CityExportScene(this.e, {required this.mode, required this.zoom, required this.pan, required this.bounds});
  final EditorState e;
  final ViewMode mode;
  @override
  final double zoom;
  @override
  final ui.Offset pan;
  final ui.Rect bounds;

  @override
  City get city => e.city;
  @override
  RpgSystem get system => e.system;
  @override
  SettlementType get settlement => e.settlement;
  @override
  MapItem? get selected => null;
  @override
  TerrainPalette get palette => e.palette;
  @override
  ui.Rect get visibleScene => bounds;
  @override
  ViewMode get viewMode => mode;
  @override
  int get rotation => e.rotation;
  @override
  bool get showScaleBar => e.showScaleBar;
  @override
  bool get showZoneRadius => false;
  @override
  int? get selectedZoneId => null;
  @override
  Point<int>? get rulerStart => null;
  @override
  Point<int>? get hoverTile => null;
  @override
  double get time => e.time;
  @override
  PlacementPreview? get preview => null;
}

class _DungeonExportScene implements DungeonScene {
  _DungeonExportScene(this.e, {required this.mode, required this.zoom, required this.pan, required this.bounds});
  final DungeonEditor e;
  final ViewMode mode;
  @override
  final double zoom;
  @override
  final ui.Offset pan;
  final ui.Rect bounds;

  @override
  Dungeon get dungeon => e.dungeon;
  @override
  DungeonProfile get profile => e.profile;
  @override
  double get time => e.time;
  @override
  ViewMode get viewMode => mode;
  @override
  ui.Rect get visibleScene => bounds;
  @override
  int get rotation => e.rotation;
  @override
  (int, int)? get hoverCell => null;
  @override
  DungeonPropType? get previewProp => null;
  @override
  Object? get previewMonster => null;
}

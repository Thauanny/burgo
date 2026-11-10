import 'dart:ui';
import '../../domain/map_item.dart';
import '../../domain/placement_preview.dart';
import '../../geometry/iso.dart';
import '../draw_helpers.dart';
import '../scene_view.dart';
import 'entities_layer.dart';

/// Seleção, realce do tile sob o cursor e fantasma do item a colocar.
class OverlayLayer {
  const OverlayLayer(this.entities);
  final EntitiesLayer entities;

  static const _selectionColor = Color(0xFFFFC83D);
  static const _validFill = Color.fromRGBO(110, 220, 130, 0.5);
  static const _invalidFill = Color.fromRGBO(240, 90, 90, 0.5);

  void paint(Canvas cv, SceneView scene) {
    _selection(cv, scene);
    switch (scene.preview) {
      case null:
        break;
      case final TilePreview p:
        _tile(cv, p);
      case final ItemPreview p:
        _ghost(cv, p, scene);
      case RadiusPreview _:
        break; // o anel do raio é desenhado pela camada de anotações
    }
  }

  Paint _outline(Color col, double w) => Paint()
    ..color = col
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round;

  void _selection(Canvas cv, SceneView scene) {
    final item = scene.selected;
    if (item == null) return;
    final path = switch (item) {
      final Building b =>
        Iso.diamond(b.x - .15, b.y - .15, b.width + .3, b.depth + .3),
      final Farm f =>
        Iso.diamond(f.x - .1, f.y - .1, f.width + .2, f.depth + .2),
      _ => Iso.diamond(item.x.toDouble(), item.y.toDouble(), 1, 1),
    };
    cv.drawPath(path, _outline(_selectionColor, 3));
  }

  void _tile(Canvas cv, TilePreview p) {
    final tile = Iso.diamond(p.x.toDouble(), p.y.toDouble(), 1, 1);
    switch (p.kind) {
      case TilePreviewKind.hover:
        cv.drawPath(
            tile, _outline(const Color.fromRGBO(255, 255, 255, 0.7), 2));
      case TilePreviewKind.paint:
        fillPoly(cv, tile, const Color.fromRGBO(255, 255, 255, 0.35),
            line: const Color(0xFFFFFFFF), lw: 2);
      case TilePreviewKind.erase:
        fillPoly(cv, tile, const Color.fromRGBO(240, 80, 80, 0.4),
            line: const Color(0xFFE05050), lw: 2);
    }
  }

  void _ghost(Canvas cv, ItemPreview p, SceneView scene) {
    final item = p.item;
    final footprint = switch (item) {
      final Building b => Iso.diamond(b.x.toDouble(), b.y.toDouble(),
          b.width.toDouble(), b.depth.toDouble()),
      final Farm f => Iso.diamond(f.x.toDouble(), f.y.toDouble(),
          f.width.toDouble(), f.depth.toDouble()),
      Prop _ => Iso.diamond(item.x.toDouble(), item.y.toDouble(), 1, 1),
    };
    fillPoly(cv, footprint, p.isValid ? _validFill : _invalidFill);
    // a camada temporária cobre só o item (não a tela inteira), que é bem mais barato
    final (w, d) = switch (item) {
      final Building b => (b.width, b.depth),
      final Farm f => (f.width, f.depth),
      _ => (1, 1),
    };
    final center = Iso.pt(item.x + w / 2, item.y + d / 2, 40);
    final bounds = Rect.fromCenter(
        center: center,
        width: (w + d) * 40.0 + 200,
        height: (w + d) * 20.0 + 320);
    cv.saveLayer(
        bounds, Paint()..color = const Color.fromARGB(170, 255, 255, 255));
    entities.paintItemOnMap(cv, item, scene);
    cv.restore();
  }
}

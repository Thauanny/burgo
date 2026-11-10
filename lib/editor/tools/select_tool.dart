import 'dart:math';
import 'dart:ui';
import '../../domain/placement_preview.dart';
import '../tool.dart';

/// Seleciona itens e permite arrastá-los respeitando as regras de posição.
class SelectTool extends Tool {
  SelectTool() : super(ToolId.select);

  Point<int> _grabOffset = const Point(0, 0);

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) =>
      host.select(host.pickAt(scene));

  @override
  bool onDragStart(ToolHost host, Offset scene, Point<int> tile) {
    final item = host.pickAt(scene);
    if (item == null) return false;
    host.select(item);
    host.beginEdit();
    _grabOffset = Point(tile.x - item.x, tile.y - item.y);
    return true;
  }

  @override
  void onDragUpdate(ToolHost host, Point<int> tile) {
    final item = host.selected;
    if (item == null) return;
    final nx = tile.x - _grabOffset.x, ny = tile.y - _grabOffset.y;
    if (nx == item.x && ny == item.y) return;
    final moved = item.movedTo(nx, ny);
    if (host.rules.canPlace(moved, ignoreId: item.id)) host.moveItem(moved);
  }

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) =>
      TilePreview(tile.x, tile.y, TilePreviewKind.hover);
}

/// Mover: arrastar sempre move o mapa e clicar não altera nada.
class PanTool extends Tool {
  PanTool() : super(ToolId.pan);
}

import 'dart:math';
import 'dart:ui';
import '../../domain/map_item.dart';
import '../../domain/placement_preview.dart';
import '../tool.dart';

/// Coloca uma cópia do modelo de fazenda (`farmDraft`) com o canto no tile clicado.
class FarmTool extends Tool {
  FarmTool() : super(ToolId.farm);

  Farm _placeAt(ToolHost host, Point<int> tile) {
    final d = host.farmDraft;
    return d.copyWith(x: tile.x - d.width ~/ 2, y: tile.y - d.depth ~/ 2);
  }

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) {
    final f = _placeAt(host, tile).copyWith(id: host.city.newId());
    if (host.rules.canPlaceFarm(f)) host.addItem(f);
  }

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) {
    final f = _placeAt(host, tile);
    return ItemPreview(f, isValid: host.rules.canPlaceFarm(f));
  }
}

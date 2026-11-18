import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../domain/placement_preview.dart';
import '../tool.dart';
import 'prop_tool.dart';

/// Fazenda: coloca uma plantação (cópia do modelo `farmDraft`) ou, se um objeto da fazenda
/// foi escolhido (cerca, feno, carroça, animal...), coloca esse objeto.
class FarmTool extends Tool {
  FarmTool() : super(ToolId.farm);

  final _props = _FarmPropTool();

  Farm _placeAt(ToolHost host, Point<int> tile) {
    final d = host.farmDraft;
    return d.copyWith(x: tile.x - d.width ~/ 2, y: tile.y - d.depth ~/ 2);
  }

  @override
  bool onDragStart(ToolHost host, Offset scene, Point<int> tile) =>
      host.farmProp != null && _props.onDragStart(host, scene, tile);

  @override
  void onDragUpdate(ToolHost host, Point<int> tile) {
    if (host.farmProp != null) _props.onDragUpdate(host, tile);
  }

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) {
    if (host.farmProp != null) return _props.onTap(host, scene, tile);
    final f = _placeAt(host, tile).copyWith(id: host.city.newId());
    if (host.rules.canPlaceFarm(f)) host.addItem(f);
  }

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) {
    if (host.farmProp != null) return _props.previewAt(host, tile);
    final f = _placeAt(host, tile);
    return ItemPreview(f, isValid: host.rules.canPlaceFarm(f));
  }
}

class _FarmPropTool extends PropTool {
  _FarmPropTool() : super(ToolId.farm);

  @override
  PropType typeOf(ToolHost host) => host.farmProp!;
}

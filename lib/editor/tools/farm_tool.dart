import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../domain/placement_preview.dart';
import '../../domain/placement_rules.dart';
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

  /// Onde a plantação fica: centrada no tile clicado ou, se ali não couber por pouco, no lugar
  /// válido mais perto (até 2 tiles de distância). Sem lugar, devolve a centrada (inválida).
  (Farm, bool) _fitAt(ToolHost host, Point<int> tile) {
    final base = _placeAt(host, tile);
    for (final (dx, dy) in _offsets) {
      final f = base.copyWith(x: base.x + dx, y: base.y + dy);
      if (host.rules.canPlaceFarm(f, clearPlants: true)) return (f, true);
    }
    return (base, false);
  }

  static final List<(int, int)> _offsets = [
    for (var dx = -2; dx <= 2; dx++)
      for (var dy = -2; dy <= 2; dy++) (dx, dy)
  ]..sort((a, b) => (a.$1.abs() + a.$2.abs()).compareTo(b.$1.abs() + b.$2.abs()));

  /// Leva quem anda para fora da plantação nova (o tile livre mais perto).
  void _moveWalkersOut(ToolHost host, Farm f) {
    final city = host.city;
    for (final p in city.props.where((p) => f.occupies(p.x, p.y) && PlacementRules.isWalker(p.type)).toList()) {
      Point<int>? best;
      for (var r = 1; r <= 6 && best == null; r++) {
        for (var x = f.x - r; x < f.x + f.width + r && best == null; x++) {
          for (var y = f.y - r; y < f.y + f.depth + r && best == null; y++) {
            if (f.occupies(x, y)) continue;
            if (host.rules.canPlaceProp(x, y, p.type, ignoreId: p.id)) best = Point(x, y);
          }
        }
      }
      if (best != null) {
        city.replace(p.movedTo(best.x, best.y));
      } else {
        city.remove(p);
      }
    }
  }

  /// Nomes das construções da fazenda (a ferramenta Fazenda põe cada uma já no tamanho padrão).
  static const _names = {
    BuildingKind.countryHouse: 'Casa de campo',
    BuildingKind.farmhouse: 'Casa de sítio',
    BuildingKind.barn: 'Celeiro',
    BuildingKind.stable: 'Estábulo',
    BuildingKind.silo: 'Silo',
    BuildingKind.windmill: 'Moinho',
    BuildingKind.greenhouse: 'Estufa',
    BuildingKind.gambrel: 'Casa colonial',
    BuildingKind.ranch: 'Casa de rancho',
    BuildingKind.faluCabin: 'Chalé vermelho',
  };

  static const _homes = {
    BuildingKind.countryHouse,
    BuildingKind.farmhouse,
    BuildingKind.gambrel,
    BuildingKind.ranch,
    BuildingKind.faluCabin,
  };

  Building _buildingAt(ToolHost host, Point<int> tile) {
    final k = host.farmBuilding!;
    final spec = BuildingKindSpec.all[k]!;
    final (w, d) = spec.footprints.first;
    return host.draft.copyWith(
        kind: k,
        width: w,
        depth: d,
        floors: spec.minFloors,
        roof: spec.roofs.first,
        chimney: _homes.contains(k),
        name: _names[k] ?? 'Sítio',
        x: tile.x - w ~/ 2,
        y: tile.y - d ~/ 2);
  }

  @override
  bool onDragStart(ToolHost host, Offset scene, Point<int> tile) =>
      host.farmBuilding == null && host.farmProp != null && _props.onDragStart(host, scene, tile);

  @override
  void onDragUpdate(ToolHost host, Point<int> tile) {
    if (host.farmBuilding == null && host.farmProp != null) _props.onDragUpdate(host, tile);
  }

  @override
  void onTap(ToolHost host, Offset scene, Point<int> tile) {
    if (host.farmBuilding != null) {
      final b = _buildingAt(host, tile).copyWith(id: host.city.newId());
      if (host.rules.canPlaceBuilding(b)) host.addItem(b);
      return;
    }
    if (host.farmProp != null) return _props.onTap(host, scene, tile);
    final (fit, ok) = _fitAt(host, tile);
    if (!ok) return;
    final f = fit.copyWith(id: host.city.newId());
    // abre o terreno: o mato sai e os bichos se afastam (tudo num só passo do desfazer)
    host.addItem(f);
    _moveWalkersOut(host, f);
    for (final p in host.city.props.where((p) => f.occupies(p.x, p.y)).toList()) {
      host.city.remove(p);
    }
    host.changed();
  }

  @override
  PlacementPreview? previewAt(ToolHost host, Point<int> tile) {
    if (host.farmBuilding != null) {
      final b = _buildingAt(host, tile);
      return ItemPreview(b, isValid: host.rules.canPlaceBuilding(b));
    }
    if (host.farmProp != null) return _props.previewAt(host, tile);
    final (f, ok) = _fitAt(host, tile);
    return ItemPreview(f, isValid: ok);
  }
}

class _FarmPropTool extends PropTool {
  _FarmPropTool() : super(ToolId.farm);

  @override
  PropType typeOf(ToolHost host) => host.farmProp!;
}

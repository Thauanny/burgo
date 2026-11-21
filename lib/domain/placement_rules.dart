import 'city.dart';
import 'city_types.dart';
import 'map_item.dart';

/// Regras de onde itens podem ficar: dentro do mapa, fora de ruas, água e muros, sem sobreposição.
class PlacementRules {
  const PlacementRules(this.city);
  final City city;

  static const _waterOnly = {PropType.boat};
  static const _waterOk = {PropType.boat, PropType.dock};

  /// Portões de cerca e de sebe podem cruzar uma rua (ou estrada de terra).
  static const _roadOk = {PropType.fenceGate, PropType.hedgeGate};

  /// Mato que sai do lugar quando se abre uma plantação: árvores, arbustos, flores e cactos.
  static bool isClearablePlant(PropType t) => const {
        PropType.tree,
        PropType.pine,
        PropType.sakura,
        PropType.autumnTree,
        PropType.frostTree,
        PropType.bush,
        PropType.giantFlower,
        PropType.cactus,
      }.contains(t);

  /// Bichos e pessoas que andam: não seguram o terreno (saem do caminho ao plantar).
  static bool isWalker(PropType t) =>
      const {PropType.cow, PropType.sheep, PropType.chicken, PropType.dog, PropType.horse}.contains(t) ||
      (Figures.isFigure(t) && t != PropType.mDragon && t != PropType.mCube);

  /// Há algo no tile além de mato e de quem anda (a plantação limpa um e afasta o outro)?
  bool isOccupiedButPlants(int x, int y) {
    if (city.buildings.any((b) => b.occupies(x, y)) || city.farms.any((f) => f.occupies(x, y))) return true;
    return city.props.any((p) => p.x == x && p.y == y && !isClearablePlant(p.type) && !isWalker(p.type));
  }

  /// Há construção, fazenda ou objeto no tile? [ignoreId] desconsidera o próprio item (ao movê-lo).
  bool isOccupied(int x, int y, {int? ignoreId}) {
    for (final b in city.buildings) {
      if (b.id != ignoreId && b.occupies(x, y)) return true;
    }
    for (final f in city.farms) {
      if (f.id != ignoreId && f.occupies(x, y)) return true;
    }
    for (final p in city.props) {
      if (p.id != ignoreId && p.x == x && p.y == y) return true;
    }
    return false;
  }

  bool _blockedGround(int x, int y) =>
      !city.inBounds(x, y) ||
      city.road.at(x, y) ||
      city.water.at(x, y) ||
      city.walls.at(x, y);

  bool canPlaceBuilding(Building b, {int? ignoreId}) {
    for (var i = b.x; i < b.x + b.width; i++) {
      for (var j = b.y; j < b.y + b.depth; j++) {
        if (_blockedGround(i, j) || isOccupied(i, j, ignoreId: ignoreId)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Cabe a plantação? Com [clearPlants], árvores e arbustos no terreno não impedem (são
  /// tirados ao plantar); casas, ruas, água, muros, outras plantações e objetos impedem.
  bool canPlaceFarm(Farm f, {int? ignoreId, bool clearPlants = false}) {
    for (var i = f.x; i < f.x + f.width; i++) {
      for (var j = f.y; j < f.y + f.depth; j++) {
        if (_blockedGround(i, j) ||
            (clearPlants ? isOccupiedButPlants(i, j) : isOccupied(i, j, ignoreId: ignoreId))) {
          return false;
        }
      }
    }
    return true;
  }

  bool canPlaceProp(int x, int y, PropType type, {int? ignoreId}) {
    if (!city.inBounds(x, y) ||
        city.walls.at(x, y) ||
        isOccupied(x, y, ignoreId: ignoreId)) {
      return false;
    }
    final onWater = city.water.at(x, y);
    if (onWater) return _waterOk.contains(type);
    if (_waterOnly.contains(type)) return false;
    return !city.road.at(x, y) || _roadOk.contains(type);
  }

  bool canPlace(MapItem item, {int? ignoreId}) => switch (item) {
        final Building b => canPlaceBuilding(b, ignoreId: ignoreId),
        final Farm f => canPlaceFarm(f, ignoreId: ignoreId),
        final Prop p => canPlaceProp(p.x, p.y, p.type, ignoreId: ignoreId),
      };
}

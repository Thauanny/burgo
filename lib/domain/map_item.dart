import 'dart:ui';
import 'city_types.dart';

/// Item posicionável no mapa. `sealed` permite `switch` exaustivo.
sealed class MapItem {
  const MapItem({required this.id, required this.x, required this.y});
  final int id;
  final int x, y;

  MapItem movedTo(int x, int y);
}

/// Casa ou prédio ocupando `width × depth` tiles a partir de ([x], [y]).
final class Building extends MapItem {
  const Building({
    required super.id,
    required super.x,
    required super.y,
    this.width = 2,
    this.depth = 2,
    this.floors = 1,
    this.roof = RoofType.gable,
    this.wall = const Color(0xFFF4D9B5),
    this.roofColor = const Color(0xFFC96B5A),
    this.chimney = false,
    this.name = 'Casa',
    this.kind = BuildingKind.house,
  });

  final BuildingKind kind;
  final int width, depth, floors;
  final RoofType roof;
  final Color wall, roofColor;
  final bool chimney;
  final String name;

  bool occupies(int tx, int ty) =>
      tx >= x && tx < x + width && ty >= y && ty < y + depth;

  Building copyWith({
    int? id,
    int? x,
    int? y,
    int? width,
    int? depth,
    int? floors,
    RoofType? roof,
    Color? wall,
    Color? roofColor,
    bool? chimney,
    String? name,
    BuildingKind? kind,
  }) =>
      Building(
        id: id ?? this.id,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        depth: depth ?? this.depth,
        floors: floors ?? this.floors,
        roof: roof ?? this.roof,
        wall: wall ?? this.wall,
        roofColor: roofColor ?? this.roofColor,
        chimney: chimney ?? this.chimney,
        name: name ?? this.name,
        kind: kind ?? this.kind,
      );

  @override
  Building movedTo(int x, int y) => copyWith(x: x, y: y);
}

/// Objeto de 1 tile (árvore, poço, poste...).
final class Prop extends MapItem {
  const Prop(
      {required super.id,
      required super.x,
      required super.y,
      required this.type,
      this.race});
  final PropType type;

  /// Raça de uma pessoa (classe ou povo); o boneco muda de corpo, rosto e traços com ela.
  /// Sem raça, o desenho sorteia uma entre as do cenário.
  final PropType? race;

  @override
  Prop movedTo(int x, int y) => Prop(id: id, x: x, y: y, type: type, race: race);

  Prop copyWith({PropType? type, PropType? race, bool clearRace = false}) =>
      Prop(id: id, x: x, y: y, type: type ?? this.type, race: clearRace ? null : race ?? this.race);
}

/// Plantação ou pasto ocupando `width × depth` tiles, com cerca.
final class Farm extends MapItem {
  const Farm({
    required super.id,
    required super.x,
    required super.y,
    this.width = 4,
    this.depth = 4,
    this.crop = CropType.wheat,
  });

  final int width, depth;
  final CropType crop;

  bool occupies(int tx, int ty) =>
      tx >= x && tx < x + width && ty >= y && ty < y + depth;

  Farm copyWith(
          {int? id, int? x, int? y, int? width, int? depth, CropType? crop}) =>
      Farm(
        id: id ?? this.id,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        depth: depth ?? this.depth,
        crop: crop ?? this.crop,
      );

  @override
  Farm movedTo(int x, int y) => copyWith(x: x, y: y);
}

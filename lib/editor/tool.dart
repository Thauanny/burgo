import 'dart:math';
import 'dart:ui';
import '../domain/city.dart';
import '../domain/city_types.dart';
import '../domain/map_item.dart';
import '../domain/placement_preview.dart';
import '../domain/placement_rules.dart';

enum ToolId {
  pan,
  select,
  road,
  zone,
  zoneSource,
  water,
  wall,
  build,
  farm,
  prop,
  character,
  marker,
  ruler,
  erase
}

/// O que uma ferramenta precisa do editor (interface mínima, ISP).
abstract interface class ToolHost {
  City get city;
  PlacementRules get rules;
  Building get draft;
  Farm get farmDraft;
  PropType get propType;

  /// Personagem escolhido na ferramenta Personagens (pessoas e monstros).
  PropType get characterType;

  /// Raça da pessoa a colocar (ignorada para monstros).
  PropType get characterRace;
  MapItem? get selected;
  MapItem? pickAt(Offset scene);
  void select(MapItem? item);
  void addItem(MapItem item);
  void updateItem(MapItem item);

  /// Move um item sem avisar o painel (a posição não aparece nele).
  void moveItem(MapItem item);
  void removeItem(MapItem item);

  /// O mapa mudou (terreno pintado, por exemplo), mas o painel não precisa refazer.
  void changed();

  /// Guarda o estado para desfazer, antes de uma alteração feita pela própria ferramenta.
  void beginEdit({String? key, Offset? shiftTiles});

  // ---- áreas especiais, marcadores e régua ----
  int get zoneDefaultRadius;

  /// Raio do tracejado das próximas áreas (acompanha o tamanho se não foi definido).
  int get zoneDefaultRing;
  void zoneTap(Point<int> tile);
  bool zoneDragStart(Point<int> tile);
  void zoneDragUpdate(Point<int> tile);
  void addMarker(Point<int> tile);
  void rulerClick(Point<int> tile);
}

/// Estratégia de interação do mapa. Nova ferramenta = nova subclasse.
abstract class Tool {
  const Tool(this.id);
  final ToolId id;

  void onTap(ToolHost host, Offset scene, Point<int> tile) {}

  /// Devolve `true` se a ferramenta assume o arrasto (senão o mapa é movido).
  bool onDragStart(ToolHost host, Offset scene, Point<int> tile) => false;

  void onDragUpdate(ToolHost host, Point<int> tile) {}

  PlacementPreview? previewAt(ToolHost host, Point<int> tile) => null;
}

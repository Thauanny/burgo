import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../domain/city.dart';
import '../domain/city_types.dart';
import '../domain/era.dart';
import '../domain/map_annotations.dart';
import '../domain/map_item.dart';
import '../domain/placement_preview.dart';
import '../domain/placement_rules.dart';
import '../dungeon/dungeon_editor.dart';
import '../dungeon/dungeon_generator.dart' show DungeonDensity;
import '../generation/city_generator.dart';
import '../geometry/iso.dart';
import '../persistence/city_codec.dart';
import '../project/floor_navigator.dart';
import '../project/project_editor.dart';
import '../render/scene_view.dart';
import '../systems/rpg_system.dart';
import '../systems/settlement_type.dart';
import '../systems/system_repository.dart';
import 'animation_clock.dart';
import 'history.dart';
import 'hit_tester.dart';
import 'map_edge.dart';
import 'tool.dart';
import 'tools/annotation_tools.dart';
import 'tools/build_tool.dart';
import 'tools/erase_tool.dart';
import 'tools/farm_tool.dart';
import 'tools/paint_tools.dart';
import 'tools/prop_tool.dart';
import 'tools/select_tool.dart';
import 'viewport.dart';

/// Estado do editor: cidade, sistema, ferramenta, seleção e modelo de construção.
/// Os widgets só chamam seus métodos e leem seu estado.
class EditorState extends ChangeNotifier
    implements ToolHost, SceneView, ProjectEditor, FloorNavigator {
  EditorState({
    required CityGenerator generator,
    required SystemRepository systems,
    Random? random,
    this.dungeonFactory,
  })  : _generator = generator,
        _systems = systems,
        _random = random ?? Random(),
        system = systems.fallback {
    settlement = system.art.settlements.first;
    mode = settlement.defaultMode;
    city = _generate(seed: _newSeed(), tiles: CitySize.town.tiles);
  }

  /// Cria o editor de uma masmorra (injetado: o editor da cidade não conhece o gerador concreto).
  final DungeonEditor Function(String systemId)? dungeonFactory;
  final CityGenerator _generator;
  final SystemRepository _systems;
  final Random _random;
  final Viewport viewport = Viewport();

  final Map<ToolId, Tool> _tools = {
    for (final t in <Tool>[
      PanTool(),
      SelectTool(),
      RoadTool(),
      ZoneTool(),
      ZoneSourceTool(),
      WaterTool(),
      WallTool(),
      BuildTool(),
      FarmTool(),
      PropTool(),
      CharacterTool(),
      MarkerTool(),
      RulerTool(),
      EraseTool()
    ])
      t.id: t,
  };

  @override
  late City city;
  @override
  RpgSystem system;
  @override
  late SettlementType settlement;
  SettlementMode mode = SettlementMode.cityWithFarms;
  bool withZone = true;

  /// Distância (em blocos) entre a cidade e as plantações ao gerar com fazendas.
  int farmGap = 4;
  @override
  bool showScaleBar = true;
  @override
  bool showZoneRadius = true;
  @override
  int? selectedZoneId;
  @override
  Point<int>? rulerStart;
  @override
  int zoneDefaultRadius = 5;
  int? _zoneRing;

  @override
  int get zoneDefaultRing => _zoneRing ?? zoneDefaultRadius;

  /// Visão do mapa: isométrica ou de cima.
  @override
  ViewMode viewMode = ViewMode.isometric;

  /// Giro da vista em passos de 90° (0 a 3).
  @override
  int rotation = 0;

  /// Liga/desliga as animações (vento, animais, efeitos da área especial).
  bool animationsEnabled = true;

  /// Mostra as setas nas laterais do mapa para aumentá-lo.
  bool showExpandArrows = true;

  static const int maxMapTiles = 160, expandStep = 4;

  /// Dá para aumentar o lado [edge]? Cada seta mexe só na dimensão do seu lado.
  bool canExpandEdge(MapEdge edge) =>
      edgeLength(edge) + expandStep <= maxMapTiles;

  /// Tamanho (em blocos) da dimensão que o lado [edge] controla.
  int edgeLength(MapEdge edge) => edge == MapEdge.xMin || edge == MapEdge.xMax
      ? city.tilesX
      : city.tilesY;
  ToolId toolId = ToolId.pan;
  @override
  PropType propType = PropType.tree;

  @override
  PropType characterType = PropType.fighter;
  @override
  PropType characterRace = PropType.raceHuman;
  @override
  Building draft =
      const Building(id: -1, x: 0, y: 0, floors: 2, name: 'Nova casa');
  @override
  Farm farmDraft = const Farm(id: -1, x: 0, y: 0, width: 4, depth: 4);
  @override
  MapItem? selected;
  String? hook;

  final AnimationClock clock = AnimationClock();

  @override
  ProjectKind get kind => ProjectKind.city;
  @override
  String get systemId => system.id;
  @override
  String get title => city.name;
  @override
  Listenable get changes => Listenable.merge([this, sceneTick]);

  @override
  Map<String, dynamic> toJson() => {
        'city': cityToJson(city),
        'withZone': withZone,
        'farmGap': farmGap,
        'scaleBar': showScaleBar,
        'zoneRadius': showZoneRadius,
        'view': viewMode.name,
        'rotation': rotation,
        'animations': animationsEnabled,
        'arrows': showExpandArrows,
        'floor': activeEntranceId,
        'dungeons': [
          for (final e in dungeons.entries)
            if (city.props.any(
                (p) => p.id == e.key && p.type == PropType.dungeonEntrance))
              {'entrance': e.key, 'data': e.value.toJson()},
        ],
      };

  @override
  void loadJson(Map<String, dynamic> json) {
    final loaded = cityFromJson(json['city'] as Map<String, dynamic>);
    city = loaded;
    system = _systems.byId(loaded.systemId);
    settlement = system.art.settlements.firstWhere(
        (s) => s.id == loaded.settlementId,
        orElse: () => system.art.settlements.first);
    mode = loaded.mode;
    withZone = json['withZone'] as bool? ?? true;
    farmGap = (json['farmGap'] as num?)?.toInt() ?? 2;
    showScaleBar = json['scaleBar'] as bool? ?? true;
    showZoneRadius = json['zoneRadius'] as bool? ?? true;
    selectedZoneId = null;
    rulerStart = null;
    viewMode = ViewMode.values.asNameMap()[json['view']] ?? ViewMode.isometric;
    rotation = ((json['rotation'] as num?)?.toInt() ?? 0) % 4;
    animationsEnabled = json['animations'] as bool? ?? true;
    showExpandArrows = json['arrows'] as bool? ?? true;
    if (!system.availableProps.contains(propType)) {
      propType = system.availableProps.first;
    }
    if (!system.hasZone &&
        (toolId == ToolId.zone || toolId == ToolId.zoneSource)) {
      toolId = ToolId.pan;
    }
    selected = null;
    hook = null;
    _history.clear();
    _loadDungeons(
        (json['dungeons'] as List?)?.cast<Map<String, dynamic>>() ?? const [],
        (json['floor'] as num?)?.toInt());
    revision++;
    viewport.requestFit();
    notifyListeners();
  }

  final History<City> _history =
      History(clone: (c) => c.resized(newX: c.tilesX, newY: c.tilesY));

  @override
  bool get canUndo => _history.canUndo;
  @override
  bool get canRedo => _history.canRedo;

  /// Guarda o estado atual para poder desfazer. Chamado antes de cada alteração.
  @override
  void beginEdit({String? key, Offset? shiftTiles}) =>
      _history.record(city, key: key, note: shiftTiles);

  @override
  void undo() {
    final r = _history.undo(city);
    if (r != null) _restore(r.$1, r.$2 as Offset?, forward: false);
  }

  @override
  void redo() {
    final r = _history.redo(city);
    if (r != null) _restore(r.$1, r.$2 as Offset?, forward: true);
  }

  void _restore(City snapshot, Offset? shiftTiles, {required bool forward}) {
    city = snapshot;
    system = _systems.byId(city.systemId);
    settlement = system.art.settlements.firstWhere(
        (s) => s.id == city.settlementId,
        orElse: () => system.art.settlements.first);
    mode = city.mode;
    selected = null;
    revision++;
    if (shiftTiles != null) {
      // desfazer/refazer um aumento de mapa desloca o conteúdo: compensa a câmera
      final shift = Iso.pt(shiftTiles.dx, shiftTiles.dy) * viewport.zoom;
      viewport.moveTo(
          forward ? viewport.pan - shift : viewport.pan + shift, viewport.zoom);
    }
    notifyListeners();
  }

  /// Avisa só o canvas (pintura de terreno, arrasto), sem reconstruir o painel.
  final ValueNotifier<int> sceneTick = ValueNotifier(0);

  @override
  void dispose() {
    for (final d in dungeons.values) {
      d.dispose();
    }
    sceneTick.dispose();
    clock.dispose();
    super.dispose();
  }

  @override
  double get time => clock.seconds;

  /// Muda quando a cidade é regenerada (a UI usa para reiniciar campos de texto).
  int revision = 0;

  Tool get tool => _tools[toolId]!;
  @override
  PlacementRules get rules => PlacementRules(city);
  List<RpgSystem> get availableSystems => _systems.all;

  /// Construção em edição no painel: a selecionada ou, na ferramenta Construir, o modelo.
  Building? get activeBuilding {
    final s = selected;
    if (s is Building) return s;
    return toolId == ToolId.build ? draft : null;
  }

  bool get isEditingDraft => selected is! Building;

  /// Fazenda em edição no painel: a selecionada ou, na ferramenta Fazenda, o modelo.
  Farm? get activeFarm {
    final s = selected;
    if (s is Farm) return s;
    return toolId == ToolId.farm ? farmDraft : null;
  }

  bool get isEditingFarmDraft => selected is! Farm;

  // ---------- SceneView ----------
  @override
  Rect get visibleScene => viewport.size.isEmpty
      ? const Rect.fromLTRB(-1e9, -1e9, 1e9, 1e9)
      : Rect.fromLTWH(
          -viewport.pan.dx / viewport.zoom,
          -viewport.pan.dy / viewport.zoom,
          viewport.size.width / viewport.zoom,
          viewport.size.height / viewport.zoom);

  @override
  Point<int>? get hoverTile => viewport.hover;

  @override
  Offset get pan => viewport.pan;
  @override
  double get zoom => viewport.zoom;
  @override
  PlacementPreview? get preview {
    final tile = viewport.hover;
    if (tile == null || !city.inBounds(tile.x, tile.y)) return null;
    // sobre algo que já existe, só realça (clicar seleciona para mover/editar)
    if (_pickFirstTools.contains(toolId) &&
        toolId != ToolId.select &&
        rules.isOccupied(tile.x, tile.y)) {
      return TilePreview(tile.x, tile.y, TilePreviewKind.hover);
    }
    return tool.previewAt(this, tile);
  }

  // ---------- geração ----------
  int _newSeed() => _random.nextInt(900000) + 100000;

  City _generate({required int seed, required int tiles}) =>
      _generator.generate(GenerationRequest(
        seed: seed,
        tiles: tiles,
        system: system,
        settlement: settlement,
        mode: mode,
        withZone: withZone,
        farmGap: farmGap,
      ));

  /// Tamanho de mapa que a pessoa pediu. Algumas cidades (Valkaria) abrem num mapa maior, mas
  /// ao trocar de tipo o mapa volta ao tamanho pedido.
  int? _wantedTiles;

  /// Gera outra cidade. Sem [seed], sorteia uma nova.
  void generate({int? seed, CitySize? size, int? tiles, String? historyKey}) {
    beginEdit(key: historyKey);
    final km = city.kmPerTile;
    _wantedTiles ??= city.size;
    final want = tiles ?? size?.tiles ?? _wantedTiles!;
    if (tiles != null || size != null) _wantedTiles = want;
    city = _generate(seed: seed ?? _newSeed(), tiles: want);
    city.kmPerTile = km;
    selectedZoneId = null;
    rulerStart = null;
    selected = null;
    hook = null;
    revision++;
    viewport.requestFit();
    notifyListeners();
  }

  @override
  TerrainPalette get palette =>
      settlement.terrain ??
      TerrainPalette(
          grassA: system.grassA,
          grassB: system.grassB,
          road: system.roadColor,
          plaza: system.plazaColor,
          soil: system.soil);

  List<SettlementType> get availableSettlements => system.art.settlements;

  void setSettlement(SettlementType type) {
    settlement = type;
    mode = type.defaultMode;
    // a área especial volta ao trocar de tipo (a não ser que o lugar não tenha)
    withZone = !type.noZone && (type.wildZone ?? true);
    _syncDraftToEra();
    generate(seed: city.seed);
  }

  void setMode(SettlementMode value) {
    mode = value;
    generate(seed: city.seed);
  }

  void setSystem(RpgSystem s) {
    system = s;
    settlement = s.art.settlements.first;
    mode = settlement.defaultMode;
    if (!s.hasZone && (toolId == ToolId.zone || toolId == ToolId.zoneSource)) {
      toolId = ToolId.pan;
    }
    if (!s.availableObjects.contains(propType)) propType = s.availableObjects.first;
    if (!s.availableCharacters.contains(characterType) && s.availableCharacters.isNotEmpty) {
      characterType = s.availableCharacters.first;
    }
    if (!s.availableRaces.contains(characterRace) && s.availableRaces.isNotEmpty) {
      characterRace = s.availableRaces.first;
    }
    _syncDraftToEra();
    generate(seed: city.seed);
  }

  /// Define sistema, tipo e composição de uma vez e gera uma só cidade (usado ao criar abas).
  void configure(
      {required String systemId, SettlementMode? mode, String? settlementId}) {
    system = _systems.byId(systemId);
    settlement = settlementId == null
        ? system.art.settlements.first
        : system.art.settlements.firstWhere((s) => s.id == settlementId,
            orElse: () => system.art.settlements.first);
    this.mode = mode ?? settlement.defaultMode;
    if (!system.hasZone &&
        (toolId == ToolId.zone || toolId == ToolId.zoneSource)) {
      toolId = ToolId.pan;
    }
    if (!system.availableProps.contains(propType)) {
      propType = system.availableProps.first;
    }
    _syncDraftToEra();
    generate(seed: _newSeed());
    _history.clear();
  }

  void setSystemById(String id) => setSystem(_systems.byId(id));

  void setWithZone(bool value) {
    withZone = value;
    generate(seed: city.seed);
  }

  void setAnimations(bool value) {
    animationsEnabled = value;
    notifyListeners();
  }

  /// Época do lugar atual (do tipo de assentamento, senão do cenário).
  Era get era => settlement.era ?? system.art.era;

  /// A construção-modelo da ferramenta Construir começa com a casa comum da época.
  void _syncDraftToEra() {
    if (!EraRules.allowsBuilding(draft.kind, era)) {
      draft = draft.copyWith(kind: era.homeKind);
    }
  }

  /// Gira a vista [quarters] passos de 90° (positivo = horário), mantendo parado o ponto do
  /// mapa que está no centro da tela.
  void rotate(int quarters) {
    final area = viewport.size;
    activateProjection();
    final center = area.center(Offset.zero);
    final focus = Iso.unproject(viewport.toScene(center));
    rotation = ((rotation + quarters) % 4 + 4) % 4;
    activateProjection();
    if (!area.isEmpty) {
      final scene = Iso.pt(focus.dx, focus.dy);
      viewport.moveTo(center - scene * viewport.zoom, viewport.zoom);
    }
    notifyListeners();
  }

  /// Troca a visão; aplica a projeção e reenquadra o mapa.
  @override
  void setViewMode(ViewMode mode) {
    viewMode = mode;
    activateProjection();
    viewport.requestFit();
    notifyListeners();
  }

  /// Aplica a projeção deste editor (ao ficar ativo numa aba).
  @override
  void activateProjection() =>
      Iso.configure(viewMode, rotation, city.tilesX, city.tilesY);

  void setShowExpandArrows(bool value) {
    showExpandArrows = value;
    notifyListeners();
  }

  /// Aumenta o mapa em [expandStep] tiles pelo lado escolhido, mantendo tudo no lugar na tela.
  void expandMap(MapEdge edge) {
    if (!canExpandEdge(edge)) return;
    if (city.islandRadius > 0) {
      // ilha flutuante (Vectora): a ilha inteira cresce junto, mantendo o formato redondo
      generate(
          seed: city.seed,
          tiles: max(city.tilesX, city.tilesY) + expandStep * 2);
      return;
    }
    final alongX = edge == MapEdge.xMin || edge == MapEdge.xMax;
    final dx = edge == MapEdge.xMin ? expandStep : 0;
    final dy = edge == MapEdge.yMin ? expandStep : 0;
    beginEdit(shiftTiles: Offset(dx.toDouble(), dy.toDouble()));
    city = city.resized(
        newX: city.tilesX + (alongX ? expandStep : 0),
        newY: city.tilesY + (alongX ? 0 : expandStep),
        dx: dx,
        dy: dy);
    selected = null;
    // o conteúdo se deslocou (dx,dy) tiles: compensa a câmera para nada "pular"
    final shift = Iso.pt(dx.toDouble(), dy.toDouble()) * viewport.zoom;
    viewport.moveTo(viewport.pan - shift, viewport.zoom);
    notifyListeners();
  }

  void renameCity(String name) {
    city.name = name;
    notifyListeners(); // atualiza o nome da aba
  }

  void newHook() {
    hook = system.hooks[_random.nextInt(system.hooks.length)];
    notifyListeners();
  }

  // ---------- ferramentas ----------
  void setTool(ToolId id) {
    toolId = id;
    rulerStart = null;
    selected = null;
    notifyListeners();
  }

  void setCharacterType(PropType type) {
    characterType = type;
    notifyListeners();
  }

  void setCharacterRace(PropType race) {
    characterRace = race;
    notifyListeners();
  }

  /// Troca a raça da pessoa selecionada.
  void setSelectedRace(PropType race) {
    final p = selected;
    if (p is! Prop || !Figures.isPerson(p.type)) return;
    updateItem(p.copyWith(race: race));
  }

  void setPropType(PropType type) {
    propType = type;
    notifyListeners();
  }

  /// Ferramentas de colocar: clicar em algo que já existe seleciona, em vez de colocar por cima.
  static const _pickFirstTools = {
    ToolId.select,
    ToolId.build,
    ToolId.farm,
    ToolId.prop,
    ToolId.character
  };
  Tool? _dragTool;

  void tapAt(Offset scene) {
    if (_pickFirstTools.contains(toolId) && toolId != ToolId.select) {
      final item = pickAt(scene);
      if (item != null) {
        select(item);
        return;
      }
      if (selected != null) {
        select(null); // o primeiro clique no vazio só tira a seleção
        return;
      }
    }
    tool.onTap(this, scene, Iso.tileAt(scene));
  }

  bool dragStartAt(Offset scene) {
    if (toolId == ToolId.pan) return false;
    final tile = Iso.tileAt(scene);
    if (_pickFirstTools.contains(toolId) &&
        toolId != ToolId.select &&
        pickAt(scene) != null) {
      // arrastar algo existente move, com qualquer ferramenta de colocar
      final select = _tools[ToolId.select]!;
      if (select.onDragStart(this, scene, tile)) {
        _dragTool = select;
        return true;
      }
    }
    _dragTool = null;
    return tool.onDragStart(this, scene, tile);
  }

  void dragUpdateAt(Point<int> tile) =>
      (_dragTool ?? tool).onDragUpdate(this, tile);

  /// Troca o tipo do objeto selecionado (árvore → poço, por exemplo).
  void changeSelectedPropType(PropType type) {
    final p = selected;
    if (p is! Prop || p.type == type) return;
    final changed = Prop(id: p.id, x: p.x, y: p.y, type: type, race: Figures.isPerson(type) ? p.race : null);
    if (rules.canPlaceProp(p.x, p.y, type, ignoreId: p.id)) updateItem(changed);
  }

  // ---------- ToolHost ----------
  @override
  MapItem? pickAt(Offset scene) => pickItemAt(city, scene);

  @override
  void select(MapItem? item) {
    selected = item;
    notifyListeners();
  }

  @override
  void addItem(MapItem item) {
    beginEdit();
    city.add(item);
    if (creatingFloor &&
        item is Prop &&
        item.type == PropType.dungeonEntrance) {
      draftEntranceId = item.id;
    }
    notifyListeners();
  }

  @override
  void updateItem(MapItem item) {
    beginEdit(key: 'upd-${item.id}');
    city.replace(item);
    if (selected?.id == item.id) selected = item;
    notifyListeners();
  }

  @override
  void removeItem(MapItem item) {
    beginEdit();
    city.remove(item);
    if (selected?.id == item.id) selected = null;
    notifyListeners();
  }

  @override
  void changed() => sceneTick.value++;

  @override
  void moveItem(MapItem item) {
    city.replace(item);
    if (selected?.id == item.id) selected = item;
    sceneTick.value++;
  }

  void deleteSelected() {
    final item = selected;
    if (item != null) removeItem(item);
  }

  /// Copia a construção selecionada para o espaço livre mais próximo.
  void duplicateSelected() {
    final b = selected;
    if (b is! Building) return;
    const maxRadius = 14;
    for (var ring = 1; ring <= maxRadius; ring++) {
      for (var dx = -ring; dx <= ring; dx++) {
        for (var dy = -ring; dy <= ring; dy++) {
          if (max(dx.abs(), dy.abs()) != ring) continue;
          final copy = b.copyWith(id: city.newId(), x: b.x + dx, y: b.y + dy);
          if (rules.canPlaceBuilding(copy)) {
            beginEdit();
            city.add(copy);
            selected = copy;
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  // ---------- edição da construção ativa ----------
  void editBuilding(Building Function(Building) change) {
    final b = activeBuilding;
    if (b == null) return;
    final edited = change(b);
    if (isEditingDraft) {
      draft = edited;
      notifyListeners();
    } else if (rules.canPlaceBuilding(edited, ignoreId: b.id)) {
      updateItem(edited);
    }
  }

  void editFarm(Farm Function(Farm) change) {
    final f = activeFarm;
    if (f == null) return;
    final edited = change(f);
    if (isEditingFarmDraft) {
      farmDraft = edited;
      notifyListeners();
    } else if (rules.canPlaceFarm(edited, ignoreId: f.id)) {
      updateItem(edited);
    }
  }

  // ---------- escala, distância e anotações ----------
  /// Quantos quilômetros vale cada bloco.
  void setKmPerTile(double km) {
    if (km <= 0 || km.isNaN || km.isInfinite) return;
    beginEdit(key: 'km');
    city.kmPerTile = km.clamp(.001, 1000).toDouble();
    notifyListeners();
  }

  /// Menor tamanho de mapa que comporta uma faixa de [gap] blocos entre a cidade e o campo.
  static int mapSizeForGap(int gap) => ((gap + 28) / 4).ceil() * 4;

  /// Afasta (ou aproxima) as fazendas da cidade. Se o mapa for pequeno demais, ele cresce sozinho.
  void setFarmGap(int tiles) {
    farmGap = tiles;
    final needed = min(maxMapTiles, mapSizeForGap(tiles));
    generate(seed: city.seed, tiles: max(city.size, needed), historyKey: 'gap');
  }

  void setShowScaleBar(bool v) {
    showScaleBar = v;
    notifyListeners();
  }

  void setShowZoneRadius(bool v) {
    showZoneRadius = v;
    notifyListeners();
  }

  /// Área que o controle de raio redimensiona: a selecionada ou, se só existe uma, ela mesma.
  ZoneSource? get radiusTarget {
    final selected = selectedZone;
    if (selected != null) return selected;
    final all = city.zoneSources;
    return all.length == 1 ? all.first : null;
  }

  /// Muda o raio no controle do painel: redimensiona a área-alvo (se houver) e vale para as próximas.
  void setZoneDefaultRadius(int r) {
    zoneDefaultRadius = r.clamp(1, 30);
    final target = radiusTarget;
    if (target == null) {
      notifyListeners();
      return;
    }
    selectedZoneId = target.id;
    setZoneRadius(zoneDefaultRadius);
  }

  /// Muda só o raio do tracejado (não mexe na área especial): da área-alvo e das próximas.
  void setZoneDefaultRing(int r) {
    _zoneRing = r.clamp(1, 40);
    final target = radiusTarget;
    if (target == null) {
      notifyListeners();
      return;
    }
    selectedZoneId = target.id;
    beginEdit(key: 'zring-${target.id}');
    city.replaceZoneSource(target.copyWith(ring: _zoneRing));
    notifyListeners();
  }

  /// Volta o tracejado a acompanhar o tamanho da área.
  void resetZoneRing() {
    _zoneRing = null;
    final target = radiusTarget;
    if (target != null) {
      beginEdit();
      city.replaceZoneSource(target.copyWith(followArea: true));
    }
    notifyListeners();
  }

  ZoneSource? get selectedZone {
    for (final z in city.zoneSources) {
      if (z.id == selectedZoneId) return z;
    }
    return null;
  }

  ZoneSource? _zoneNear(Point<int> tile) {
    ZoneSource? best;
    var bestDist = 2.2; // quase em cima do centro
    for (final z in city.zoneSources) {
      final d = sqrt(pow(z.x - tile.x, 2) + pow(z.y - tile.y, 2));
      if (d < bestDist) {
        best = z;
        bestDist = d;
      }
    }
    return best;
  }

  @override
  void zoneTap(Point<int> tile) {
    final near = _zoneNear(tile);
    if (near != null) {
      selectedZoneId = near.id;
      notifyListeners();
      return;
    }
    if (!city.inBounds(tile.x, tile.y)) return;
    beginEdit();
    final z = ZoneSource(
        id: city.newId(),
        x: tile.x,
        y: tile.y,
        radius: zoneDefaultRadius,
        ring: _zoneRing);
    city.addZoneSource(z, adapt: true);
    selectedZoneId = z.id;
    notifyListeners();
  }

  @override
  bool zoneDragStart(Point<int> tile) {
    final near = _zoneNear(tile);
    if (near == null) return false;
    selectedZoneId = near.id;
    beginEdit();
    notifyListeners();
    return true;
  }

  @override
  void zoneDragUpdate(Point<int> tile) {
    final z = selectedZone;
    if (z == null ||
        !city.inBounds(tile.x, tile.y) ||
        (z.x == tile.x && z.y == tile.y)) {
      return;
    }
    city.replaceZoneSource(z.copyWith(x: tile.x, y: tile.y), adapt: true);
    sceneTick.value++;
  }

  /// Muda o raio de ação da área selecionada (em blocos).
  void setZoneRadius(int radius) {
    final z = selectedZone;
    if (z == null) return;
    beginEdit(key: 'zr-${z.id}');
    city.replaceZoneSource(z.copyWith(radius: radius.clamp(1, 30)),
        adapt: true);
    notifyListeners();
  }

  void removeZoneSource(int id) {
    beginEdit();
    city.removeZoneSource(id, adapt: true);
    if (selectedZoneId == id) selectedZoneId = null;
    notifyListeners();
  }

  void selectZone(int? id) {
    selectedZoneId = id;
    notifyListeners();
  }

  @override
  void addMarker(Point<int> tile) {
    if (!city.inBounds(tile.x, tile.y)) return;
    beginEdit();
    final n = city.labels.length + 1;
    city.addLabel(
        MapLabel(id: city.newId(), x: tile.x, y: tile.y, text: 'Local $n'));
    notifyListeners();
  }

  void updateLabel(MapLabel l) {
    beginEdit(key: 'lb-${l.id}');
    city.replaceLabel(l);
    notifyListeners();
  }

  void removeLabel(int id) {
    beginEdit();
    city.removeLabel(id);
    notifyListeners();
  }

  @override
  void rulerClick(Point<int> tile) {
    if (!city.inBounds(tile.x, tile.y)) return;
    final start = rulerStart;
    if (start == null) {
      rulerStart = tile;
    } else {
      beginEdit();
      city.addRuler(MapRuler(
          id: city.newId(), x1: start.x, y1: start.y, x2: tile.x, y2: tile.y));
      rulerStart = null;
    }
    notifyListeners();
  }

  void removeRuler(int id) {
    beginEdit();
    city.removeRuler(id);
    notifyListeners();
  }

  // ---------- pisos: superfície (cima) e masmorras (baixo) ----------
  /// Masmorras ligadas às entradas do piso de cima (chave: id do objeto de entrada).
  final Map<int, DungeonEditor> dungeons = {};

  @override
  List<FloorEntry> get lowerFloors => [
        for (final e in dungeons.entries)
          FloorEntry(entranceId: e.key, title: e.value.title)
      ];

  /// Entrada cuja masmorra está sendo vista; `null` = piso de cima.
  @override
  int? activeEntranceId;

  DungeonEditor? get activeDungeon =>
      activeEntranceId == null ? null : dungeons[activeEntranceId];

  Prop? get selectedEntrance {
    final s = selected;
    return s is Prop && s.type == PropType.dungeonEntrance ? s : null;
  }

  bool hasDungeonAt(int entranceId) => dungeons.containsKey(entranceId);

  Prop? _entrance(int id) {
    for (final p in city.props) {
      if (p.id == id && p.type == PropType.dungeonEntrance) return p;
    }
    return null;
  }

  /// Texto "Entrada em (x, y) · a 3 km do centro" para o painel da masmorra.
  String _entranceInfo(Prop p) {
    final km = city.distanceFromHubKm(p.x + .5, p.y + .5);
    final near = city.labels
        .where((l) => (l.x - p.x).abs() <= 1 && (l.y - p.y).abs() <= 1);
    final where = near.isEmpty
        ? 'entrada em (${p.x}, ${p.y})'
        : 'entrada: ${near.first.text}';
    return '$where · a ${km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1).replaceAll('.', ',')} km'} do centro da cidade';
  }

  DungeonEditor _attachDungeon(int entranceId, DungeonEditor d) {
    d.onAscend = ascend;
    d.navigator = this;
    d.viewMode = viewMode;
    // qualquer mudança na masmorra também conta para o salvamento automático
    d.changes.addListener(() => sceneTick.value++);
    dungeons[entranceId] = d;
    return d;
  }

  /// Cria a masmorra da entrada e desce para ela.
  void createDungeonAndDescend(int entranceId,
      {int? size, DungeonDensity? density}) {
    final entrance = _entrance(entranceId);
    final factory = dungeonFactory;
    if (entrance == null || factory == null) return;
    if (!dungeons.containsKey(entranceId)) {
      final d = _attachDungeon(entranceId, factory(system.id));
      d.renameDungeon('Masmorra · entrada (${entrance.x}, ${entrance.y})');
      if (size != null || density != null) {
        d.configure(size: size, density: density);
      }
    }
    descend(entranceId);
  }

  @override
  void descend(int entranceId) {
    final entrance = _entrance(entranceId), d = dungeons[entranceId];
    if (entrance == null || d == null) return;
    d.entranceInfo = _entranceInfo(entrance);
    d.viewMode = viewMode;
    activeEntranceId = entranceId;
    d.activateProjection();
    d.viewport.requestFit();
    notifyListeners();
  }

  /// Sobe para o piso de cima e seleciona a entrada de onde veio.
  @override
  void ascend() {
    final id = activeEntranceId;
    activeEntranceId = null;
    activateProjection();
    final e = id == null ? null : _entrance(id);
    if (e != null) selected = e;
    notifyListeners();
  }

  void removeDungeon(int entranceId) {
    dungeons.remove(entranceId)?.dispose();
    if (activeEntranceId == entranceId) activeEntranceId = null;
    sceneTick.value++;
    notifyListeners();
  }

  void _loadDungeons(List<Map<String, dynamic>> saved, int? floor) {
    for (final d in dungeons.values) {
      d.dispose();
    }
    dungeons.clear();
    activeEntranceId = null;
    final factory = dungeonFactory;
    if (factory == null) return;
    for (final item in saved) {
      final id = (item['entrance'] as num).toInt();
      final d = _attachDungeon(id, factory(system.id));
      d.loadJson(item['data'] as Map<String, dynamic>);
      d.viewMode = viewMode;
    }
    if (floor != null && dungeons.containsKey(floor)) {
      activeEntranceId = floor;
      final e = _entrance(floor);
      if (e != null) dungeons[floor]!.entranceInfo = _entranceInfo(e);
    }
  }

  // ---------- criar piso inferior (opções de geração) ----------
  /// Está com o formulário "criar piso inferior" aberto?
  bool creatingFloor = false;

  /// Entrada escolhida para a nova masmorra e opções de geração.
  int? draftEntranceId;
  int draftDungeonSize = 40;
  DungeonDensity draftDensity = DungeonDensity.medium;

  /// Entradas ainda sem masmorra.
  List<Prop> get freeEntrances => [
        for (final p in city.props)
          if (p.type == PropType.dungeonEntrance && !dungeons.containsKey(p.id))
            p
      ];

  void startFloorCreation() {
    creatingFloor = true;
    final free = freeEntrances;
    draftEntranceId = free.any((p) => p.id == draftEntranceId)
        ? draftEntranceId
        : (free.isEmpty ? null : free.first.id);
    notifyListeners();
  }

  void cancelFloorCreation() {
    creatingFloor = false;
    notifyListeners();
  }

  void setDraftEntrance(int? id) {
    draftEntranceId = id;
    notifyListeners();
  }

  void setDraftSize(int tiles) {
    draftDungeonSize = tiles;
    notifyListeners();
  }

  void setDraftDensity(DungeonDensity d) {
    draftDensity = d;
    notifyListeners();
  }

  /// Passa para a ferramenta Objetos com "Entrada de masmorra" já escolhida, para posicionar no mapa.
  void pickEntranceOnMap() {
    setTool(ToolId.prop);
    propType = PropType.dungeonEntrance;
    notifyListeners();
  }

  /// Gera a masmorra da entrada escolhida, com as opções do formulário, e desce.
  void generateFloor() {
    final id = draftEntranceId;
    if (id == null || _entrance(id) == null) return;
    creatingFloor = false;
    createDungeonAndDescend(id, size: draftDungeonSize, density: draftDensity);
  }
}

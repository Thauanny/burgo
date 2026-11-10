import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../domain/city_types.dart';
import '../domain/dungeon.dart';
import '../editor/animation_clock.dart';
import '../editor/history.dart';
import '../editor/viewport.dart';
import '../geometry/iso.dart';
import '../persistence/dungeon_codec.dart';
import '../project/floor_navigator.dart';
import '../project/project_editor.dart';
import '../render/dungeon/dungeon_scene.dart';
import '../systems/dungeon_profile.dart';
import '../systems/dungeon_profiles.dart';
import 'dungeon_generator.dart';

enum DungeonTool { pan, carve, wall, door, prop, erase }

/// Estado do editor de masmorras: mapa, ferramenta, câmera e histórico.
class DungeonEditor extends ChangeNotifier
    implements ProjectEditor, DungeonScene {
  DungeonEditor(
      {required DungeonGenerator generator,
      this.systems = const [],
      Random? random,
      this.systemId = 'generico',
      this.size = 40})
      : _generator = generator,
        _random = random ?? Random() {
    dungeon = _make(_newSeed());
  }

  /// Sistemas disponíveis (id, nome) para escolher o estilo da masmorra.
  final List<(String, String)> systems;
  final DungeonGenerator _generator;
  final Random _random;
  final Viewport viewport = Viewport();

  /// Ligação com o piso de cima: volta para a superfície e descreve onde fica a entrada.
  VoidCallback? onAscend;

  /// Navegação entre pisos (para trocar de piso pelo painel da masmorra).
  FloorNavigator? navigator;
  String? entranceInfo;
  final AnimationClock clock = AnimationClock();
  final ValueNotifier<int> sceneTick = ValueNotifier(0);
  final History<Dungeon> _history = History(clone: (d) => d.copy());

  @override
  late Dungeon dungeon;
  @override
  String systemId;
  int size;
  DungeonDensity density = DungeonDensity.medium;
  DungeonTool tool = DungeonTool.pan;
  DungeonPropType propType = DungeonPropType.chest;

  /// Monstro a colocar quando [propType] é [DungeonPropType.monster].
  PropType monsterType = PropType.mGoblin;
  @override
  ViewMode viewMode = ViewMode.isometric;
  @override
  int rotation = 0;
  bool animationsEnabled = true;
  int revision = 0;
  bool _paintOn = true;

  @override
  ProjectKind get kind => ProjectKind.dungeon;
  @override
  String get title => dungeon.name;
  @override
  Listenable get changes => Listenable.merge([this, sceneTick]);
  @override
  DungeonProfile get profile => DungeonProfiles.of(systemId);

  static const List<int> sizes = [24, 32, 40, 48, 64];

  // ---------- DungeonScene ----------
  @override
  Offset get pan => viewport.pan;
  @override
  double get zoom => viewport.zoom;
  @override
  double get time => clock.seconds;
  @override
  Rect get visibleScene => viewport.size.isEmpty
      ? const Rect.fromLTRB(-1e9, -1e9, 1e9, 1e9)
      : Rect.fromLTWH(
          -viewport.pan.dx / viewport.zoom,
          -viewport.pan.dy / viewport.zoom,
          viewport.size.width / viewport.zoom,
          viewport.size.height / viewport.zoom);
  @override
  (int, int)? get hoverCell {
    final h = viewport.hover;
    return h == null ? null : (h.x, h.y);
  }

  @override
  DungeonPropType? get previewProp =>
      tool == DungeonTool.prop ? propType : null;
  @override
  Object? get previewMonster => monsterType;

  /// Monstros deste cenário (comuns, chefes e bichos), para a ferramenta.
  List<PropType> get availableMonsters => {
        ...profile.monsters,
        ...profile.bosses,
        ...profile.vermin,
      }.toList();

  // ---------- geração ----------
  int _newSeed() => _random.nextInt(900000) + 100000;

  Dungeon _make(int seed) => _generator.generate(DungeonRequest(
      seed: seed,
      size: size,
      systemId: systemId,
      profile: profile,
      density: density));

  void generate({int? seed}) {
    _history.record(dungeon);
    dungeon = _make(seed ?? _newSeed());
    revision++;
    viewport.requestFit();
    notifyListeners();
  }

  /// Define tamanho e quantidade de salas e gera uma masmorra nova, sem entrar no histórico (masmorra recém-criada).
  void configure({int? size, DungeonDensity? density, int? seed}) {
    if (size != null) this.size = size;
    if (density != null) this.density = density;
    dungeon = _make(seed ?? dungeon.seed);
    _history.clear();
    revision++;
    viewport.requestFit();
    notifyListeners();
  }

  void setSystem(String id) {
    systemId = id;
    final monsters = availableMonsters;
    if (!monsters.contains(monsterType) && monsters.isNotEmpty) monsterType = monsters.first;
    generate(seed: dungeon.seed);
  }

  void setMonsterType(PropType t) {
    monsterType = t;
    propType = DungeonPropType.monster;
    notifyListeners();
  }

  /// Gira a vista em passos de 90° ([dir] = ±1).
  void rotate(int dir) {
    rotation = (rotation + dir + 4) % 4;
    activateProjection();
    viewport.requestFit();
    notifyListeners();
  }

  void setSize(int tiles) {
    size = tiles;
    generate(seed: dungeon.seed);
  }

  void setDensity(DungeonDensity value) {
    density = value;
    generate(seed: dungeon.seed);
  }

  void renameDungeon(String name) {
    dungeon.name = name;
    notifyListeners();
  }

  void setTool(DungeonTool t) {
    tool = t;
    notifyListeners();
  }

  void setPropType(DungeonPropType t) {
    propType = t;
    notifyListeners();
  }

  void setAnimations(bool value) {
    animationsEnabled = value;
    notifyListeners();
  }

  // ---------- edição ----------
  /// Começa um gesto de pintura/colocação: guarda o estado e decide se o gesto pinta ou apaga.
  void beginGesture(Point<int> cell) {
    if (tool == DungeonTool.pan) return;
    _history.record(dungeon);
    _paintOn = switch (tool) {
      DungeonTool.carve => !dungeon.isOpen(cell.x, cell.y),
      DungeonTool.wall => dungeon.isOpen(cell.x, cell.y),
      _ => true,
    };
    applyAt(cell);
  }

  void applyAt(Point<int> cell) {
    final (x, y) = (cell.x, cell.y);
    if (!dungeon.inBounds(x, y)) return;
    // a borda do mapa fica sempre de rocha
    final edge =
        x == 0 || y == 0 || x == dungeon.size - 1 || y == dungeon.size - 1;
    switch (tool) {
      case DungeonTool.pan:
        return;
      case DungeonTool.carve:
        if (!edge && _paintOn && dungeon.cellAt(x, y) == DungeonCell.rock) {
          dungeon.setCell(x, y, DungeonCell.floor);
        }
        if (!_paintOn && dungeon.cellAt(x, y) != DungeonCell.rock) {
          dungeon.setCell(x, y, DungeonCell.rock);
        }
      case DungeonTool.wall:
        if (dungeon.cellAt(x, y) != DungeonCell.rock) {
          dungeon.setCell(x, y, DungeonCell.rock);
        }
      case DungeonTool.door:
        if (!edge && dungeon.isOpen(x, y)) {
          dungeon.setCell(
              x,
              y,
              dungeon.cellAt(x, y) == DungeonCell.door
                  ? DungeonCell.floor
                  : DungeonCell.door);
        }
      case DungeonTool.prop:
        dungeon.addProp(propType, x, y,
            monster: propType == DungeonPropType.monster ? monsterType : null);
      case DungeonTool.erase:
        dungeon.removePropAt(x, y);
    }
    sceneTick.value++;
  }

  /// Toques simples em ferramentas de um clique (porta, objeto) não repetem ao arrastar.
  bool get paintsWhileDragging =>
      tool == DungeonTool.carve ||
      tool == DungeonTool.wall ||
      tool == DungeonTool.erase ||
      tool == DungeonTool.prop;

  // ---------- histórico ----------
  @override
  bool get canUndo => _history.canUndo;
  @override
  bool get canRedo => _history.canRedo;

  @override
  void undo() {
    final r = _history.undo(dungeon);
    if (r != null) _restore(r.$1);
  }

  @override
  void redo() {
    final r = _history.redo(dungeon);
    if (r != null) _restore(r.$1);
  }

  void _restore(Dungeon d) {
    dungeon = d;
    size = d.size;
    systemId = d.systemId;
    revision++;
    notifyListeners();
  }

  // ---------- projeto ----------
  @override
  void setViewMode(ViewMode mode) {
    viewMode = mode;
    activateProjection();
    viewport.requestFit();
    notifyListeners();
  }

  @override
  void activateProjection() =>
      Iso.configure(viewMode, rotation, dungeon.size, dungeon.size);

  @override
  Map<String, dynamic> toJson() => {
        'dungeon': dungeonToJson(dungeon),
        'density': density.name,
        'view': viewMode.name,
        'rotation': rotation,
      };

  @override
  void loadJson(Map<String, dynamic> json) {
    dungeon = dungeonFromJson(json['dungeon'] as Map<String, dynamic>);
    size = dungeon.size;
    systemId = dungeon.systemId;
    density = DungeonDensity.values.asNameMap()[json['density']] ??
        DungeonDensity.medium;
    viewMode = ViewMode.values.asNameMap()[json['view']] ?? ViewMode.isometric;
    rotation = ((json['rotation'] as num?)?.toInt() ?? 0) % 4;
    _history.clear();
    revision++;
    viewport.requestFit();
    notifyListeners();
  }

  @override
  void dispose() {
    sceneTick.dispose();
    clock.dispose();
    super.dispose();
  }
}

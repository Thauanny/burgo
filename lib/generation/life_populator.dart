import 'dart:math';

import '../domain/city.dart';
import '../domain/city_types.dart';
import '../domain/era.dart';
import '../domain/map_item.dart';
import '../domain/tile_grid.dart';
import '../systems/art_profile.dart';
import '../systems/rpg_system.dart';
import '../systems/settlement_type.dart';

/// Controle da população de uma cidade já gerada: põe ou tira pessoas (nas ruas e praças,
/// com as raças da lore do lugar) e monstros (em acampamentos fora da cidade), sem mexer no
/// resto do mapa.
class LifePopulator {
  LifePopulator(this.city, this.sys, this.st, this.r);
  final City city;
  final RpgSystem sys;
  final SettlementType st;
  final Random r;

  Era get era => st.era ?? sys.art.era;

  static int peopleIn(City c) => c.props.where((p) => Figures.isPerson(p.type)).length;
  static int monstersIn(City c) => c.props.where((p) => Figures.isMonster(p.type)).length;

  /// Tiles ocupados por construções, fazendas, objetos, muros e água.
  TileGrid _blocked() {
    final g = TileGrid(city.size);
    for (final b in city.buildings) {
      for (var x = b.x; x < b.x + b.width; x++) {
        for (var y = b.y; y < b.y + b.depth; y++) {
          g.set(x, y, true);
        }
      }
    }
    for (final f in city.farms) {
      for (var x = f.x; x < f.x + f.width; x++) {
        for (var y = f.y; y < f.y + f.depth; y++) {
          g.set(x, y, true);
        }
      }
    }
    for (final p in city.props) {
      g.set(p.x, p.y, true);
    }
    for (var x = 0; x < city.tilesX; x++) {
      for (var y = 0; y < city.tilesY; y++) {
        if (city.water.at(x, y) || city.walls.at(x, y)) g.set(x, y, true);
      }
    }
    return g;
  }

  /// Ruas e praças livres (praças repetidas: lá há mais gente).
  List<(int, int)> _streetTiles(TileGrid blocked) {
    final out = <(int, int)>[];
    for (var x = 0; x < city.tilesX; x++) {
      for (var y = 0; y < city.tilesY; y++) {
        if (blocked.at(x, y)) continue;
        if (city.plaza.at(x, y)) {
          out
            ..add((x, y))
            ..add((x, y))
            ..add((x, y));
        } else if (city.road.at(x, y)) {
          out.add((x, y));
        }
      }
    }
    return out;
  }

  /// Quantas pessoas cabem nas ruas e praças livres, além das que já estão.
  int maxPeople() => peopleIn(city) + _streetTiles(_blocked()).toSet().length;

  List<PropType> get _classes => [
        for (final p in sys.art.people)
          if (!Figures.races.contains(p) && EraRules.allowsProp(p, era)) p
      ];

  List<PropWeight> get _population {
    final allowed = sys.art.people.where(Figures.races.contains).toSet();
    final pop = [
      for (final w in st.population ?? sys.art.population)
        if (allowed.contains(w.type)) w
    ];
    return pop;
  }

  PropType? _race() {
    final pop = _population;
    if (pop.isEmpty) return null;
    var total = 0.0;
    for (final w in pop) {
      total += w.weight;
    }
    var roll = r.nextDouble() * total;
    for (final w in pop) {
      roll -= w.weight;
      if (roll <= 0) return w.type;
    }
    return pop.last.type;
  }

  /// Deixa a cidade com [target] pessoas.
  void setPeople(int target) {
    final people = city.props.where((p) => Figures.isPerson(p.type)).toList()..shuffle(r);
    if (people.length > target) {
      for (final p in people.take(people.length - target)) {
        city.remove(p);
      }
      return;
    }
    final classes = _classes;
    if (classes.isEmpty) return;
    final folk = classes.where((p) => Figures.folk.contains(p) || Figures.loopFolk.contains(p)).toList();
    final tiles = _streetTiles(_blocked())..shuffle(r);
    final taken = <(int, int)>{};
    var missing = target - people.length;
    for (final t in tiles) {
      if (missing <= 0) break;
      if (!taken.add(t)) continue;
      final type = folk.isNotEmpty && r.nextDouble() < .45 ? folk[r.nextInt(folk.length)] : classes[r.nextInt(classes.length)];
      final race = Figures.loopFolk.contains(type) ? null : _race();
      city.add(Prop(id: city.newId(), x: t.$1, y: t.$2, type: type, race: race));
      missing--;
    }
  }

  List<PropType> get _monsters => [
        for (final m in sys.art.monsters)
          if (EraRules.allowsProp(m, era)) m
      ];

  /// Deixa o mapa com [target] monstros, em acampamentos com fogueira longe das casas.
  void setMonsters(int target) {
    final monsters = city.props.where((p) => Figures.isMonster(p.type)).toList()..shuffle(r);
    if (monsters.length > target) {
      for (final m in monsters.take(monsters.length - target)) {
        city.remove(m);
      }
      // fogueiras que ficaram sem ninguém em volta saem também
      final left = city.props.where((p) => Figures.isMonster(p.type)).toList();
      for (final f in city.props.where((p) => p.type == PropType.campfire).toList()) {
        if (!left.any((m) => (m.x - f.x).abs() <= 3 && (m.y - f.y).abs() <= 3)) city.remove(f);
      }
      return;
    }
    final pool = _monsters;
    if (pool.isEmpty) return;
    var missing = target - monsters.length;
    final blocked = _blocked();
    for (final gap in const [6, 4, 2, 0]) {
      final centers = <(int, int)>[];
      for (var x = 2; x < city.tilesX - 2; x++) {
        for (var y = 2; y < city.tilesY - 2; y++) {
          if (blocked.at(x, y) || city.road.at(x, y) || city.plaza.at(x, y)) continue;
          final far = city.buildings.every((b) =>
              x < b.x - gap || x >= b.x + b.width + gap || y < b.y - gap || y >= b.y + b.depth + gap);
          if (far) centers.add((x, y));
        }
      }
      centers.shuffle(r);
      for (final (cx, cy) in centers) {
        if (missing <= 0) return;
        if (blocked.at(cx, cy)) continue;
        // a fogueira e o bando (2 a 4) em volta
        city.add(Prop(id: city.newId(), x: cx, y: cy, type: PropType.campfire));
        blocked.set(cx, cy, true);
        final kind = pool[r.nextInt(pool.length)];
        final band = min(missing, 2 + r.nextInt(3));
        var placed = 0;
        for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)]) {
          if (placed >= band) break;
          final x = cx + dx, y = cy + dy;
          if (!city.inBounds(x, y) || blocked.at(x, y) || city.road.at(x, y)) continue;
          final type = r.nextDouble() < .75 ? kind : pool[r.nextInt(pool.length)];
          city.add(Prop(id: city.newId(), x: x, y: y, type: type));
          blocked.set(x, y, true);
          placed++;
        }
        missing -= placed;
      }
      if (missing <= 0) return;
    }
  }
}

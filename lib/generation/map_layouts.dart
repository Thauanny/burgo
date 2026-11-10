part of 'procedural_city_generator.dart';

/// Cidades desenhadas a partir de mapas oficiais (Malpetrim, Smokestone, Norba, Sambúrdia).
/// As posições estão em frações do mapa: u = 0 oeste … 1 leste, v = 0 norte … 1 sul.
extension _MapLayouts on _CityBuild {
  City _runLayout() {
    // começa limpo: o terreno genérico (costa, lago, rio sorteado) não vale para estes mapas
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        city.water.set(x, y, false);
        occupied.set(x, y, false);
      }
    }
    blocks = const [];
    switch (st.layout) {
      case MapLayout.malpetrim:
        _malpetrim();
      case MapLayout.smokestone:
        _smokestone();
      case MapLayout.norba:
        _norba();
      case MapLayout.samburdia:
        _samburdia();
      case MapLayout.malaren:
        _malaren();
      case MapLayout.boulder:
        _boulder();
      case MapLayout.mercer:
        _mercer();
      case MapLayout.waterdeep:
        _waterdeep();
      case MapLayout.baldursGate:
        _baldursGate();
      case MapLayout.neverwinter:
        _neverwinter();
      case MapLayout.phandalin:
        _phandalin();
      case MapLayout.brynShander:
        _brynShander();
      case MapLayout.none:
        break;
    }
    if (withZone && sys.hasZone) {
      // área especial pedida num mapa oficial: o que estava ali dá lugar a ela
      _paintZone(adapt: true);
      _populateZone();
    }
    _populateLife();
    return city;
  }

  // ---------------------------------------------------------------- ferramentas
  double _u(double u) => u * n;
  double _v(double v) => v * nY;
  (int, int) _t(double u, double v) => (_u(u).floor(), _v(v).floor());

  bool _free(int x, int y) =>
      city.inBounds(x, y) &&
      !occupied.at(x, y) &&
      !city.road.at(x, y) &&
      !city.water.at(x, y) &&
      !city.walls.at(x, y);

  /// Ponto dentro do polígono (pares u, v).
  bool _inPolyUV(List<double> uv, int x, int y) {
    final px = (x + .5) / n, py = (y + .5) / nY;
    var inside = false;
    for (var i = 0, j = uv.length - 2; i < uv.length; j = i, i += 2) {
      final xi = uv[i], yi = uv[i + 1], xj = uv[j], yj = uv[j + 1];
      if ((yi > py) != (yj > py) &&
          px < (xj - xi) * (py - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
    }
    return inside;
  }

  bool _inDisc(double u, double v, double ru, double rv, int x, int y) {
    final dx = ((x + .5) / n - u) / ru, dy = ((y + .5) / nY - v) / rv;
    return dx * dx + dy * dy <= 1;
  }

  /// Linha 4-conectada (sem atalhos na diagonal): muros e ruas ficam emendados.
  void _line4(int x0, int y0, int x1, int y1, void Function(int, int) f) {
    var x = x0, y = y0;
    f(x, y);
    final dx = (x1 - x0).abs(), dy = (y1 - y0).abs();
    final sx = x1 >= x0 ? 1 : -1, sy = y1 >= y0 ? 1 : -1;
    var mx = 0, my = 0;
    while (mx < dx || my < dy) {
      final moveX = my >= dy || (mx < dx && (mx + .5) / dx <= (my + .5) / dy);
      if (moveX) {
        x += sx;
        mx++;
      } else {
        y += sy;
        my++;
      }
      f(x, y);
    }
  }

  /// Caminho por pontos (u, v); [width] 1 ou 2 blocos.
  void _pathUV(List<double> uv, void Function(int, int) f, {int width = 1}) {
    for (var i = 0; i + 3 < uv.length; i += 2) {
      final (x0, y0) = _t(uv[i], uv[i + 1]);
      final (x1, y1) = _t(uv[i + 2], uv[i + 3]);
      _line4(x0, y0, x1, y1, (x, y) {
        f(x, y);
        if (width >= 2) {
          f(x + 1, y);
          f(x, y + 1);
          f(x + 1, y + 1);
        }
      });
    }
  }

  void _roadTile(int x, int y, {bool dirt = false}) {
    if (!city.inBounds(x, y) || city.walls.at(x, y)) return;
    if (dirt && city.road.at(x, y) && !city.dirt.at(x, y)) return; // não rebaixa rua de pedra
    // não passa por cima de rocha, construção ou objeto (só cruza água, como ponte)
    if (occupied.at(x, y) && !city.road.at(x, y) && !city.water.at(x, y)) return;
    city.road.set(x, y, true);
    city.dirt.set(x, y, dirt);
    occupied.set(x, y, true);
  }

  void _waterTile(int x, int y) {
    if (!city.inBounds(x, y)) return;
    city.water.set(x, y, true); // rua que cruza vira ponte
    occupied.set(x, y, true);
  }

  void _wallTile(int x, int y) {
    if (!city.inBounds(x, y) || city.water.at(x, y)) return;
    city.road.set(x, y, false);
    city.walls.set(x, y, true);
    occupied.set(x, y, true);
  }

  /// Portão: abre o muro mais perto do ponto e põe o rótulo.
  void _gateAt(String name, double u, double v) {
    final (gx, gy) = _t(u, v);
    (int, int)? best;
    var bd = 1e9;
    for (var x = gx - 4; x <= gx + 4; x++) {
      for (var y = gy - 4; y <= gy + 4; y++) {
        if (!city.walls.at(x, y)) continue;
        final d = ((x - gx) * (x - gx) + (y - gy) * (y - gy)).toDouble();
        if (d < bd) {
          bd = d;
          best = (x, y);
        }
      }
    }
    if (best == null) return;
    city.walls.set(best.$1, best.$2, false);
    city.road.set(best.$1, best.$2, true);
    occupied.set(best.$1, best.$2, true);
    _label(name, best.$1, best.$2);
  }

  /// Enche a área com construções, sem passar por cima de rua, água ou muro.
  int _packIn(bool Function(int, int) inside, List<KindWeight> kinds,
      {double density = .85, Map<BuildingKind, List<String>> names = const {}}) {
    var count = 0;
    for (var y = 0; y < nY; y++) {
      for (var x = 0; x < n; x++) {
        if (!_free(x, y) || !inside(x, y) || r.nextDouble() > density) continue;
        final kind = _pickWeighted(kinds, (k) => k.weight).kind;
        final shapes = [...BuildingKindSpec.of(kind).footprints]..shuffle(r);
        for (final (w, d) in shapes) {
          var ok = true;
          for (var i = x; i < x + w && ok; i++) {
            for (var j = y; j < y + d && ok; j++) {
              ok = _free(i, j) && inside(i, j);
            }
          }
          if (!ok) continue;
          _addBuilding(x, y, w, d, kind, names: names[kind]);
          count++;
          break;
        }
      }
    }
    return count;
  }

  /// Uma construção num ponto exato (marco do mapa), se couber.
  void _landmarkAt(BuildingKind kind, String name, double u, double v,
      {int? w, int? d}) {
    final (fw, fd) = BuildingKindSpec.of(kind).footprints.first;
    final ww = w ?? fw, dd = d ?? fd;
    final (cx, cy) = _t(u, v);
    for (var ring = 0; ring < 6; ring++) {
      for (var x = cx - ring; x <= cx + ring; x++) {
        for (var y = cy - ring; y <= cy + ring; y++) {
          var ok = true;
          for (var i = x; i < x + ww && ok; i++) {
            for (var j = y; j < y + dd && ok; j++) {
              ok = _free(i, j);
            }
          }
          if (!ok) continue;
          _addBuilding(x, y, ww, dd, kind, names: [name]);
          return;
        }
      }
    }
  }

  /// Talhões de plantação (retângulos de 2 a 6 blocos) dentro da área.
  void _fieldsIn(bool Function(int, int) inside, List<CropType> crops) {
    for (var y = 0; y < nY; y++) {
      for (var x = 0; x < n; x++) {
        if (!_free(x, y) || !inside(x, y)) continue;
        var fw = 1;
        while (fw < 6 && _free(x + fw, y) && inside(x + fw, y)) {
          fw++;
        }
        var fd = 1;
        bool rowOk(int yy) {
          for (var i = x; i < x + fw; i++) {
            if (!_free(i, yy) || !inside(i, yy)) return false;
          }
          return true;
        }

        while (fd < 6 && rowOk(y + fd)) {
          fd++;
        }
        if (fw < FarmLimits.minSide || fd < FarmLimits.minSide) continue;
        city.add(Farm(
            id: city.newId(), x: x, y: y, width: fw, depth: fd, crop: _pick(crops)));
        _occupy(x, y, fw, fd);
      }
    }
  }

  void _forestIn(bool Function(int, int) inside, double density) {
    for (var y = 0; y < nY; y++) {
      for (var x = 0; x < n; x++) {
        if (!_free(x, y) || !inside(x, y)) continue;
        final roll = r.nextDouble();
        if (roll < density) {
          _addTree(x, y);
        } else if (roll < density + .05) {
          _addProp(PropType.bush, x, y);
        }
      }
    }
  }

  void _propsIn(bool Function(int, int) inside, PropType type, double chance) {
    for (var y = 0; y < nY; y++) {
      for (var x = 0; x < n; x++) {
        if (_free(x, y) && inside(x, y) && r.nextDouble() < chance) {
          _addProp(type, x, y);
        }
      }
    }
  }

  /// Grade de ruas dentro da área, a cada [step] blocos.
  void _streetGrid(bool Function(int, int) inside, int step,
      {bool dirt = false, int ox = 0, int oy = 0}) {
    for (var y = 0; y < nY; y++) {
      for (var x = 0; x < n; x++) {
        if (!inside(x, y) || city.water.at(x, y)) continue;
        if ((x + ox) % step == 0 || (y + oy) % step == 0) {
          _roadTile(x, y, dirt: dirt);
        }
      }
    }
  }

  // ---------------------------------------------------------------- Malpetrim
  /// Malpetrim, "a Cidade dos Heróis": porto na costa sudoeste, muralha do Portão Principal ao
  /// Portão Sudeste, rio vindo do norte que se divide em dois canais, cidade baixa densa junto ao
  /// porto, bairro norte mais espaçado e as Granjas dos Armadores a leste do rio.
  void _malpetrim() {
    double coast(double u) => .60 + .57 * u;
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        final u = (x + .5) / n, v = (y + .5) / nY;
        final wob = .012 * sin(u * 40) + .008 * sin(u * 97);
        if (v > coast(u) + wob) _waterTile(x, y);
      }
    }
    // ilhotas de pedra diante do porto
    for (final (u, v) in const [(.07, .74), (.12, .78), (.17, .83), (.05, .80)]) {
      for (var x = 0; x < n; x++) {
        for (var y = 0; y < nY; y++) {
          if (_inDisc(u, v, .018, .014, x, y)) {
            city.water.set(x, y, false);
            occupied.set(x, y, false);
          }
        }
      }
    }
    // rio e os dois canais
    _pathUV(const [.82, 0, .80, .08, .76, .16, .73, .24, .69, .34, .65, .45], _waterTile,
        width: 2);
    _pathUV(const [.65, .45, .55, .52, .50, .60, .48, .67], _waterTile);
    _pathUV(const [.65, .45, .64, .56, .61, .66, .58, .76], _waterTile);
    // muralha
    const wall = [.06, .62, .09, .47, .20, .27, .70, .25, .80, .28, .87, .37, .88, .55, .61, .93];
    const city0 = [...wall, .06, .62];
    bool inside(int x, int y) => _inPolyUV(city0, x, y) && !city.water.at(x, y);
    _pathUV(wall, _wallTile);
    _gateAt('Portão Principal', .09, .47);
    _gateAt('Portão Norte', .43, .25);
    _gateAt('Portão Noroeste', .88, .40);
    _gateAt('Portão Sudeste', .61, .92);
    // ruas principais (pedra) e estradas para fora (terra)
    const mainRoads = [
      [.0, .47, .09, .47, .22, .53, .33, .59, .45, .63, .55, .70, .59, .82, .61, .93, .72, 1.0],
      [.43, .0, .43, .25, .41, .40, .36, .52, .33, .59],
      [1.0, .40, .88, .40, .76, .43, .65, .47, .55, .52, .45, .63],
      [.10, .60, .25, .70, .40, .80, .52, .88],
    ];
    for (final rd in mainRoads) {
      _pathUV(rd, (x, y) => _roadTile(x, y, dirt: !_inPolyUV(city0, x, y)));
    }
    // bairros
    bool dense(int x, int y) {
      final u = (x + .5) / n, v = (y + .5) / nY;
      return inside(x, y) && v > .45 + .12 * u && u < .63;
    }

    bool granjas(int x, int y) {
      final u = (x + .5) / n, v = (y + .5) / nY;
      return inside(x, y) && (u > .66 || (u > .61 && v > .5));
    }

    bool north(int x, int y) => inside(x, y) && !dense(x, y) && !granjas(x, y);
    _streetGrid(dense, 4);
    _streetGrid(north, 7, oy: 2);
    _streetGrid(granjas, 9, dirt: true, ox: 3);
    // marcos (legenda do mapa oficial)
    final (mx, my) = _t(.33, .60);
    for (var x = mx - 2; x <= mx + 2; x++) {
      for (var y = my - 2; y <= my + 1; y++) {
        if (!city.inBounds(x, y) || city.water.at(x, y)) continue;
        city.road.set(x, y, false);
        city.plaza.set(x, y, true);
        occupied.set(x, y, true);
      }
    }
    _addPropForce(PropType.well, mx, my);
    _addPropForce(PropType.stall, mx - 2, my - 2);
    _addPropForce(PropType.stall, mx + 2, my + 1);
    _label('Mercado', mx, my);
    _landmarkAt(BuildingKind.temple, 'Templo de Marah', .55, .74);
    _landmarkAt(BuildingKind.arena, 'Arena de Malpetrim', .27, .50);
    _landmarkAt(BuildingKind.timber, 'Estalagem do Macaco Empalhado', .46, .58);
    _landmarkAt(BuildingKind.timber, 'Estalagem da Águia Dourada', .37, .66);
    for (final b in city.buildings) {
      _label(b.name, b.x + b.width / 2, b.y);
    }
    _packIn(dense, const [
      KindWeight(BuildingKind.tallHouse, 4),
      KindWeight(BuildingKind.timber, 4),
      KindWeight(BuildingKind.cottage, 2),
    ], density: .95);
    _packIn(north, const [
      KindWeight(BuildingKind.cottage, 4),
      KindWeight(BuildingKind.timber, 2),
      KindWeight(BuildingKind.manor, 1),
    ], density: .22);
    _propsIn(north, PropType.tree, .06);
    // granjas: casarões dos armadores entre hortas e pomares
    _packIn(granjas, const [
      KindWeight(BuildingKind.manor, 3),
      KindWeight(BuildingKind.barn, 1),
    ], density: .05);
    _fieldsIn(granjas, const [CropType.orchard, CropType.vegetables, CropType.pasture]);
    _label('Granjas dos Armadores', _u(.77), _v(.48));
    // porto: docas na costa da cidade, barcos no mar
    var docks = 0;
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        final u = (x + .5) / n;
        if (u < .08 || u > .6 || !city.water.at(x, y) || city.road.at(x, y)) continue;
        if (!city.water.at(x, y - 1) && docks < 40 && x % 3 == 0) {
          _addProp(PropType.dock, x, y);
          docks++;
        }
      }
    }
    for (final (u, v) in const [(.25, .93), (.40, .97), (.12, .90), (.33, .99)]) {
      final (x, y) = _t(u, v);
      if (city.water.at(x, y)) _addPropForce(PropType.boat, x, y);
    }
    _label('Porto de Malpetrim', _u(.30), _v(.84));
    // fora da muralha: mata ao norte e a sudeste, campo a oeste
    _forestIn((x, y) => (y + .5) / nY < .13 && (x + .5) / n > .22, .75);
    _forestIn((x, y) {
      final u = (x + .5) / n, v = (y + .5) / nY;
      return u > .72 && v > .62;
    }, .7);
    _forestIn((x, y) => !_inPolyUV(city0, x, y), .06);
    _fieldsIn((x, y) {
      final u = (x + .5) / n, v = (y + .5) / nY;
      return u < .18 && v > .18 && v < .44 && r.nextDouble() < .5;
    }, const [CropType.wheat, CropType.vegetables]);
  }

  void _addPropForce(PropType type, int x, int y) {
    if (!city.inBounds(x, y)) return;
    city.add(Prop(id: city.newId(), type: type, x: x, y: y));
    occupied.set(x, y, true);
  }

  // ---------------------------------------------------------------- Smokestone
  /// Smokestone: cidade de faroeste no deserto de Petrynia, aos pés de grandes rochas
  /// vermelhas (uma mesa enorme a noroeste, pilares ao norte e a leste, uma agulha a oeste).
  /// Ruas paralelas, cercado em volta do povoado, curral e cemitério ao sul; a oeste, o rio,
  /// os moinhos-bomba e as hortas.
  void _smokestone() {
    // rio a oeste
    _pathUV(const [.12, 0, .16, .12, .10, .25, .14, .40, .07, .55, .12, .70, .05, .85, .08, 1.0],
        _waterTile, width: 2);
    const rocks = [
      (.30, .24, .15, .20),
      (.50, .26, .05, .10),
      (.55, .38, .045, .08),
      (.69, .22, .03, .08),
      (.74, .34, .04, .08),
      (.83, .60, .11, .17),
      (.25, .52, .04, .10),
    ];
    for (final (u, v, ru, rv) in rocks) {
      for (var x = 0; x < n; x++) {
        for (var y = 0; y < nY; y++) {
          if (_free(x, y) && _inDisc(u, v, ru, rv, x, y)) {
            _addProp(PropType.mesa, x, y);
          }
        }
      }
    }
    // cerca do povoado (estrada de terra em volta) e ruas
    const town = [.30, .62, .30, .90, .64, .94, .82, .82, .76, .62, .58, .50, .38, .50];
    _pathUV([...town, town[0], town[1]], (x, y) => _roadTile(x, y, dirt: true));
    bool inTown(int x, int y) => _inPolyUV(town, x, y);
    for (final v in const [.62, .71, .80]) {
      _pathUV([.30, v, .80, v], (x, y) {
        if (inTown(x, y)) _roadTile(x, y, dirt: true);
      });
    }
    _streetGrid(inTown, 8, dirt: true, oy: 1000);
    _pathUV(const [.0, .66, .30, .71], (x, y) => _roadTile(x, y, dirt: true));
    _pathUV(const [.64, .94, .70, 1.0], (x, y) => _roadTile(x, y, dirt: true));
    // curral e cemitério ao sul
    bool corral(int x, int y) => _inDisc(.48, .86, .06, .05, x, y);
    _fieldsIn(corral, const [CropType.pasture]);
    _propsIn((x, y) => _inDisc(.62, .87, .04, .04, x, y), PropType.grave, .45);
    _label('Cemitério', _u(.62), _v(.87));
    _landmarkAt(BuildingKind.saloon, 'Saloon do Fumo Vermelho', .50, .68);
    _landmarkAt(BuildingKind.saloon, 'Xerife', .40, .76);
    _landmarkAt(BuildingKind.saloon, 'Banco de Smokestone', .62, .76);
    for (final b in city.buildings) {
      _label(b.name, b.x + b.width / 2, b.y);
    }
    _packIn(inTown, st.kinds ?? const [KindWeight(BuildingKind.saloon, 1)], density: .8);
    _propsIn(inTown, PropType.horse, .03);
    _propsIn(inTown, PropType.barrel, .03);
    // oeste: moinhos-bomba (caixas d'água), hortas e cactos
    for (final (u, v) in const [(.20, .30), (.22, .46), (.17, .60)]) {
      final (x, y) = _t(u, v);
      if (_free(x, y)) _addProp(PropType.waterTower, x, y);
    }
    _fieldsIn((x, y) {
      final u = (x + .5) / n, v = (y + .5) / nY;
      return u > .15 && u < .26 && v > .55 && v < .72;
    }, const [CropType.corn, CropType.vegetables]);
    _propsIn((x, y) => !inTown(x, y), PropType.cactus, .03);
    _label('Smokestone', _u(.55), _v(.56));
  }

  // ---------------------------------------------------------------- Norba
  /// Norba: vila numa clareira cercada de mata fechada, com quatro estradas de terra saindo da
  /// praça, talhões coloridos a oeste, um bosque dentro da clareira e o lago a sudeste.
  void _norba() {
    const clearing = [
      .07, .26, .28, .13, .55, .16, .78, .24, .74, .44, .68, .70, .55, .84,
      .30, .88, .10, .80, .05, .52,
    ];
    bool open(int x, int y) => _inPolyUV(clearing, x, y);
    // lago no canto sudeste
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (_inDisc(1.02, .98, .17, .15, x, y)) _waterTile(x, y);
      }
    }
    const roads = [
      [.20, .0, .24, .12, .40, .30, .47, .45],
      [.30, .20, .55, .23, .76, .27, 1.0, .29],
      [.47, .47, .52, .62, .50, .80, .47, 1.0],
      [.44, .50, .30, .56, .18, .62, .0, .63],
      [.76, .27, .70, .0],
    ];
    for (final rd in roads) {
      _pathUV(rd, (x, y) => _roadTile(x, y, dirt: true));
    }
    _label('Para Sambúrdia', _u(.93), _v(.27));
    // praça e vila
    final (px, py) = _t(.46, .48);
    for (var x = px - 3; x <= px + 2; x++) {
      for (var y = py - 3; y <= py + 2; y++) {
        city.road.set(x, y, false);
        city.plaza.set(x, y, true);
        occupied.set(x, y, true);
      }
    }
    _addPropForce(PropType.well, px, py);
    _label('Praça de Norba', px, py);
    const village = [.35, .35, .60, .35, .63, .63, .36, .66];
    bool inVillage(int x, int y) => _inPolyUV(village, x, y);
    _streetGrid(inVillage, 5, dirt: true, ox: 1, oy: 2);
    const places = [
      ('Posto Avançado de Norba', BuildingKind.tower, .38, .10),
      ('Prefeitura', BuildingKind.manor, .52, .40),
      ('O Pônei Rústico', BuildingKind.timber, .40, .44),
      ('Templo', BuildingKind.temple, .55, .55),
      ('Pena Centrífuga', BuildingKind.timber, .42, .58),
      ('Ferraria', BuildingKind.timber, .58, .46),
      ('Carpintaria', BuildingKind.timber, .38, .52),
      ('Herbalista', BuildingKind.cottage, .50, .60),
      ('Pescados do Lago', BuildingKind.cottage, .80, .82),
    ];
    for (final (name, kind, u, v) in places) {
      _landmarkAt(kind, name, u, v);
      final b = city.buildings.last;
      if (b.name == name) _label(name, b.x + b.width / 2, b.y);
    }
    _packIn(inVillage, const [
      KindWeight(BuildingKind.cottage, 4),
      KindWeight(BuildingKind.timber, 3),
    ], density: .8);
    // talhões coloridos a oeste
    for (final (u0, v0, u1, v1, crop) in const [
      (.08, .28, .19, .38, CropType.wheat),
      (.20, .30, .32, .55, CropType.vegetables),
      (.09, .40, .19, .50, CropType.corn),
      (.09, .60, .19, .71, CropType.vegetables),
      (.20, .67, .30, .78, CropType.wheat),
    ]) {
      _fieldsIn((x, y) {
        final u = (x + .5) / n, v = (y + .5) / nY;
        return u >= u0 && u <= u1 && v >= v0 && v <= v1;
      }, [crop]);
    }
    // bosque dentro da clareira, mata fechada em volta, árvores soltas no campo
    _forestIn((x, y) => _inDisc(.60, .30, .07, .07, x, y), .85);
    _forestIn((x, y) => !open(x, y), .82);
    _forestIn(open, .03);
    _propsIn(open, PropType.sheep, .01);
  }

  // ---------------------------------------------------------------- Sambúrdia
  /// Sambúrdia, o "celeiro de Arton": campos entre grandes florestas, o Rio Sambúrdia descendo
  /// até o mar, as Montanhas Sanguinárias a nordeste e a capital murada com o castelo.
  void _samburdia() {
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        final u = (x + .5) / n, v = (y + .5) / nY;
        if (v > .86 + .05 * sin(u * 9) || (u > .70 && v > .80 - (u - .7) * .4)) {
          _waterTile(x, y);
        }
      }
    }
    _pathUV(const [.52, .0, .50, .18, .55, .35, .51, .55, .56, .72, .54, .90], _waterTile,
        width: 2);
    _pathUV(const [.88, .30, .86, .45, .90, .60, .86, .80], _waterTile);
    _label('Rio Sambúrdia', _u(.55), _v(.45));
    _label('Cataratas de Sambúrdia', _u(.88), _v(.45));
    // montanhas a nordeste
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        final u = (x + .5) / n, v = (y + .5) / nY;
        if (u > .66 && v < .32 - (1 - u) * .2 && _free(x, y) && r.nextDouble() < .55) {
          _addProp(PropType.mountain, x, y);
        }
      }
    }
    _label('Montanhas Sanguinárias', _u(.84), _v(.12));
    // capital murada
    const cap = [.14, .26, .32, .26, .32, .44, .14, .44];
    bool inCap(int x, int y) => _inPolyUV(cap, x, y);
    _pathUV([...cap, cap[0], cap[1]], _wallTile);
    _gateAt('Portão da Capital', .32, .35);
    _streetGrid(inCap, 5, ox: 2, oy: 1);
    _landmarkAt(BuildingKind.castle, 'Palácio de Sambúrdia', .22, .33);
    _packIn(inCap, const [
      KindWeight(BuildingKind.timber, 3),
      KindWeight(BuildingKind.cottage, 3),
      KindWeight(BuildingKind.temple, .5),
    ], density: .9);
    _label('Sambúrdia Capital', _u(.23), _v(.24));
    // estradas entre a capital, o rio e o litoral
    for (final rd in const [
      [.32, .35, .50, .40, .62, .55, .74, .62],
      [.23, .44, .30, .65, .45, .78, .55, .85],
      [.50, .40, .48, .0],
    ]) {
      _pathUV(rd, (x, y) => _roadTile(x, y, dirt: true));
    }
    // marcos da região
    _landmarkAt(BuildingKind.tower, 'Torre de Erebo', .63, .50);
    _landmarkAt(BuildingKind.temple, 'Tumba de Mokk Amhor', .40, .48);
    _landmarkAt(BuildingKind.temple, 'Refúgio da Donzela', .58, .76);
    _landmarkAt(BuildingKind.manor, 'Balneário de Zannar', .74, .66);
    for (final b in city.buildings.where((b) => b.kind != BuildingKind.cottage &&
        b.kind != BuildingKind.timber)) {
      if (b.kind == BuildingKind.castle) continue;
      _label(b.name, b.x + b.width / 2, b.y);
    }
    _label('Formigueiro', _u(.44), _v(.28));
    _label('Buraco de Vectora', _u(.74), _v(.42));
    // florestas em grandes manchas (como no mapa) e a Floresta das Escamas Verdes
    bool forest(int x, int y) {
      final u = (x + .5) / n, v = (y + .5) / nY;
      final band = sin(u * 13 + 1.2) * cos(v * 11 - .5) + .5 * sin((u + v) * 17);
      return band > .55 ||
          _inDisc(.28, .64, .14, .14, x, y) ||
          _inDisc(.40, .18, .14, .07, x, y);
    }

    _forestIn(forest, .85);
    _label('Floresta das Escamas Verdes', _u(.28), _v(.64));
    // sítios e campos no resto
    _packIn((x, y) => !forest(x, y) && !inCap(x, y), const [
      KindWeight(BuildingKind.cottage, 3),
      KindWeight(BuildingKind.barn, 2),
      KindWeight(BuildingKind.windmill, 1),
    ], density: .012);
    _fieldsIn((x, y) => !forest(x, y) && !inCap(x, y), st.crops);
    _propsIn((x, y) => !forest(x, y), PropType.cow, .01);
  }

  // ---------------------------------------------------------------- Tales from the Loop
  /// Pontos do mapa oficial das Ilhas Mälaren (imagem de 900×1393 px, girada 90°: a legenda
  /// está de lado). Converte (x, y) da imagem para (u, v) com o norte em cima.
  List<double> _img(List<double> xy) => [
        for (var i = 0; i + 1 < xy.length; i += 2) ...[1 - xy[i + 1] / 1393, xy[i] / 900],
      ];

  (double, double) _imgPt(double x, double y) => (1 - y / 1393, x / 900);

  bool _inImgDisc(double x, double y, double rx, double ry, int tx, int ty) {
    final (u, v) = _imgPt(x, y);
    return _inDisc(u, v, ry / 1393, rx / 900, tx, ty);
  }

  /// Povoado: casas e galpões num círculo pequeno, com rua.
  void _hamlet(String name, double x, double y, List<KindWeight> kinds,
      {double r = 26, double density = .55, bool label = true}) {
    bool inside(int tx, int ty) => _inImgDisc(x, y, r, r, tx, ty);
    final (u, v) = _imgPt(x, y);
    final (cx, cy) = _t(u, v);
    for (var tx = cx - 6; tx <= cx + 6; tx++) {
      if (inside(tx, cy)) _roadTile(tx, cy);
    }
    _packIn(inside, kinds, density: density);
    if (label) _label(name, cx, cy);
  }

  /// Ilhas Mälaren: o arquipélago a oeste de Estocolmo onde fica o Loop. Svartsjölandet, Munsö,
  /// Adelsö e Ekerö, ilhotas, o reator Bona com as torres de resfriamento em Munsö, o anel do
  /// acelerador, os portões, povoados de chalés vermelhos, matas, campos e os fiordes do lago.
  void _malaren() {
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        _waterTile(x, y);
      }
    }
    final islands = <String, List<double>>{
      'Svartsjölandet': _img(const [
        255, 560, 250, 500, 270, 450, 300, 420, 320, 370, 370, 330, 420, 300, 470, 260, 520, 230,
        580, 200, 640, 160, 700, 140, 760, 120, 800, 150, 790, 220, 760, 290, 720, 330, 700, 380,
        660, 420, 620, 470, 600, 520, 560, 560, 520, 580, 470, 590, 420, 600, 360, 610, 300, 600,
      ]),
      'Munsö': _img(const [
        290, 700, 310, 650, 360, 630, 430, 625, 500, 610, 560, 595, 600, 575, 625, 610, 600, 650,
        540, 690, 480, 730, 430, 770, 380, 800, 320, 790, 285, 750,
      ]),
      'Adelsö': _img(const [
        290, 880, 330, 840, 400, 815, 480, 790, 560, 770, 625, 780, 640, 830, 600, 880, 540, 930,
        470, 990, 400, 1050, 330, 1080, 280, 1040, 270, 960,
      ]),
      'Ekerö': _img(const [
        640, 760, 660, 700, 690, 640, 720, 560, 750, 480, 780, 400, 820, 330, 860, 300, 880, 360,
        870, 450, 840, 540, 800, 640, 760, 720, 700, 790,
      ]),
      '': _img(const [720, 0, 900, 0, 900, 100, 800, 110, 740, 60]),
      ' ': _img(const [700, 840, 780, 800, 900, 820, 900, 1000, 800, 980, 720, 900]),
      '  ': _img(const [0, 1100, 60, 1080, 120, 1200, 180, 1393, 0, 1393]),
      '   ': _img(const [820, 1150, 900, 1100, 900, 1393, 760, 1393]),
    };
    const small = [
      ('Dävensö', 190.0, 690.0, 25.0, 40.0),
      ('Eldgarnsö', 200.0, 530.0, 30.0, 55.0),
      ('Alholmen', 130.0, 850.0, 18.0, 30.0),
      ('Lagnö', 210.0, 820.0, 18.0, 25.0),
      ('Bastlagnö', 120.0, 1140.0, 20.0, 40.0),
    ];
    bool land(int x, int y) =>
        islands.values.any((p) => _inPolyUV(p, x, y)) ||
        small.any((s) => _inImgDisc(s.$2, s.$3, s.$4, s.$5, x, y));
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (land(x, y)) {
          city.water.set(x, y, false);
          occupied.set(x, y, false);
        }
      }
    }
    // reator Bona e as torres de resfriamento (sempre visíveis no horizonte)
    bool bona(int x, int y) => _inImgDisc(355, 720, 62, 62, x, y);
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (bona(x, y) && !city.water.at(x, y)) {
          city.plaza.set(x, y, true);
          occupied.set(x, y, true);
        }
      }
    }
    void clearAt(double u, double v, int w, int d) {
      final (x, y) = _t(u, v);
      for (var i = x; i < x + w; i++) {
        for (var j = y; j < y + d; j++) {
          city.plaza.set(i, j, false);
          occupied.set(i, j, false);
        }
      }
    }

    for (final (px, py) in const [(340.0, 740.0), (380.0, 700.0), (395.0, 755.0)]) {
      final (u, v) = _imgPt(px, py);
      clearAt(u, v, 3, 3);
      _landmarkAt(BuildingKind.coolingTower, 'Torre de resfriamento', u, v);
    }
    final (bu, bv) = _imgPt(330, 700);
    clearAt(bu, bv, 4, 4);
    _landmarkAt(BuildingKind.lab, 'Reator Bona', bu, bv, w: 4, d: 4);
    final (lu, lv) = _imgPt(355, 720);
    _label('Reator Bona', _u(lu), _v(lv));
    // anel do acelerador (túneis sob a terra): marcado por postes de energia na superfície
    for (final (rk, name) in const [(1.0, 'Acelerador Prim 1'), (.72, 'Acelerador Aux'), (.5, '')]) {
      for (var a = 0.0; a < 2 * pi; a += .05) {
        final (u, v) = _imgPt(330 + cos(a) * 320 * rk, 760 + sin(a) * 320 * rk);
        final (x, y) = _t(u, v);
        if (_free(x, y) && (x + y) % 3 == 0) _addProp(PropType.powerPole, x, y);
      }
      if (name.isNotEmpty) {
        final (u, v) = _imgPt(330 - 320 * rk * .7, 760 - 320 * rk * .7);
        _label(name, _u(u), _v(v));
      }
    }
    // portões do Loop
    for (final (name, px, py) in const [
      ('North Gate 5B', 95.0, 650.0),
      ('East Gate 5D', 385.0, 445.0),
      ('Gate 3C–4C', 330.0, 665.0),
      ('Gate 2D–3B', 300.0, 770.0),
      ('South Gate 5D', 620.0, 565.0),
      ('West Gate 5D', 445.0, 1060.0),
    ]) {
      final (u, v) = _imgPt(px, py);
      _landmarkAt(BuildingKind.modern, name, u, v);
      _label(name, _u(u), _v(v));
    }
    // fábrica de Dävensö
    final (fu, fv) = _imgPt(200, 700);
    _landmarkAt(BuildingKind.warehouse, 'Fábrica de Dävensö', fu, fv);
    // estradas civis entre os povoados
    for (final rd in const [
      [320, 470, 395, 430, 370, 380, 470, 420, 560, 450, 520, 400, 630, 330, 650, 325, 690, 290, 740, 200],
      [300, 740, 355, 720, 450, 690, 560, 620],
      [430, 800, 400, 920, 430, 1020, 320, 1060],
      [650, 640, 720, 600, 800, 450, 840, 330],
    ]) {
      _pathUV(_img(rd.map((e) => e.toDouble()).toList()), (x, y) {
        if (!city.water.at(x, y)) _roadTile(x, y);
      });
    }
    const village = [
      KindWeight(BuildingKind.faluCabin, 6),
      KindWeight(BuildingKind.barn, 1.5),
      KindWeight(BuildingKind.modern, .6),
    ];
    for (final (name, px, py, big) in const [
      ('Stenhamra', 630.0, 330.0, true),
      ('Färentuna', 395.0, 430.0, true),
      ('Hilleshög', 370.0, 380.0, false),
      ('Kungsberga', 320.0, 470.0, false),
      ('Sånga-Säby', 520.0, 400.0, false),
      ('Torslunda', 560.0, 450.0, false),
      ('Morby', 690.0, 290.0, false),
      ('Troxhammar', 740.0, 200.0, false),
      ('Löten', 245.0, 680.0, false),
      ('Stenby', 430.0, 800.0, false),
      ('Dalby', 400.0, 920.0, false),
      ('Torsta', 430.0, 1020.0, false),
      ('Sätra', 320.0, 1060.0, false),
      ('Skytteholm', 720.0, 600.0, false),
      ('Menhammar', 650.0, 640.0, false),
    ]) {
      _hamlet(name, px, py, village, r: big ? 70 : 45, density: big ? .75 : .55, label: true);
    }
    // nomes das ilhas e das águas
    for (final (name, px, py) in const [
      ('Svartsjölandet', 520.0, 420.0),
      ('Munsö', 470.0, 680.0),
      ('Adelsö', 450.0, 920.0),
      ('Ekerö', 770.0, 520.0),
      ('Mälaren', 160.0, 1000.0),
      ('Björkfjärden', 160.0, 900.0),
      ('Prästfjärden', 600.0, 1150.0),
      ('Långtarmen', 560.0, 520.0),
    ]) {
      final (u, v) = _imgPt(px, py);
      _label(name, _u(u), _v(v));
    }
    // docas e barcos (rotas de balsa)
    for (final (px, py) in const [(250.0, 760.0), (620.0, 600.0), (300.0, 870.0), (640.0, 760.0)]) {
      final (u, v) = _imgPt(px, py);
      final (x, y) = _t(u, v);
      for (var dx = -2; dx <= 2; dx++) {
        if (city.water.at(x + dx, y) && !city.water.at(x + dx - 1, y) && _free(x + dx - 1, y) == false) {
          _addPropForce(PropType.dock, x + dx, y);
          break;
        }
      }
    }
    for (final (px, py) in const [(240.0, 800.0), (600.0, 720.0), (180.0, 960.0), (520.0, 1120.0)]) {
      final (u, v) = _imgPt(px, py);
      final (x, y) = _t(u, v);
      if (city.water.at(x, y)) _addPropForce(PropType.boat, x, y);
    }
    // matas e campos (mapa: verde-escuro mata, verde-claro campo)
    final a = r.nextDouble() * 100;
    bool forest(int x, int y) =>
        sin(x * .35 + a) * cos(y * .31 - a) + .5 * sin((x - y) * .2 + a) > .35;
    _forestIn((x, y) => land(x, y) && forest(x, y), .75);
    _fieldsIn((x, y) => land(x, y) && !forest(x, y) && r.nextDouble() < .9,
        const [CropType.wheat, CropType.pasture, CropType.vegetables]);
    _propsIn((x, y) => land(x, y), PropType.robot, .004);
    _propsIn((x, y) => land(x, y), PropType.cow, .006);
  }

  /// Boulder City (Nevada): cidade construída em 1931 para os operários da Represa Hoover,
  /// com o traçado em leque a partir do prédio do Bureau, o parque Wilbur Square, casas térreas
  /// no deserto; a nordeste o Lago Mead, a represa no Black Canyon e o Rio Colorado; a
  /// instalação americana do Loop com as torres de resfriamento no deserto.
  void _boulder() {
    const lake = <double>[.55, 0, 1, 0, 1, .45, .86, .44, .78, .30, .70, .25, .62, .15];
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (_inPolyUV(lake, x, y)) _waterTile(x, y);
      }
    }
    _pathUV(const [.86, .46, .88, .56, .84, .70, .87, .85, .85, 1.0], _waterTile, width: 2);
    // represa atravessando o cânion na saída do lago
    final (dx, dy) = _t(.82, .44);
    for (var x = dx; x < dx + 8; x++) {
      for (var y = dy; y < dy + 2; y++) {
        if (!city.inBounds(x, y)) continue;
        city.water.set(x, y, false);
        occupied.set(x, y, false);
      }
    }
    _addBuilding(dx, dy, 8, 2, BuildingKind.dam, names: const ['Represa Hoover']);
    _label('Represa Hoover', dx + 4, dy);
    _label('Lago Mead', _u(.82), _v(.15));
    _label('Rio Colorado', _u(.90), _v(.75));
    // montanhas (River Mountains) e paredões do cânion
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        final u = (x + .5) / n, v = (y + .5) / nY;
        final canyon = (u - .86).abs() < .06 && v > .48 && !city.water.at(x, y);
        final north = u < .45 && v < .2;
        if ((canyon || north) && _free(x, y) && r.nextDouble() < (canyon ? .6 : .35)) {
          _addProp(PropType.mesa, x, y);
        }
      }
    }
    // rodovia 93: de noroeste, passando pela cidade, até a represa
    _pathUV(const [.0, .26, .20, .30, .35, .33, .55, .40, .70, .44, .82, .45], (x, y) => _roadTile(x, y));
    _label('Rodovia 93', _u(.12), _v(.26));
    // traçado em leque: ruas radiais a partir do Bureau e ruas em arco
    const ax = .35, ay = .36;
    for (var k = 0; k < 7; k++) {
      final ang = pi * (.18 + k * .107);
      _pathUV([ax, ay, ax + cos(ang) * .30, ay + sin(ang) * .42], (x, y) => _roadTile(x, y));
    }
    for (final rr in const [.09, .16, .23, .30]) {
      for (var ang = pi * .16; ang <= pi * .84; ang += .02) {
        final (x, y) = _t(ax + cos(ang) * rr, ay + sin(ang) * rr * 1.4);
        _roadTile(x, y);
      }
    }
    bool fan(int x, int y) {
      final u = (x + .5) / n - ax, v = ((y + .5) / nY - ay) / 1.4;
      final d = sqrt(u * u + v * v), ang = atan2(v, u);
      return d > .04 && d < .31 && ang > pi * .16 && ang < pi * .84;
    }

    // prédio do Bureau e o parque Wilbur Square em frente
    _landmarkAt(BuildingKind.block, 'Prédio do Bureau of Reclamation', ax - .02, ay - .05);
    bool park(int x, int y) {
      final u = (x + .5) / n - ax, v = ((y + .5) / nY - ay) / 1.4;
      final d = sqrt(u * u + v * v), ang = atan2(v, u);
      return d > .03 && d < .085 && ang > pi * .38 && ang < pi * .62;
    }

    _propsIn(park, PropType.tree, .45);
    _label('Wilbur Square', _u(ax), _v(ay + .07));
    // comércio no primeiro arco, casas térreas no resto
    bool downtown(int x, int y) {
      final u = (x + .5) / n - ax, v = ((y + .5) / nY - ay) / 1.4;
      return fan(x, y) && sqrt(u * u + v * v) < .16 && !park(x, y);
    }

    _landmarkAt(BuildingKind.modern, 'Posto de gasolina', ax + .12, ay + .02);
    _landmarkAt(BuildingKind.modern, 'Escola de Boulder City', ax - .14, ay + .16);
    _packIn(downtown, const [
      KindWeight(BuildingKind.modern, 4),
      KindWeight(BuildingKind.ranch, 2),
    ], density: .6, names: const {
      BuildingKind.modern: ['Lanchonete', 'Fliperama', 'Locadora de fitas', 'Loja de ferragens', 'Cinema'],
    });
    _packIn((x, y) => fan(x, y) && !downtown(x, y), const [
      KindWeight(BuildingKind.ranch, 6),
      KindWeight(BuildingKind.house, 1),
    ], density: .55);
    _propsIn(fan, PropType.car, .03);
    _propsIn(fan, PropType.tree, .02);
    final (wx, wy) = _t(ax - .06, ay - .08);
    _addPropForce(PropType.waterTower, wx, wy);
    _label('Boulder City', _u(ax), _v(ay - .1));
    // instalação do Loop (Nevada) no deserto, ao sul da represa
    bool facility(int x, int y) => _inDisc(.64, .72, .09, .12, x, y);
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (facility(x, y) && _free(x, y)) {
          city.plaza.set(x, y, true);
          occupied.set(x, y, true);
        }
      }
    }
    void free(double u, double v, int w, int d) {
      final (x, y) = _t(u, v);
      for (var i = x; i < x + w; i++) {
        for (var j = y; j < y + d; j++) {
          city.plaza.set(i, j, false);
          occupied.set(i, j, false);
        }
      }
    }

    for (final (u, v) in const [(.60, .66), (.66, .66)]) {
      free(u, v, 3, 3);
      _landmarkAt(BuildingKind.coolingTower, 'Torre de resfriamento', u, v);
    }
    free(.60, .76, 4, 4);
    _landmarkAt(BuildingKind.lab, 'Instalação do Loop (Boulder)', .60, .76, w: 4, d: 4);
    _label('Instalação do Loop (Boulder)', _u(.64), _v(.86));
    _pathUV(const [.55, .40, .58, .55, .62, .62], (x, y) => _roadTile(x, y));
    _propsIn((x, y) => _inDisc(.64, .72, .11, .14, x, y) && !facility(x, y), PropType.powerPole, .25);
    // deserto
    _propsIn((x, y) => !fan(x, y), PropType.cactus, .03);
    _propsIn((x, y) => !fan(x, y), PropType.robot, .002);
  }

  /// Mercer (Ohio), a cidade da série da Amazon: cidadezinha do meio-oeste em cima do
  /// complexo do Loop (o Mercer Center for Experimental Physics, com o Eclipse no subsolo),
  /// cercada de campos de milho, sítios com silo, um bosque com robôs abandonados e o lago.
  void _mercer() {
    // lago a sudoeste e riacho
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (_inDisc(.16, .78, .11, .13, x, y)) _waterTile(x, y);
      }
    }
    _pathUV(const [.24, .74, .32, .62, .30, .50, .36, .34, .34, .0], _waterTile);
    _label('Lago', _u(.16), _v(.78));
    // estradas: rua principal, avenida até o Loop e estradas rurais
    _pathUV(const [.0, .48, 1.0, .48], (x, y) => _roadTile(x, y));
    _pathUV(const [.48, .0, .48, 1.0], (x, y) => _roadTile(x, y));
    _pathUV(const [.48, .40, .62, .30, .76, .24], (x, y) => _roadTile(x, y));
    for (final rd in const [
      <double>[.70, .48, .70, 1.0],
      <double>[.48, .75, 1.0, .75],
      <double>[.0, .20, .48, .20],
    ]) {
      _pathUV(rd, (x, y) => _roadTile(x, y, dirt: true));
    }
    _label('Main Street', _u(.40), _v(.48));
    // centro da cidade em grade
    bool town(int x, int y) => _inDisc(.47, .48, .13, .17, x, y);
    _streetGrid(town, 5, ox: 2, oy: 1);
    _landmarkAt(BuildingKind.church, 'Igreja de Mercer', .42, .40);
    _landmarkAt(BuildingKind.block, 'Prefeitura de Mercer', .52, .43);
    _landmarkAt(BuildingKind.modern, 'Escola de Mercer', .40, .55);
    _landmarkAt(BuildingKind.modern, 'Lanchonete', .54, .52);
    for (final b in city.buildings) {
      _label(b.name, b.x + b.width / 2, b.y);
    }
    final (wx, wy) = _t(.57, .40);
    _addPropForce(PropType.waterTower, wx, wy);
    _packIn(town, const [
      KindWeight(BuildingKind.house, 6),
      KindWeight(BuildingKind.modern, 1.5),
    ], density: .7, names: const {
      BuildingKind.modern: ['Mercearia', 'Barbearia', 'Correio', 'Posto de gasolina', 'Loja de ferragens'],
    });
    _propsIn(town, PropType.tree, .05);
    _propsIn(town, PropType.car, .03);
    // o Loop: Mercer Center for Experimental Physics, a nordeste
    bool campus(int x, int y) => _inDisc(.80, .24, .13, .17, x, y);
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (campus(x, y) && _free(x, y)) {
          city.plaza.set(x, y, true);
          occupied.set(x, y, true);
        }
      }
    }
    void free(double u, double v, int w, int d) {
      final (x, y) = _t(u, v);
      for (var i = x; i < x + w; i++) {
        for (var j = y; j < y + d; j++) {
          city.plaza.set(i, j, false);
          occupied.set(i, j, false);
        }
      }
    }

    free(.74, .16, 4, 4);
    _landmarkAt(BuildingKind.lab, 'Mercer Center for Experimental Physics', .74, .16, w: 4, d: 4);
    free(.84, .14, 3, 3);
    _landmarkAt(BuildingKind.coolingTower, 'Torre de resfriamento', .84, .14);
    free(.80, .30, 4, 4);
    _landmarkAt(BuildingKind.lab, 'Laboratório do Loop', .80, .30, w: 4, d: 4);
    final (ex, ey) = _t(.86, .26);
    city.plaza.set(ex, ey, false);
    occupied.set(ex, ey, false);
    _addPropForce(PropType.eclipse, ex, ey);
    _label('O Eclipse (no subsolo do Loop)', ex, ey);
    _label('Mercer Center for Experimental Physics', _u(.80), _v(.06));
    _propsIn((x, y) => _inDisc(.80, .24, .15, .19, x, y) && !campus(x, y), PropType.powerPole, .2);
    // bosque com robôs abandonados a noroeste
    bool woods(int x, int y) => _inDisc(.14, .22, .16, .2, x, y);
    _forestIn(woods, .7);
    _propsIn(woods, PropType.robot, .06);
    _label('Bosque', _u(.14), _v(.22));
    // sítios e campos de milho no resto
    bool farmland(int x, int y) => !town(x, y) && !campus(x, y) && !woods(x, y);
    _packIn(farmland, const [
      KindWeight(BuildingKind.farmhouse, 3),
      KindWeight(BuildingKind.barn, 2),
      KindWeight(BuildingKind.silo, 1),
    ], density: .012);
    _fieldsIn(farmland, const [CropType.corn, CropType.corn, CropType.wheat, CropType.pasture]);
    _forestIn(farmland, .08);
  }

  // ---------------------------------------------------------------- D&D (Costa da Espada)
  bool _inRectUV(double u0, double v0, double u1, double v1, int x, int y) {
    final u = (x + .5) / n, v = (y + .5) / nY;
    return u >= u0 && u <= u1 && v >= v0 && v <= v1;
  }

  /// Bairro: ruas em grade, casas do estilo dele e o nome no mapa.
  void _ward(String name, bool Function(int, int) inside, List<KindWeight> kinds,
      {int step = 5, double density = .8, double lu = -1, double lv = -1,
      Map<BuildingKind, List<String>> names = const {}}) {
    _streetGrid(inside, step, ox: name.length % step, oy: (name.length * 3) % step);
    _packIn(inside, kinds, density: density, names: names);
    if (lu >= 0) _label(name, _u(lu), _v(lv));
  }

  void _labelBuildings(Iterable<String> names) {
    for (final b in city.buildings.where((b) => names.contains(b.name))) {
      _label(b.name, b.x + b.width / 2, b.y);
    }
  }

  void _clearPlaza(double u0, double v0, double u1, double v1) {
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (_inRectUV(u0, v0, u1, v1, x, y) && !city.water.at(x, y)) {
          city.road.set(x, y, false);
          city.plaza.set(x, y, true);
          occupied.set(x, y, true);
        }
      }
    }
  }

  static const _kNoble = [
    KindWeight(BuildingKind.manor, 4),
    KindWeight(BuildingKind.tallHouse, 2),
    KindWeight(BuildingKind.temple, .6),
  ];
  static const _kTrade = [
    KindWeight(BuildingKind.tallHouse, 4),
    KindWeight(BuildingKind.timber, 4),
  ];
  static const _kPoor = [
    KindWeight(BuildingKind.cottage, 5),
    KindWeight(BuildingKind.timber, 2),
  ];
  static const _kDocks = [
    KindWeight(BuildingKind.tallHouse, 3),
    KindWeight(BuildingKind.warehouse, 0),
    KindWeight(BuildingKind.barn, 3),
    KindWeight(BuildingKind.timber, 2),
  ];

  /// Waterdeep, a Cidade dos Esplendores: o mar a oeste, o Monte Waterdeep com o Castelo na
  /// costa, o Porto de Águas Profundas e a Ilha Deepwater ao sul, a muralha em volta e os
  /// distritos: Sea Ward (templos e casas nobres, noroeste), North Ward (casas nobres e
  /// estalagens), Castle Ward (governo, no monte), Trades Ward (comércio), Southern Ward
  /// (caravanas e estábulos), Dock Ward (docas e estaleiros), Field Ward (pobre, entre as
  /// muralhas do norte) e a Cidade dos Mortos (cemitério murado).
  void _waterdeep() {
    double coast(double v) => .08 + .05 * sin(v * 9) + (v > .62 ? .30 * (v - .62) / .38 : 0);
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        final u = (x + .5) / n, v = (y + .5) / nY;
        final harbor = _inDisc(.30, .90, .26, .14, x, y);
        if (u < coast(v) || harbor) _waterTile(x, y);
      }
    }
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (_inDisc(.24, .93, .05, .03, x, y)) {
          city.water.set(x, y, false);
          occupied.set(x, y, false);
        }
      }
    }
    _label('Ilha Deepwater', _u(.24), _v(.93));
    _label('Porto de Águas Profundas', _u(.36), _v(.86));
    _label('Mar das Espadas', _u(.04), _v(.25));
    // Monte Waterdeep e o castelo
    bool mount(int x, int y) => _inDisc(.17, .50, .07, .13, x, y) && !city.water.at(x, y);
    _propsIn((x, y) => mount(x, y) && !_inDisc(.18, .48, .035, .05, x, y), PropType.mountain, .55);
    _landmarkAt(BuildingKind.castle, 'Castelo Waterdeep', .17, .46);
    _label('Monte Waterdeep', _u(.12), _v(.62));
    for (final (u, v) in const [(.12, .32), (.26, .74)]) {
      _landmarkAt(BuildingKind.lighthouse, 'Farol', u, v);
    }
    // muralha externa e a interna do norte (o Field Ward fica entre elas)
    const outer = [.13, .06, .86, .06, .92, .30, .92, .78, .62, .90, .56, .82];
    _pathUV(outer, _wallTile);
    _pathUV(const [.20, .16, .86, .16], _wallTile);
    for (final (name, u, v) in const [
      ('Portão Norte', .50, .06),
      ('Portão do Rio', .92, .55),
      ('Portão Sul', .62, .90),
      ('Portão do Field Ward', .55, .16),
    ]) {
      _gateAt(name, u, v);
    }
    bool inCity(int x, int y) =>
        _inPolyUV(const [.10, .06, .86, .06, .92, .30, .92, .78, .62, .90, .45, .80, .25, .72, .10, .60], x, y) &&
        !city.water.at(x, y) &&
        !mount(x, y);
    // avenidas
    for (final rd in const [
      [.50, .06, .50, .40, .55, .60, .62, .90],
      [.25, .40, .50, .40, .92, .55],
      [.30, .62, .55, .60, .92, .30],
    ]) {
      _pathUV(rd, (x, y) {
        if (inCity(x, y)) _roadTile(x, y);
      });
    }
    // Cidade dos Mortos: cemitério murado a leste
    const dead = [.76, .30, .90, .30, .90, .52, .76, .52];
    _pathUV([...dead, dead[0], dead[1]], _wallTile);
    _gateAt('Cidade dos Mortos', .76, .41);
    bool cemetery(int x, int y) => _inPolyUV(dead, x, y) && !city.walls.at(x, y);
    _propsIn(cemetery, PropType.grave, .3);
    _propsIn(cemetery, PropType.tree, .1);
    _landmarkAt(BuildingKind.temple, 'Mausoléu', .83, .42);
    bool w(double u0, double v0, double u1, double v1, int x, int y) =>
        inCity(x, y) && _inRectUV(u0, v0, u1, v1, x, y) && !cemetery(x, y);
    _ward('Field Ward', (x, y) => w(.14, .07, .86, .155, x, y), _kPoor, step: 4, density: .9, lu: .66, lv: .11);
    _ward('Sea Ward', (x, y) => w(.20, .17, .50, .38, x, y), _kNoble, step: 6, density: .75, lu: .34, lv: .26,
        names: const {BuildingKind.temple: ['Templo de Selûne', 'Templo de Lathander', 'Torre do Báculo Negro']});
    _ward('North Ward', (x, y) => w(.50, .17, .88, .30, x, y), [..._kNoble, const KindWeight(BuildingKind.timber, 2)],
        step: 6, density: .75, lu: .68, lv: .24);
    _landmarkAt(BuildingKind.timber, 'Portal Escancarado (Yawning Portal)', .32, .45);
    _landmarkAt(BuildingKind.manor, 'Palácio de Waterdeep', .38, .52);
    _ward('Castle Ward', (x, y) => w(.24, .38, .50, .60, x, y),
        [const KindWeight(BuildingKind.manor, 3), const KindWeight(BuildingKind.tallHouse, 3), const KindWeight(BuildingKind.tower, 1)],
        step: 5, lu: .40, lv: .46);
    _ward('Trades Ward', (x, y) => w(.50, .30, .76, .60, x, y), _kTrade, step: 4, density: .9, lu: .62, lv: .45,
        names: const {BuildingKind.tallHouse: ['Casa de guilda', 'Casa de câmbio', 'Armazém', 'Loja de magia']});
    _ward('Southern Ward', (x, y) => w(.55, .60, .92, .88, x, y),
        [const KindWeight(BuildingKind.barn, 3), const KindWeight(BuildingKind.cottage, 3), const KindWeight(BuildingKind.timber, 2)],
        step: 5, lu: .74, lv: .72, names: const {BuildingKind.barn: ['Estábulo de caravanas', 'Armazém', 'Cocheira']});
    _ward('Dock Ward', (x, y) => w(.22, .60, .58, .86, x, y), _kDocks, step: 4, density: .9, lu: .42, lv: .70,
        names: const {BuildingKind.barn: ['Estaleiro', 'Armazém do porto'], BuildingKind.timber: ['Taverna do cais', 'Peixaria']});
    _labelBuildings(const ['Castelo Waterdeep', 'Portal Escancarado (Yawning Portal)', 'Palácio de Waterdeep']);
    // docas e barcos no porto
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (city.water.at(x, y) && !city.water.at(x, y - 1) && x % 3 == 0 &&
            _inDisc(.30, .90, .27, .15, x, y)) {
          _addPropForce(PropType.dock, x, y);
        }
      }
    }
    for (final (u, v) in const [(.20, .85), (.32, .95), (.40, .92), (.05, .70)]) {
      final (x, y) = _t(u, v);
      if (city.water.at(x, y)) _addPropForce(PropType.boat, x, y);
    }
    // fora da muralha: campo e mata
    _fieldsIn((x, y) => !inCity(x, y) && (x + .5) / n > .9, const [CropType.wheat, CropType.pasture]);
    _forestIn((x, y) => !inCity(x, y), .3);
  }

  /// Baldur's Gate: o Rio Chionthar ao sul, o Porto Cinzento (Gray Harbor) entrando na cidade,
  /// a Cidade Alta murada ao norte (ricos, o High Hall), a Cidade Baixa em crescente em volta do
  /// porto (muralha mais nova), a Cidade de Fora sem muralha (barracos, cercados e estábulos),
  /// o Portão Basilisco a leste, a Rocha do Wyrm no rio com as pontes e Rivington na outra margem.
  void _baldursGate() {
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        final u = (x + .5) / n, v = (y + .5) / nY;
        final river = (v - (.80 + .03 * sin(u * 8))).abs() < .055;
        final harbor = _inDisc(.42, .70, .11, .09, x, y);
        if (river || harbor) _waterTile(x, y);
      }
    }
    _label('Rio Chionthar', _u(.15), _v(.80));
    _label('Porto Cinzento', _u(.42), _v(.70));
    // Rocha do Wyrm e as pontes
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (_inDisc(.74, .80, .035, .04, x, y)) {
          city.water.set(x, y, false);
          occupied.set(x, y, false);
        }
      }
    }
    _landmarkAt(BuildingKind.castle, 'Rocha do Wyrm (Punho Flamejante)', .72, .78);
    _pathUV(const [.74, .70, .74, .76], (x, y) => _roadTile(x, y));
    _pathUV(const [.74, .84, .74, .95], (x, y) => _roadTile(x, y));
    _labelBuildings(const ['Rocha do Wyrm (Punho Flamejante)']);
    // muralhas
    const upper = [.28, .08, .70, .08, .72, .40, .26, .40];
    const lower = [.18, .38, .26, .40, .72, .40, .82, .42, .80, .74, .20, .74];
    _pathUV([...upper, upper[0], upper[1]], _wallTile);
    _pathUV([.26, .40, .18, .40, .18, .74], _wallTile);
    _pathUV([.72, .40, .82, .40, .82, .74], _wallTile);
    _gateAt('Portão Basilisco', .82, .58);
    _gateAt('Portão da Cidade Alta', .50, .40);
    _gateAt('Portão do Rio', .18, .58);
    _gateAt('Portão Norte', .50, .08);
    bool upperC(int x, int y) => _inPolyUV(upper, x, y) && !city.walls.at(x, y);
    bool lowerC(int x, int y) =>
        _inPolyUV(lower, x, y) && !upperC(x, y) && !city.walls.at(x, y) && !city.water.at(x, y);
    _pathUV(const [.50, .08, .50, .62], (x, y) => _roadTile(x, y));
    _pathUV(const [.18, .58, .82, .58, 1.0, .58], (x, y) => _roadTile(x, y));
    _label('Caminho do Comércio', _u(.93), _v(.56));
    _landmarkAt(BuildingKind.manor, 'High Hall', .50, .20);
    _landmarkAt(BuildingKind.temple, 'Templo de Gond', .62, .30);
    _clearPlaza(.33, .48, .40, .55);
    _label('O Amplo (The Wide)', _u(.36), _v(.51));
    _landmarkAt(BuildingKind.timber, 'Elfsong Tavern', .30, .64);
    _ward('Cidade Alta', upperC, _kNoble, step: 6, density: .75, lu: .38, lv: .15,
        names: const {BuildingKind.temple: ['Templo de Gond', 'Templo de Tymora']});
    _ward('Cidade Baixa', lowerC, [..._kTrade, ..._kPoor], step: 4, density: .9, lu: .64, lv: .52,
        names: const {BuildingKind.tallHouse: ['Casa de guilda', 'Sobrado estreito', 'Casa de câmbio']});
    _labelBuildings(const ['High Hall', 'Templo de Gond', 'Elfsong Tavern']);
    // Cidade de Fora: sem muralha, barracos e cercados
    bool outer(int x, int y) =>
        !_inPolyUV(lower, x, y) && !_inPolyUV(upper, x, y) && !city.water.at(x, y) &&
        ((x + .5) / n > .84 || (x + .5) / n < .16) && (y + .5) / nY > .3 && (y + .5) / nY < .74;
    _ward('Cidade de Fora', outer, [
      const KindWeight(BuildingKind.cottage, 5),
      const KindWeight(BuildingKind.barn, 2),
    ], step: 6, density: .45, lu: .92, lv: .40);
    _fieldsIn((x, y) => outer(x, y) && r.nextDouble() < .6, const [CropType.pasture]);
    // Rivington, na margem sul
    bool riv(int x, int y) => _inRectUV(.55, .87, .95, 1.0, x, y) && !city.water.at(x, y);
    _ward('Rivington', riv, _kPoor, step: 5, density: .55, lu: .85, lv: .93);
    // docas
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (city.water.at(x, y) && !city.water.at(x, y - 1) && x % 3 == 1 &&
            _inDisc(.42, .70, .12, .10, x, y)) {
          _addPropForce(PropType.dock, x, y);
        }
      }
    }
    for (final (u, v) in const [(.40, .72), (.45, .68), (.30, .81), (.60, .80)]) {
      final (x, y) = _t(u, v);
      if (city.water.at(x, y)) _addPropForce(PropType.boat, x, y);
    }
    _forestIn((x, y) => !_inPolyUV(lower, x, y) && !_inPolyUV(upper, x, y), .2);
  }

  /// Neverwinter, a Joia do Norte: o rio quente que nunca congela atravessa a cidade até o mar
  /// (a oeste), com as pontes; o Enclave do Protetor e o Salão da Justiça (templo de Tyr, no
  /// penhasco) ao sul; o Castelo Never em parte arruinado e o distrito de Blacklake com o lago
  /// ao norte; o Abismo (Chasm) selado a leste; o Monte Hotenow ao fundo.
  void _neverwinter() {
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        final u = (x + .5) / n, v = (y + .5) / nY;
        final sea = u < .07 + .02 * sin(v * 10);
        final river = (v - (.50 + .06 * sin(u * 5))).abs() < .03;
        final lake = _inDisc(.36, .28, .06, .06, x, y);
        if (sea || river || lake) _waterTile(x, y);
      }
    }
    _label('Rio Neverwinter', _u(.55), _v(.52));
    _label('Mar das Espadas', _u(.03), _v(.2));
    _label('Lago Negro', _u(.36), _v(.28));
    const wall = [.10, .10, .80, .10, .88, .40, .86, .86, .10, .88];
    _pathUV([...wall, wall[0], wall[1]], _wallTile);
    for (final (name, u, v) in const [
      ('Portão do Rio', .87, .52),
      ('Portão Norte', .45, .10),
      ('Portão Sul', .48, .87),
    ]) {
      _gateAt(name, u, v);
    }
    bool inCity(int x, int y) => _inPolyUV(wall, x, y) && !city.water.at(x, y) && !city.walls.at(x, y);
    for (final (name, u) in const [
      ('Ponte do Golfinho', .25),
      ('Ponte do Wyvern Alado', .45),
      ('Ponte do Dragão Adormecido', .68),
    ]) {
      _pathUV([u, .40, u, .60], (x, y) => _roadTile(x, y));
      _label(name, _u(u), _v(.47));
    }
    _pathUV(const [.10, .70, .86, .70], (x, y) {
      if (inCity(x, y) || city.road.at(x, y)) _roadTile(x, y);
    });
    _pathUV(const [.12, .30, .80, .30], (x, y) {
      if (inCity(x, y)) _roadTile(x, y);
    });
    // Abismo selado: fenda de ruínas e pedras
    bool chasm(int x, int y) => _inDisc(.68, .30, .08, .12, x, y) && inCity(x, y);
    _propsIn(chasm, PropType.ruin, .35);
    _propsIn(chasm, PropType.mesa, .15);
    _label('O Abismo (selado)', _u(.68), _v(.30));
    // Castelo Never, em parte arruinado
    _landmarkAt(BuildingKind.castle, 'Castelo Never', .22, .30);
    _propsIn((x, y) => _inDisc(.24, .32, .07, .08, x, y) && inCity(x, y), PropType.ruin, .25);
    _landmarkAt(BuildingKind.temple, 'Salão da Justiça (Tyr)', .14, .62);
    _landmarkAt(BuildingKind.manor, 'Paço do Lorde Protetor', .42, .66);
    _labelBuildings(const ['Castelo Never', 'Salão da Justiça (Tyr)', 'Paço do Lorde Protetor']);
    _ward('Blacklake', (x, y) => inCity(x, y) && _inRectUV(.28, .12, .55, .44, x, y), _kNoble,
        step: 6, density: .7, lu: .45, lv: .18);
    _ward('Enclave do Protetor', (x, y) => inCity(x, y) && _inRectUV(.12, .56, .62, .86, x, y),
        [..._kTrade, ..._kNoble], step: 5, density: .85, lu: .32, lv: .78);
    _ward('Distrito do Rio', (x, y) => inCity(x, y) && !chasm(x, y) && _inRectUV(.55, .12, .88, .48, x, y),
        _kPoor, step: 5, density: .55, lu: .80, lv: .20);
    _ward('Distrito Leste', (x, y) => inCity(x, y) && _inRectUV(.62, .56, .88, .86, x, y), _kTrade,
        step: 5, density: .75, lu: .76, lv: .80);
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (city.water.at(x, y) && !city.water.at(x + 1, y) && (x + .5) / n < .12 && y % 4 == 0) {
          _addPropForce(PropType.dock, x, y);
        }
      }
    }
    // Monte Hotenow a nordeste e a Floresta de Neverwinter
    _propsIn((x, y) => _inRectUV(.80, 0, 1, .12, x, y) && !city.walls.at(x, y), PropType.mountain, .5);
    _label('Monte Hotenow', _u(.92), _v(.05));
    _forestIn((x, y) => !_inPolyUV(wall, x, y), .6);
  }

  /// Phandalin: vila de fronteira refeita sobre as ruínas da antiga, sem muralha, no cruzamento
  /// da Trilha de Triboar; Stonehill Inn, Barthen's Provisions, Lionshield Coster, Salão do
  /// Mestre da Vila, Santuário da Sorte, Sleeping Giant, Fazenda Alderleaf, Pomar de Edermath e as
  /// ruínas da Mansão Tresendar no morro a leste. A Floresta de Neverwinter ao norte.
  void _phandalin() {
    _pathUV(const [.0, .55, .30, .52, .50, .50, .75, .48, 1.0, .45], (x, y) => _roadTile(x, y, dirt: true));
    _pathUV(const [.48, .0, .50, .30, .50, .50, .52, .75, .50, 1.0], (x, y) => _roadTile(x, y, dirt: true));
    _label('Trilha de Triboar', _u(.10), _v(.52));
    _pathUV(const [.62, .49, .72, .38, .80, .32], (x, y) => _roadTile(x, y, dirt: true));
    _clearPlaza(.45, .45, .55, .55);
    final (wx, wy) = _t(.50, .50);
    _addPropForce(PropType.well, wx, wy);
    const places = [
      ('Stonehill Inn', BuildingKind.timber, .40, .44),
      ("Barthen's Provisions", BuildingKind.timber, .56, .42),
      ('Lionshield Coster', BuildingKind.timber, .58, .55),
      ('Salão do Mestre da Vila', BuildingKind.manor, .42, .57),
      ('Santuário da Sorte (Tymora)', BuildingKind.temple, .62, .44),
      ('Sleeping Giant', BuildingKind.timber, .70, .58),
      ('Fazenda Alderleaf', BuildingKind.barn, .26, .66),
      ('Pomar de Edermath', BuildingKind.cottage, .30, .30),
      ('Companhia dos Mineiros', BuildingKind.timber, .38, .36),
    ];
    for (final (name, kind, u, v) in places) {
      _landmarkAt(kind, name, u, v);
    }
    _labelBuildings([for (final p in places) p.$1]);
    bool town(int x, int y) => _inDisc(.50, .50, .2, .2, x, y);
    _packIn(town, const [
      KindWeight(BuildingKind.cottage, 5),
      KindWeight(BuildingKind.timber, 1.5),
      KindWeight(BuildingKind.barn, .6),
    ], density: .1);
    // ruínas da antiga Phandalin espalhadas e a Mansão Tresendar no morro
    _propsIn((x, y) => _inDisc(.50, .50, .32, .32, x, y), PropType.ruin, .025);
    _landmarkAt(BuildingKind.manor, 'Ruínas da Mansão Tresendar', .82, .30);
    _propsIn((x, y) => _inDisc(.82, .30, .08, .08, x, y), PropType.ruin, .3);
    _labelBuildings(const ['Ruínas da Mansão Tresendar']);
    _fieldsIn((x, y) => _inDisc(.28, .68, .12, .1, x, y), const [CropType.wheat, CropType.vegetables, CropType.pasture]);
    _fieldsIn((x, y) => _inDisc(.30, .28, .07, .06, x, y), const [CropType.orchard]);
    _label('Phandalin', _u(.50), _v(.40));
    _forestIn((x, y) => (y + .5) / nY < .18, .85);
    _label('Floresta de Neverwinter', _u(.25), _v(.06));
    _forestIn((x, y) => !_inDisc(.50, .50, .38, .40, x, y), .3);
    _propsIn((x, y) => _inDisc(.50, .50, .3, .3, x, y), PropType.sheep, .006);
  }

  /// Bryn Shander, a maior das Dez Cidades do Vale do Vento Gélido: cidade murada num morro, na
  /// neve, entre os três lagos (Maer Dualdon a noroeste, Lac Dinneshere a leste e Redwaters ao
  /// sul), com o Monte de Kelvin (Kelvin's Cairn) a nordeste e estradas para as outras cidades.
  void _brynShander() {
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        final lakes = _inDisc(.12, .18, .18, .20, x, y) ||
            _inDisc(.92, .45, .14, .22, x, y) ||
            _inDisc(.50, 1.02, .22, .12, x, y);
        if (lakes) _waterTile(x, y);
      }
    }
    _label('Maer Dualdon', _u(.10), _v(.14));
    _label('Lac Dinneshere', _u(.92), _v(.45));
    _label('Redwaters', _u(.50), _v(.95));
    _propsIn((x, y) => _inRectUV(.70, 0, 1, .2, x, y), PropType.mountain, .5);
    _label("Monte de Kelvin (Kelvin's Cairn)", _u(.86), _v(.06));
    // muralha redonda no morro
    final pts = <double>[];
    for (var a = 0.0; a < 2 * pi; a += pi / 14) {
      pts..add(.48 + cos(a) * .18)..add(.48 + sin(a) * .2);
    }
    _pathUV([...pts, pts[0], pts[1]], _wallTile);
    _gateAt('Portão Norte', .48, .28);
    _gateAt('Portão Sul', .48, .68);
    _gateAt('Portão Oeste', .30, .48);
    bool town(int x, int y) => _inDisc(.48, .48, .17, .19, x, y) && !city.walls.at(x, y);
    for (final rd in const [
      [.48, .28, .48, .68],
      [.30, .48, .48, .48],
      [.48, .28, .30, .0],
      [.48, .68, .60, .9, .70, 1.0],
      [.30, .48, .0, .55],
      [.48, .48, .66, .40, 1.0, .25],
    ]) {
      _pathUV(rd, (x, y) => _roadTile(x, y, dirt: !town(x, y)));
    }
    _clearPlaza(.45, .45, .51, .51);
    _label('Bryn Shander', _u(.48), _v(.40));
    _landmarkAt(BuildingKind.manor, 'Salão do Porta-Voz', .52, .52);
    _landmarkAt(BuildingKind.timber, 'Northlook (estalagem)', .42, .54);
    _landmarkAt(BuildingKind.temple, 'Templo da Senhora da Manhã', .54, .40);
    _labelBuildings(const ['Salão do Porta-Voz', 'Northlook (estalagem)', 'Templo da Senhora da Manhã']);
    _packIn(town, const [
      KindWeight(BuildingKind.cottage, 5),
      KindWeight(BuildingKind.timber, 3),
      KindWeight(BuildingKind.barn, .6),
    ], density: .8, names: const {
      BuildingKind.cottage: ['Casa de pedra', 'Casa do caçador', 'Casa do pescador'],
    });
    // vilas de pescadores nas margens (as outras das Dez Cidades)
    for (final (name, u, v) in const [
      ('Termalaine', .22, .40),
      ('Easthaven', .80, .62),
      ('Targos', .30, .10),
      ('Caer-Dineval', .80, .30),
    ]) {
      bool hamlet(int x, int y) => _inDisc(u, v, .05, .05, x, y);
      _packIn(hamlet, const [KindWeight(BuildingKind.cottage, 1)], density: .5);
      _label(name, _u(u), _v(v));
    }
    _forestIn((x, y) => !_inDisc(.48, .48, .25, .27, x, y), .12);
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < nY; y++) {
        if (city.water.at(x, y) && !city.water.at(x, y - 1) && (x * 7 + y) % 11 == 0) {
          _addPropForce(PropType.boat, x, y);
        }
      }
    }
  }
}

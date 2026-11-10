import 'dart:math';
import 'dart:ui';
import '../domain/city_types.dart';
import '../domain/era.dart';
import 'art_profile.dart';

/// Cores do terreno de um assentamento (substituem as do sistema quando informadas).
class TerrainPalette {
  const TerrainPalette({
    required this.grassA,
    required this.grassB,
    required this.road,
    required this.plaza,
    required this.soil,
  });
  final Color grassA, grassB, road, plaza, soil;
}

/// Bairro de uma cidade, com estilo próprio (construções, cores, árvores e nomes). O bairro ocupa
/// os quarteirões do setor [fromDeg]..[toDeg] (ângulo no plano dos tiles a partir do centro:
/// 0° = eixo x, 90° = eixo y; o intervalo pode dar a volta em 360°) ou o miolo, se [core].
class DistrictSpec {
  const DistrictSpec({
    required this.name,
    required this.kinds,
    this.fromDeg = 0,
    this.toDeg = 0,
    this.core = false,
    this.u,
    this.v,
    this.names = const {},
    this.wallColors,
    this.roofColors,
    this.trees,
    this.filler,
    this.density = 1,
    this.canals = false,
    this.showLabel = true,
    this.population,
  });
  final String name;

  /// Quem mora no bairro (raças com pesos); sem isso, a população da cidade.
  final List<PropWeight>? population;

  /// Âncora no mapa, em unidades da elipse da cidade (u: -1 oeste a +1 leste; v: -1 norte a +1 sul).
  /// Cada quarteirão fica no bairro de âncora mais próxima (manchas como num mapa de bairros).
  final double? u, v;

  /// Objetos de enchimento do bairro (túmulos no cemitério, barracas na praça de diversões...).
  final List<PropWeight>? filler;

  /// Quanto do bairro é construído (0 a 1): parques e ruínas deixam o chão livre.
  final double density;

  /// Canais de água cortando o bairro (Cidade da Praia).
  final bool canals;

  /// Mostra o nome no mapa (os bairros de enchimento ficam sem rótulo).
  final bool showLabel;
  final List<KindWeight> kinds;
  final double fromDeg, toDeg;
  final bool core;
  final Map<BuildingKind, List<String>> names;
  final List<Color>? wallColors, roofColors;
  final List<PropType>? trees;

  bool covers(double deg) => fromDeg <= toDeg
      ? deg >= fromDeg && deg < toDeg
      : deg >= fromDeg || deg < toDeg;
}

/// Marco extra de uma cidade (estátua colossal, arena...), num quarteirão do setor [angleDeg].
/// Com [pond], um lago circular em volta (a estátua de Valkaria).
class ExtraBuilding {
  const ExtraBuilding(this.kind, this.name,
      {this.angleDeg, this.u, this.v, this.pond = false, this.minBlocks = 0});
  final BuildingKind kind;

  /// Só entra se a cidade tiver ao menos este número de quarteirões (nas pequenas não sobra lugar).
  final int minBlocks;
  final String name;
  final double? angleDeg;

  /// Posição desejada na elipse da cidade (como em [DistrictSpec.u]); vale mais que [angleDeg].
  final double? u, v;
  final bool pond;
}

/// Linha desenhada no mapa (aqueduto, canal), em pontos da elipse da cidade (u, v pares).
class PathSpec {
  const PathSpec(this.name, this.uv, {this.label = true});
  final String name;
  final List<double> uv;
  final bool label;
}

/// Cidade com traçado próprio, desenhado a partir de um mapa oficial.
enum MapLayout { none, malpetrim, smokestone, norba, samburdia, malaren, boulder, mercer, waterdeep, baldursGate, neverwinter, phandalin, brynShander }

/// O traçado próprio vale nos modos de cidade (e, na vila de Norba, também em "Só floresta").
bool usesLayout(SettlementType st, SettlementMode mode) =>
    st.layout != MapLayout.none &&
    (mode == SettlementMode.cityOnly ||
        mode == SettlementMode.cityWithFarms ||
        (mode == SettlementMode.forestOnly && st.layout == MapLayout.norba));

/// Portão de uma muralha oval: nome e posição na elipse (u: oeste/leste, v: norte/sul).
class GateSpec {
  const GateSpec(this.name, this.u, this.v);
  final String name;
  final double u, v;
}

/// Tipo de assentamento de um cenário (capital, cidade voadora, fazendas ao redor do Loop...).
/// Só dados: o gerador e o renderizador interpretam cada campo.
class SettlementType {
  const SettlementType({
    required this.id,
    required this.name,
    required this.lore,
    this.kinds,
    this.landmark,
    this.farmHouse,
    this.farmBarn,
    this.trees,
    this.noLandmark = false,
    this.landmarkChance = 1,
    this.names = const {},
    this.terrain,
    this.wallColors,
    this.roofColors,
    this.water = WaterLayout.none,
    this.walls = false,
    this.divisions,
    this.districts,
    this.extras = const [],
    this.gateNames,
    this.oval = false,
    this.gates,
    this.statueRadius,
    this.minTiles,
    this.noZone = false,
    this.river,
    this.chaotic = false,
    this.ovalRiver = false,
    this.ovalRatio = .62,
    this.layout = MapLayout.none,
    this.mapRatio = 1,
    this.aqueducts = const [],
    this.spirals = const [],
    this.radialStreets = 0,
    this.island = false,
    this.centerWater = true,
    this.population,
    this.wallStone,
    this.wallRoof,
    this.floating = false,
    this.defaultMode = SettlementMode.cityWithFarms,
    this.crops = const [
      CropType.wheat,
      CropType.corn,
      CropType.pasture,
      CropType.vegetables
    ],
    this.farmShare = .5,
    this.filler,
    this.street,
    this.wildZone,
    this.era,
    this.buildDensity = 1,
    this.cityShare = .55,
    this.varied = false,
  });

  final String id, name;

  /// Descrição do lugar e a origem da informação (para o mestre e para conferir no livro).
  final String lore;

  /// Substituem os do perfil do sistema quando não nulos.
  final List<KindWeight>? kinds;
  final BuildingKind? landmark;

  /// Casa e celeiro dos sítios deste lugar. Sem isso, usa os da época. Servem para o campo seguir
  /// o mesmo estilo da cidade (casa oriental em Nitamurá, chalé falu em Mälaren...).
  final BuildingKind? farmHouse, farmBarn;

  /// Árvores do lugar (cerejeiras em Nitamurá). Sem isso, usa as do sistema.
  final List<PropType>? trees;
  final bool noLandmark;

  /// Chance (0 a 1) de a cidade ter o destaque. Nem toda cidade tem castelo: varia de uma para outra.
  final double landmarkChance;
  final Map<BuildingKind, List<String>> names;
  final TerrainPalette? terrain;

  /// Cores de parede e telhado do lugar (substituem as do sistema quando informadas).
  final List<Color>? wallColors, roofColors;
  final WaterLayout water;
  final bool walls;

  /// Divisões internas da cidade murada. Sem isso, cidade com castelo ganha só a cidadela.
  /// Cada tipo respeita a sua lore (Waterdeep: cidadela e docas; Baldur's Gate: cidade alta e baixa).
  final List<Division>? divisions;

  /// Bairros com estilo próprio (Valkaria: Nitamu-ra, Vila Élfica, Favela dos Goblins...).
  final List<DistrictSpec>? districts;

  /// Quem mora na cidade (raças com pesos, pela lore); sem isso, a demografia do cenário.
  final List<PropWeight>? population;

  /// Marcos extras além do destaque (estátua colossal, arena).
  final List<ExtraBuilding> extras;

  /// Nomes dos portões, na ordem norte, leste, sul, oeste.
  final List<String>? gateNames;

  /// Cidade oval (como Valkaria): muralha em elipse, portões em [gates], mapa retangular e
  /// uma praça circular no centro com lagos concêntricos e a estátua colossal.
  final bool oval;
  final List<GateSpec>? gates;

  /// Raio (em blocos) do conjunto central da cidade oval: estátua, lago e praça.
  final double? statueRadius;

  /// Tamanho mínimo do mapa em blocos (cidades grandes não cabem nos tamanhos pequenos).
  final int? minTiles;

  /// Sem área especial nesta cidade (Valkaria não tem Área da Tormenta).
  final bool noZone;

  /// Rio atravessando o mapa: true sempre, false nunca, sem valor (null) sorteia pela semente.
  final bool? river;

  /// Traçado bagunçado (Pondsmânia): ruas que somem, poças e muitas flores e luzes.
  final bool chaotic;

  /// Cidade oval com rio vindo do canto noroeste, passando pela praia até o lago central, e uma baía no canto.
  final bool ovalRiver;

  /// Altura do mapa da cidade oval em relação à largura (1 = círculo, num mapa quadrado).
  final double ovalRatio;

  /// Traçado próprio (mapa oficial) e a proporção altura/largura do mapa dele.
  final MapLayout layout;
  final double mapRatio;

  /// Aquedutos e canais (linhas de água de 1 bloco; a muralha passa por cima, as ruas viram ponte).
  final List<PathSpec> aqueducts;

  /// Centros (u, v pares) de espirais de água, como os jardins em espiral da Vila Élfica.
  final List<double> spirals;

  /// Ruas radiais saindo da praça central, e um anel de rua em volta dela.
  final int radialStreets;

  /// Cidade numa ilha flutuante redonda (Vectora): céu em volta, penhasco de rocha embaixo,
  /// Avenida Circular e bosque em volta da muralha, montanha e castelo ao norte, praça de
  /// entrada e ancoradouro ao sul, avenidas em cruz até a praça central.
  final bool island;

  /// A praça central da cidade oval tem lago (Valkaria) ou é só praça (Vectora).
  final bool centerWater;

  /// Cores da muralha (pedra e telhado das torres); sem valor, pedra cinza e telhado vermelho.
  final Color? wallStone, wallRoof;

  /// Cidade sobre uma ilha flutuante (nuvens em volta, sem terra embaixo).
  final bool floating;
  final SettlementMode defaultMode;
  final List<CropType> crops;

  /// Fração das terras livres ao redor que viram fazendas (0..1).
  final double farmShare;
  final List<PropWeight>? filler, street;

  /// Se informado, liga/desliga a área especial por padrão para este tipo.
  final bool? wildZone;

  /// Época do lugar, quando difere da do cenário (ex.: cidade de faroeste num mundo de fantasia).
  final Era? era;

  /// Quanto dos lotes vira construção (1 = todos; menos = cidade mais espaçada).
  final double buildDensity;

  /// Quanto do mapa é cidade no modo "Cidade + fazendas" (o resto é campo).
  final double cityShare;

  /// Cidade genérica que muda de cara a cada semente (água, muralha, marco, cores, construções).
  final bool varied;

  /// Uma variação sorteada deste tipo (para os tipos [varied]).
  SettlementType variation(Random r) {
    T pick<T>(List<T> l) => l[r.nextInt(l.length)];
    const palettes = [
      ([Color(0xFFF4E3C3), Color(0xFFE8D2A8), Color(0xFFF2EAD8)],
          [Color(0xFFB0472F), Color(0xFF8E3B2A), Color(0xFF6B4A3A)]),
      ([Color(0xFFE7E3DA), Color(0xFFD6D2C8), Color(0xFFC9C3B6)],
          [Color(0xFF3F4650), Color(0xFF55606B), Color(0xFF2F3A44)]),
      ([Color(0xFFF2E6C8), Color(0xFFE0CFA0), Color(0xFFD8C08A)],
          [Color(0xFFCFAE62), Color(0xFFB8964E), Color(0xFF9C7A3A)]),
      ([Color(0xFFEAD7C4), Color(0xFFDCC3AC), Color(0xFFF0E1CF)],
          [Color(0xFF4F7A5A), Color(0xFF3E6A4C), Color(0xFF6B8E5A)]),
      ([Color(0xFFF3EEE4), Color(0xFFE6DDCC), Color(0xFFD9CFBC)],
          [Color(0xFF3F5E8A), Color(0xFF4A5A70), Color(0xFF8E3B2A)]),
    ];
    const mixes = [
      [KindWeight(BuildingKind.timber, 5), KindWeight(BuildingKind.cottage, 2), KindWeight(BuildingKind.tallHouse, 2), KindWeight(BuildingKind.temple, .8)],
      [KindWeight(BuildingKind.cottage, 6), KindWeight(BuildingKind.timber, 2), KindWeight(BuildingKind.barn, 1), KindWeight(BuildingKind.windmill, .6)],
      [KindWeight(BuildingKind.tallHouse, 5), KindWeight(BuildingKind.manor, 2), KindWeight(BuildingKind.temple, 1), KindWeight(BuildingKind.tower, 1)],
      [KindWeight(BuildingKind.timber, 3), KindWeight(BuildingKind.manor, 3), KindWeight(BuildingKind.church, 1), KindWeight(BuildingKind.tower, .6)],
      [KindWeight(BuildingKind.cottage, 4), KindWeight(BuildingKind.timber, 3), KindWeight(BuildingKind.temple, 1), KindWeight(BuildingKind.tower, .8)],
    ];
    // tipos com sobrados sorteiam entre cidade (grande) e vila (pequena, mais campo)
    final big = (kinds?.any((k) => k.kind == BuildingKind.tallHouse) ?? false) &&
        r.nextDouble() < .55;
    final palette = pick(palettes);
    final water = pick(const [
      WaterLayout.none, WaterLayout.river, WaterLayout.lake, WaterLayout.coast,
    ]);
    final mix = big ? pick(mixes) : pick([mixes[1], mixes[4], mixes[0]]);
    final walled = big && r.nextDouble() < .5;
    return SettlementType(
      id: id,
      name: name,
      lore: lore,
      kinds: [
        ...mix,
        if (kinds != null)
          for (final k in kinds!)
            if (!mix.any((m) => m.kind == k.kind)) KindWeight(k.kind, k.weight * .3),
      ],
      landmark: big ? pick(const [BuildingKind.castle, BuildingKind.church, BuildingKind.temple, BuildingKind.tower]) : landmark,
      noLandmark: !big && r.nextDouble() < .5 ? true : noLandmark,
      landmarkChance: big ? .75 : landmarkChance,
      names: names,
      terrain: terrain,
      wallColors: palette.$1,
      roofColors: palette.$2,
      water: water,
      walls: walled,
      river: water == WaterLayout.none ? r.nextBool() : false,
      defaultMode: defaultMode,
      crops: crops,
      farmShare: big ? .2 + r.nextDouble() * .4 : .6 + r.nextDouble() * .35,
      filler: filler,
      street: street,
      wildZone: wildZone,
      era: era,
      trees: pick(const [
        [PropType.tree], [PropType.pine], [PropType.tree, PropType.pine], [PropType.tree, PropType.tree, PropType.pine],
      ]),
      buildDensity: big ? .7 + r.nextDouble() * .3 : .35 + r.nextDouble() * .3,
    );
  }

  static const standard = SettlementType(
    id: 'padrao',
    name: 'Cidade comum',
    lore: 'Cidade genérica do cenário, sem particularidades.',
    landmarkChance: .5,
  );
}

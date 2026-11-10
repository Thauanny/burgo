/// Formato do telhado de uma construção.
enum RoofType { gable, flat, pyramid }

/// Tipos de objeto que podem ser colocados no mapa.
enum PropType {
  tree,
  pine,
  bush,
  well,
  fountain,
  stall,
  lamp,
  anomaly,
  // animais
  cow,
  sheep,
  chicken,
  dog,
  horse,
  // vida rural e urbana
  crate,
  barrel,
  hay,
  cart,
  banner,
  statue,
  grave,
  // tecnologia
  robot,
  powerPole,
  dish,
  waterTower,
  car,
  drone,
  vending,
  // fazenda, água e deserto
  scarecrow,
  cactus,
  dock,
  boat,
  airship,
  tractor,
  // piso de baixo
  dungeonEntrance,
  // idade média
  lantern,
  // oriental e élfico
  sakura,
  toro,
  torii,
  elfLamp,

  /// Cargueiro flutuante (Tales from the Loop): navio de carga que paira sobre os campos.
  freighter,

  /// Pico de montanha rochosa (cordilheira de Vectora).
  mountain,

  /// Ilhota de rocha flutuando no céu, com uma árvore.
  skyIsle,

  /// Rocha vermelha alta do deserto (as formações de Smokestone).
  mesa,

  /// Flor gigante colorida (floresta feérica).
  giantFlower,

  /// Luz de fada flutuando (floresta feérica).
  fairyLight,

  /// O Eclipse: orbe negro com anel de luz (o coração do Loop em Mercer).
  eclipse,

  /// Ruína de pedra: pedaço de muro caído com pedras soltas.
  ruin,

  // pessoas: classes
  fighter,
  wizard,
  cleric,
  rogue,
  ranger,
  bard,
  paladin,
  barbarian,
  druid,
  monk,
  warlock,
  sorcerer,
  inventor,
  noble,
  buccaneer,
  knight,
  // pessoas: raças
  raceHuman,
  raceElf,
  raceDwarf,
  raceHalfling,
  raceGnome,
  raceHalfOrc,
  raceTiefling,
  raceDragonborn,
  raceGoblin,
  raceMinotaur,
  raceLefou,
  raceDahllan,
  raceQareen,
  raceOsteon,
  raceTrog,
  raceGolem,
  raceMedusa,
  raceKliren,
  raceMermaid,
  raceSylph,
  raceSuraggel,
  // povo
  peasant,
  merchant,
  guard,
  // povo dos anos 80 (Loop)
  kid,
  adult,
  scientist,
  // monstros
  mGoblin,
  mOrc,
  mSkeleton,
  mTroll,
  mOwlbear,
  mBeholder,
  mDragon,
  mWolf,
  mLefeu,
  mHobgoblin,
  mZombie,
  mSpider,
  mCube,
  mRat,
  /// Fogueira (acampamento de monstros, viajantes).
  campfire,
}

/// Famílias de construção. Cada uma tem desenho, tamanho e andares próprios.
enum BuildingKind {
  /// Casa medieval de camponês: pedra e reboco, telhado de palha ou barro, janelas pequenas.
  cottage,

  /// Casa de bairro (anos 1920 em diante): janelas grandes, telhado de telha.
  house,
  timber,
  barn,
  windmill,
  tower,
  castle,
  temple,
  church,
  manor,
  modern,
  block,
  lab,
  skyscraper,
  farmhouse,
  silo,
  saloon,

  /// Pagode oriental de vários andares (beirais curvos).
  pagoda,

  /// Casa de chá ou dojô: paredes brancas com madeira escura e telhado curvo.
  eastHouse,

  /// Casa élfica: mármore branco, telhado verde em forma de folha.
  elfHouse,

  /// Oficina de goblins e anões: engrenagem, canos e chaminé fumegante.
  workshop,

  /// Casa de cogumelo gigante (floresta feérica).
  mushroom,

  /// Chalé sueco vermelho-falu com cantos brancos.
  faluCabin,

  /// Casa térrea de rancho americano, telhado baixo.
  ranch,

  /// Casa colonial da Nova Inglaterra com telhado mansarda (gambrel).
  gambrel,

  /// Galpão de chapa (industrial).
  warehouse,

  /// Estufa de vidro (hidroponia).
  greenhouse,

  /// Sobrado alto e estreito de cidade portuária.
  tallHouse,

  /// Casa de interior brasileira: alvenaria colorida e telhado cerâmico.
  townHouse,

  /// Estátua colossal de uma divindade, sobre pedestal (Valkaria).
  colossus,

  /// Arena circular de pedra com arcadas.
  arena,

  /// Árvore-morada élfica: tronco gigante com casa de mármore em plataforma e copa enorme.
  elfTree,

  /// Torre élfica esguia de mármore branco, anéis dourados e telhado de folha.
  elfTower,

  /// Torre de resfriamento de concreto (hiperboloide), com vapor e luzes de obstrução verdes.
  coolingTower,

  /// Represa de concreto (como a Hoover), com estrada no topo e torres de captação.
  dam,

  /// Farol de pedra listrado, com a lanterna acesa no alto (portos da Costa da Espada).
  lighthouse,
}

/// Cultivos de uma fazenda.
enum CropType {
  wheat,
  corn,
  vineyard,
  vegetables,
  orchard,
  pasture,
  rice,
  cotton
}

/// O que o gerador cria: cidade com fazendas ao redor, só cidade, só fazendas ou só floresta.
/// Divisões internas de uma cidade murada. Cada tipo de cidade escolhe as suas.
enum Division {
  /// Bairro do castelo, separado do resto por muralha (reinos).
  citadel,

  /// Distrito das docas, entre a muralha interna e o mar (cidades portuárias murada).
  harbor,

  /// Cidade alta e cidade baixa, separadas por uma muralha com portões (como Baldur's Gate).
  upperLower,
}

enum SettlementMode {
  cityWithFarms,
  cityOnly,
  farmsOnly,
  forestOnly,

  /// Terreno vazio do bioma escolhido (água, árvores, pedras), sem construções nem ruas,
  /// para o usuário construir do zero.
  blank,
}

/// Onde fica a água no mapa gerado.
enum WaterLayout { none, coast, lake, river }

/// Limites do editor de fazendas.
abstract final class FarmLimits {
  static const int minSide = 2, maxSide = 8;
}

/// Regras de tamanho de cada [BuildingKind] para o gerador.
class BuildingKindSpec {
  const BuildingKindSpec({
    required this.footprints,
    required this.minFloors,
    required this.maxFloors,
    this.roofs = const [RoofType.gable, RoofType.pyramid],
  });

  /// Pares (largura, profundidade) possíveis.
  final List<(int, int)> footprints;
  final int minFloors, maxFloors;
  final List<RoofType> roofs;

  static const Map<BuildingKind, BuildingKindSpec> all = {
    BuildingKind.cottage: BuildingKindSpec(
        footprints: [(2, 2), (2, 2), (3, 2), (2, 3)],
        minFloors: 1,
        maxFloors: 2,
        roofs: [RoofType.gable, RoofType.pyramid]),
    BuildingKind.house: BuildingKindSpec(
        footprints: [(2, 2), (2, 2), (3, 2), (2, 3), (3, 3)],
        minFloors: 1,
        maxFloors: 2),
    BuildingKind.timber: BuildingKindSpec(
        footprints: [(2, 2), (3, 2), (2, 3), (3, 3)],
        minFloors: 2,
        maxFloors: 3),
    BuildingKind.barn: BuildingKindSpec(
        footprints: [(3, 2), (2, 3), (3, 3)], minFloors: 1, maxFloors: 1),
    BuildingKind.windmill: BuildingKindSpec(
        footprints: [(2, 2)],
        minFloors: 3,
        maxFloors: 4,
        roofs: [RoofType.pyramid]),
    BuildingKind.tower: BuildingKindSpec(
        footprints: [(2, 2)],
        minFloors: 3,
        maxFloors: 5,
        roofs: [RoofType.pyramid]),
    BuildingKind.castle: BuildingKindSpec(
        footprints: [(4, 4)],
        minFloors: 3,
        maxFloors: 4,
        roofs: [RoofType.flat]),
    BuildingKind.temple: BuildingKindSpec(
        footprints: [(3, 3), (3, 2), (2, 3)], minFloors: 2, maxFloors: 3),
    BuildingKind.church: BuildingKindSpec(
        footprints: [(2, 3), (3, 2), (3, 3)],
        minFloors: 2,
        maxFloors: 2,
        roofs: [RoofType.gable]),
    BuildingKind.manor: BuildingKindSpec(
        footprints: [(3, 2), (2, 3), (3, 3)], minFloors: 2, maxFloors: 3),
    BuildingKind.modern: BuildingKindSpec(
        footprints: [(2, 2), (3, 2), (2, 3), (3, 3)],
        minFloors: 1,
        maxFloors: 3,
        roofs: [RoofType.flat]),
    BuildingKind.block: BuildingKindSpec(
        footprints: [(2, 3), (3, 2), (3, 3)],
        minFloors: 3,
        maxFloors: 5,
        roofs: [RoofType.flat]),
    BuildingKind.lab: BuildingKindSpec(
        footprints: [(3, 3), (4, 4)],
        minFloors: 1,
        maxFloors: 2,
        roofs: [RoofType.flat]),
    BuildingKind.farmhouse: BuildingKindSpec(
        footprints: [(2, 2), (3, 2)], minFloors: 1, maxFloors: 2),
    BuildingKind.saloon: BuildingKindSpec(
        footprints: [(3, 2), (2, 2), (3, 3)],
        minFloors: 2,
        maxFloors: 2,
        roofs: [RoofType.gable]),
    BuildingKind.silo: BuildingKindSpec(
        footprints: [(1, 1)],
        minFloors: 3,
        maxFloors: 4,
        roofs: [RoofType.pyramid]),
    BuildingKind.pagoda: BuildingKindSpec(
        footprints: [(2, 2)],
        minFloors: 3,
        maxFloors: 5,
        roofs: [RoofType.pyramid]),
    BuildingKind.eastHouse: BuildingKindSpec(
        footprints: [(2, 2), (3, 2), (2, 3), (3, 3)],
        minFloors: 1,
        maxFloors: 2,
        roofs: [RoofType.pyramid]),
    BuildingKind.elfHouse: BuildingKindSpec(
        footprints: [(2, 2), (2, 2), (3, 2), (2, 3)],
        minFloors: 1,
        maxFloors: 3,
        roofs: [RoofType.pyramid]),
    BuildingKind.workshop: BuildingKindSpec(
        footprints: [(2, 2), (3, 2), (2, 3), (3, 3)],
        minFloors: 1,
        maxFloors: 2,
        roofs: [RoofType.gable]),
    BuildingKind.mushroom: BuildingKindSpec(
        footprints: [(2, 2), (1, 1), (2, 2), (3, 3)],
        minFloors: 1,
        maxFloors: 4,
        roofs: [RoofType.pyramid]),
    BuildingKind.faluCabin: BuildingKindSpec(
        footprints: [(2, 2), (3, 2), (2, 3)],
        minFloors: 1,
        maxFloors: 2,
        roofs: [RoofType.gable]),
    BuildingKind.ranch: BuildingKindSpec(
        footprints: [(3, 2), (3, 2), (3, 3), (2, 2)],
        minFloors: 1,
        maxFloors: 1,
        roofs: [RoofType.gable]),
    BuildingKind.gambrel: BuildingKindSpec(
        footprints: [(2, 2), (3, 2), (2, 3), (3, 3)],
        minFloors: 2,
        maxFloors: 2,
        roofs: [RoofType.gable]),
    BuildingKind.warehouse: BuildingKindSpec(
        footprints: [(3, 2), (3, 3), (2, 3)],
        minFloors: 1,
        maxFloors: 2,
        roofs: [RoofType.gable]),
    BuildingKind.greenhouse: BuildingKindSpec(
        footprints: [(3, 2), (3, 3), (2, 3)],
        minFloors: 1,
        maxFloors: 1,
        roofs: [RoofType.gable]),
    BuildingKind.tallHouse: BuildingKindSpec(
        footprints: [(2, 2), (2, 2), (2, 3)],
        minFloors: 3,
        maxFloors: 4,
        roofs: [RoofType.gable]),
    BuildingKind.townHouse: BuildingKindSpec(
        footprints: [(2, 2), (3, 2), (2, 3), (3, 3)],
        minFloors: 1,
        maxFloors: 2,
        roofs: [RoofType.pyramid, RoofType.gable]),
    BuildingKind.elfTree: BuildingKindSpec(
        footprints: [(2, 2)],
        minFloors: 3,
        maxFloors: 4,
        roofs: [RoofType.pyramid]),
    BuildingKind.elfTower: BuildingKindSpec(
        footprints: [(2, 2)],
        minFloors: 3,
        maxFloors: 6,
        roofs: [RoofType.pyramid]),
    BuildingKind.lighthouse: BuildingKindSpec(
        footprints: [(1, 1)],
        minFloors: 4,
        maxFloors: 5,
        roofs: [RoofType.pyramid]),
    BuildingKind.coolingTower: BuildingKindSpec(
        footprints: [(3, 3)],
        minFloors: 5,
        maxFloors: 7,
        roofs: [RoofType.flat]),
    BuildingKind.dam: BuildingKindSpec(
        footprints: [(2, 8), (8, 2)],
        minFloors: 3,
        maxFloors: 3,
        roofs: [RoofType.flat]),
    BuildingKind.colossus: BuildingKindSpec(
        footprints: [(7, 7)],
        minFloors: 12,
        maxFloors: 12,
        roofs: [RoofType.flat]),
    BuildingKind.arena: BuildingKindSpec(
        footprints: [(3, 3)],
        minFloors: 2,
        maxFloors: 2,
        roofs: [RoofType.flat]),
    BuildingKind.skyscraper: BuildingKindSpec(
        footprints: [(2, 2), (3, 3), (2, 3)],
        minFloors: 4,
        maxFloors: 6,
        roofs: [RoofType.flat]),
  };

  static BuildingKindSpec of(BuildingKind k) => all[k]!;
}

/// Tamanhos de cidade disponíveis (lado do mapa em tiles).
enum CitySize {
  village(24),
  town(36),
  metropolis(48);

  const CitySize(this.tiles);
  final int tiles;

  static CitySize fromTiles(int tiles) =>
      values.firstWhere((s) => s.tiles == tiles, orElse: () => town);
}

/// Limites do construtor de casas e prédios (fonte única, usada pela UI e pelo editor).
abstract final class BuildingLimits {
  static const int minFloors = 1, maxFloors = 6;
  static const int minSide = 1, maxSide = 4;
}

/// Grupos de bonecos (pessoas e monstros) para o gerador, as ferramentas e o desenho.
abstract final class Figures {
  static const classes = {PropType.fighter, PropType.wizard, PropType.cleric, PropType.rogue, PropType.ranger, PropType.bard, PropType.paladin, PropType.barbarian, PropType.druid, PropType.monk, PropType.warlock, PropType.sorcerer, PropType.inventor, PropType.noble, PropType.buccaneer, PropType.knight};
  static const races = {PropType.raceHuman, PropType.raceElf, PropType.raceDwarf, PropType.raceHalfling, PropType.raceGnome, PropType.raceHalfOrc, PropType.raceTiefling, PropType.raceDragonborn, PropType.raceGoblin, PropType.raceMinotaur, PropType.raceLefou, PropType.raceDahllan, PropType.raceQareen, PropType.raceOsteon, PropType.raceTrog, PropType.raceGolem, PropType.raceMedusa, PropType.raceKliren, PropType.raceMermaid, PropType.raceSylph, PropType.raceSuraggel};
  static const folk = {PropType.peasant, PropType.merchant, PropType.guard};
  static const loopFolk = {PropType.kid, PropType.adult, PropType.scientist};
  static const monsters = {PropType.mGoblin, PropType.mOrc, PropType.mSkeleton, PropType.mTroll, PropType.mOwlbear, PropType.mBeholder, PropType.mDragon, PropType.mWolf, PropType.mLefeu, PropType.mHobgoblin, PropType.mZombie, PropType.mSpider, PropType.mCube, PropType.mRat};

  static bool isPerson(PropType p) =>
      classes.contains(p) || races.contains(p) || folk.contains(p) || loopFolk.contains(p);
  static bool isMonster(PropType p) => monsters.contains(p);
  static bool isFigure(PropType p) => isPerson(p) || isMonster(p);
}

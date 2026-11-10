import '../domain/city_types.dart';
import '../editor/tool.dart';

/// Todos os textos da interface (pt-BR) em um só lugar, para facilitar outros idiomas.
abstract final class Strings {
  static const appTitle = 'Burgo — Gerador de Cidades';
  static const brand = 'Burgo';
  static const tagline = 'Gerador de cidades para RPG, jogos e livros';
  static const rpgSystem = 'Sistema de RPG';
  static const folk = 'Povos e personagens';
  static const adventureHook = 'Gancho de aventura';
  static const sectionCity = 'Cidade';
  static const sectionTools = 'Ferramentas';
  static const sectionSystem = 'Sistema e cenário';
  static const sectionGeneration = 'Geração';
  static const propKind = 'Tipo de objeto';
  static const sectionView = 'Visualização';
  static const mapContent = 'Conteúdo do mapa';
  static const citySizeLabel = 'Tamanho da cidade';
  static const selectedZoneRadius = 'Tamanho da área especial';
  static const zoneRing = 'Raio do tracejado';
  static const newZoneRing = 'Raio do tracejado das novas';
  static const zoneRingFollow = 'Acompanhar o tamanho da área';
  static const placedZones = 'Áreas no mapa';
  static const cityName = 'Nome da cidade';
  static const seed = 'Seed';
  static const generateNew = 'Nova';
  static const newBuildingTemplate = 'Nova construção (modelo)';
  static const selectedBuilding = 'Construção selecionada';
  static const name = 'Nome';
  static const floors = 'Andares';
  static const width = 'Largura';
  static const depth = 'Profundidade';
  static const wall = 'Parede';
  static const roof = 'Telhado';
  static const animations = 'Animações';
  static const levels = 'Pisos';
  static const createLowerFloor = 'Criar piso inferior';
  static const cancel = 'Cancelar';
  static const newLowerFloor = 'Novo piso inferior (masmorra)';
  static const whereEntrance = 'Onde fica a entrada?';
  static const chooseOnMap = 'Escolher no mapa';
  static const clickMapForEntrance =
      'Clique no mapa para posicionar a entrada (aparece o arco com a seta).';
  static const noFreeEntrance = 'Nenhuma entrada livre ainda: escolha no mapa.';
  static const dungeonSize = 'Tamanho da masmorra';
  static const generateDescend = 'Gerar masmorra e descer';
  static const floorUp = 'Piso de cima';
  static const floorDown = 'Piso de baixo';
  static const descend = 'Descer para o piso de baixo';
  static const ascend = 'Subir para o piso de cima';
  static const createDungeonHere = 'Criar piso inferior aqui';
  static const deleteDungeon = 'Apagar a masmorra desta entrada';
  static const entranceHint =
      'Entrada de masmorra: escolha "Entrada de masmorra" em Objetos e clique no mapa.';
  static const scaleTitle = 'Escala e distâncias';
  static const oneBlock = '1 bloco =';
  static const customKm = 'Outro valor (km)';
  static const scaleBar = 'Mostrar régua de escala';
  static const farmGap = 'Distância das fazendas';
  static const zoneRadiusShow = 'Mostrar raio das áreas especiais';
  static const zoneAreas = 'Áreas especiais';
  static const radius = 'Raio';
  static const newZoneRadius = 'Tamanho das novas áreas';
  static const markers = 'Marcadores';
  static const showKm = 'km';
  static const rulers = 'Réguas';
  static const noItems = 'Nada ainda. Use a ferramenta na lista acima.';
  static const fromCenter = 'Distância do centro da cidade';
  static const undo = 'Desfazer';
  static const redo = 'Refazer';
  static const viewIso = 'Isométrica';
  static const viewTop = 'De cima';
  static const view = 'Visão';
  static const newTab = 'Nova aba';
  static const closeTab = 'Fechar aba';
  static const newCity = 'Cidade';
  static const newFarm = 'Fazendas';
  static const newMixed = 'Cidade + fazendas';
  static const newDungeon = 'Masmorra';
  static const file = 'Arquivo';
  static const saveInBrowser = 'Salvar no navegador';
  static const openSaved = 'Abrir projeto salvo…';
  static const exportFile = 'Exportar arquivo (.json)';
  static const exportImageIso = 'Exportar imagem isométrica (.png)';
  static const exportImageTop = 'Exportar imagem de cima (.png)';
  static const importFile = 'Importar arquivo…';
  static const importPaste = 'Importar colando texto…';
  static const copyJson = 'Copiar como texto';
  static const dungeonTitle = 'Nome da masmorra';
  static const rooms = 'Salas';
  static const density = 'Quantidade de salas';
  static const dungeonSystem = 'Estilo (sistema)';
  static const dungeonHelp =
      'Mover mapa: arraste. Escavar/Parede: pinte arrastando.\nPorta, Objeto e Apagar: toque na célula.';
  static const noSaved = 'Nenhum projeto salvo no navegador.';
  static const delete = 'Apagar';
  static const expandArrows = 'Setas para aumentar o mapa';
  static String expandTooltip(int step, int size, {required bool alongX}) =>
      'Aumentar só deste lado em $step blocos (${alongX ? 'largura' : 'profundidade'} hoje: $size)';
  static const expandMax = 'Tamanho máximo atingido';
  static const settlementType = 'Tipo de assentamento';
  static const composition = 'Composição';
  static const farmTemplate = 'Nova fazenda (modelo)';
  static const selectedFarm = 'Fazenda selecionada';
  static const crop = 'Cultivo';
  static const credits = 'Créditos';
  static const chimney = 'Chaminé';
  static const duplicate = 'Duplicar';
  static const remove = 'Remover';
  static const removeProp = 'Remover objeto';
  static const clickToPlace = 'Clique no mapa para posicionar.';
  static const help = 'Arraste para mover o mapa · scroll ou pinça = zoom\n'
      'Clique em algo que já existe (construção, fazenda, objeto) para mover e editar.\n'
      'Selecionar: toque e arraste construções e objetos.\n'
      'Ruas/Área especial: toque ou arraste para pintar e apagar.';

  static String generateZone(String zone) => 'Gerar $zone';

  static String toolLabel(ToolId id, {String? zoneName}) => switch (id) {
        ToolId.pan => 'Mover',
        ToolId.select => 'Selecionar',
        ToolId.road => 'Ruas',
        ToolId.zone => zoneName ?? 'Área especial',
        ToolId.zoneSource =>
          zoneName == null ? 'Área (raio)' : '$zoneName (raio)',
        ToolId.marker => 'Marcador',
        ToolId.ruler => 'Régua',
        ToolId.water => 'Água',
        ToolId.wall => 'Muros',
        ToolId.farm => 'Fazenda',
        ToolId.build => 'Construir',
        ToolId.prop => 'Objetos',
        ToolId.character => 'Personagens',
        ToolId.erase => 'Apagar',
      };

  static String settlementMode(SettlementMode m) => switch (m) {
        SettlementMode.cityWithFarms => 'Cidade + fazendas',
        SettlementMode.cityOnly => 'Só cidade',
        SettlementMode.farmsOnly => 'Só fazendas',
        SettlementMode.forestOnly => 'Só floresta',
        SettlementMode.blank => 'Terreno vazio',
      };

  static String cropName(CropType c) => switch (c) {
        CropType.wheat => 'Trigo',
        CropType.corn => 'Milho',
        CropType.vineyard => 'Vinha',
        CropType.vegetables => 'Horta',
        CropType.orchard => 'Pomar',
        CropType.pasture => 'Pasto',
        CropType.rice => 'Arroz',
        CropType.cotton => 'Algodão',
      };

  static String dungeonTool(String id) => switch (id) {
        'pan' => 'Mover mapa',
        'carve' => 'Escavar',
        'wall' => 'Parede',
        'door' => 'Porta',
        'prop' => 'Objeto',
        _ => 'Apagar',
      };

  static String dungeonProp(String id) => switch (id) {
        'chest' => 'Baú',
        'trap' => 'Armadilha',
        'torch' => 'Tocha',
        'stairsUp' => 'Escada (sobe)',
        'stairsDown' => 'Escada (desce)',
        'altar' => 'Altar',
        'statue' => 'Estátua',
        'barrel' => 'Barril',
        'bones' => 'Ossos',
        'pillar' => 'Pilar',
        'coffin' => 'Caixão',
        'stalagmite' => 'Estalagmites',
        'mushroom' => 'Cogumelos luminosos',
        'web' => 'Teia',
        'puddle' => 'Poça',
        'crystal' => 'Cristais',
        'brazier' => 'Braseiro',
        'skulls' => 'Caveiras',
        'rubble' => 'Entulho',
        'chains' => 'Correntes',
        'crate' => 'Caixote',
        'cage' => 'Jaula',
        'table' => 'Mesa',
        'pipe' => 'Canos',
        'console' => 'Painel de controle',
        'monster' => 'Monstro',
        _ => id,
      };

  static String roomKind(String id) => switch (id) {
        'boss' => 'Chefe',
        'treasure' => 'Tesouro',
        'shrine' => 'Santuário',
        'barracks' => 'Alojamento',
        'crypt' => 'Cripta',
        'cave' => 'Caverna',
        _ => 'Salão',
      };

  static String densityName(String id) => switch (id) {
        'sparse' => 'Poucas',
        'dense' => 'Muitas',
        _ => 'Médias',
      };

  static String buildingKind(BuildingKind k) => switch (k) {
        BuildingKind.cottage => 'Casa medieval',
        BuildingKind.house => 'Casa',
        BuildingKind.timber => 'Casa enxaimel',
        BuildingKind.barn => 'Celeiro',
        BuildingKind.windmill => 'Moinho',
        BuildingKind.tower => 'Torre',
        BuildingKind.castle => 'Castelo',
        BuildingKind.temple => 'Templo',
        BuildingKind.church => 'Igreja',
        BuildingKind.manor => 'Mansão',
        BuildingKind.modern => 'Comércio',
        BuildingKind.block => 'Prédio',
        BuildingKind.lab => 'Laboratório',
        BuildingKind.skyscraper => 'Arranha-céu',
        BuildingKind.farmhouse => 'Casa de sítio',
        BuildingKind.silo => 'Silo',
        BuildingKind.saloon => 'Saloon',
        BuildingKind.pagoda => 'Pagode',
        BuildingKind.eastHouse => 'Casa oriental',
        BuildingKind.elfHouse => 'Casa élfica',
        BuildingKind.workshop => 'Oficina de engenhocas',
        BuildingKind.mushroom => 'Casa de cogumelo',
        BuildingKind.faluCabin => 'Chalé vermelho',
        BuildingKind.ranch => 'Casa de rancho',
        BuildingKind.gambrel => 'Casa colonial',
        BuildingKind.warehouse => 'Galpão',
        BuildingKind.greenhouse => 'Estufa',
        BuildingKind.tallHouse => 'Sobrado alto',
        BuildingKind.townHouse => 'Casa de interior',
        BuildingKind.colossus => 'Estátua colossal',
        BuildingKind.arena => 'Arena',
        BuildingKind.elfTree => 'Árvore-morada élfica',
        BuildingKind.elfTower => 'Torre élfica',
        BuildingKind.coolingTower => 'Torre de resfriamento',
        BuildingKind.dam => 'Represa',
        BuildingKind.lighthouse => 'Farol',
      };

  static const buildingType = 'Tipo de construção';

  static String citySize(CitySize s) => switch (s) {
        CitySize.village => 'Vila',
        CitySize.town => 'Cidade',
        CitySize.metropolis => 'Metrópole',
      };

  static String roofType(RoofType r) => switch (r) {
        RoofType.gable => 'Duas águas',
        RoofType.flat => 'Plano',
        RoofType.pyramid => 'Pirâmide',
      };

  /// Nome do objeto no vocabulário do sistema: só o nome que o livro usa (T20: Arcanista,
  /// Caçador, Lutador, Hynne; D&D: Mago, Patrulheiro, Monge, Halfling). No genérico, o de D&D.
  static String propFor(PropType p, String systemId) {
    const t20 = {
      PropType.wizard: 'Arcanista',
      PropType.ranger: 'Caçador',
      PropType.monk: 'Lutador',
      PropType.raceHalfling: 'Hynne',
      PropType.mLefeu: 'Lefeu',
      PropType.mBeholder: 'Observador',
    };
    return (systemId == 't20' ? t20[p] : null) ?? prop(p);
  }

  static String prop(PropType p) => switch (p) {
        PropType.tree => 'Árvore',
        PropType.pine => 'Pinheiro',
        PropType.sakura => 'Cerejeira',
        PropType.bush => 'Arbusto',
        PropType.well => 'Poço',
        PropType.fountain => 'Fonte',
        PropType.stall => 'Barraca',
        PropType.lamp => 'Poste',
        PropType.anomaly => 'Anomalia',
        PropType.cow => 'Vaca',
        PropType.sheep => 'Ovelha',
        PropType.chicken => 'Galinha',
        PropType.dog => 'Cachorro',
        PropType.horse => 'Cavalo',
        PropType.crate => 'Caixote',
        PropType.barrel => 'Barril',
        PropType.hay => 'Feno',
        PropType.cart => 'Carroça',
        PropType.banner => 'Estandarte',
        PropType.statue => 'Estátua',
        PropType.grave => 'Lápide',
        PropType.robot => 'Robô',
        PropType.powerPole => 'Poste de energia',
        PropType.dish => 'Antena parabólica',
        PropType.waterTower => 'Caixa d\'água',
        PropType.car => 'Carro',
        PropType.drone => 'Drone',
        PropType.vending => 'Máquina de venda',
        PropType.scarecrow => 'Espantalho',
        PropType.cactus => 'Cacto',
        PropType.dock => 'Doca',
        PropType.boat => 'Barco',
        PropType.airship => 'Vintagenave',
        PropType.freighter => 'Cargueiro flutuante',
        PropType.mountain => 'Montanha',
        PropType.skyIsle => 'Ilhota flutuante',
        PropType.mesa => 'Rocha vermelha',
        PropType.giantFlower => 'Flor gigante',
        PropType.fairyLight => 'Luz de fada',
        PropType.eclipse => 'O Eclipse',
        PropType.ruin => 'Ruína',
        PropType.fighter => 'Guerreiro',
        PropType.wizard => 'Mago',
        PropType.cleric => 'Clérigo',
        PropType.rogue => 'Ladino',
        PropType.ranger => 'Patrulheiro',
        PropType.bard => 'Bardo',
        PropType.paladin => 'Paladino',
        PropType.barbarian => 'Bárbaro',
        PropType.druid => 'Druida',
        PropType.monk => 'Monge',
        PropType.warlock => 'Bruxo',
        PropType.sorcerer => 'Feiticeiro',
        PropType.inventor => 'Inventor',
        PropType.noble => 'Nobre',
        PropType.raceHuman => 'Humano',
        PropType.raceElf => 'Elfo',
        PropType.raceDwarf => 'Anão',
        PropType.raceHalfling => 'Halfling',
        PropType.raceGnome => 'Gnomo',
        PropType.raceHalfOrc => 'Meio-orc',
        PropType.raceTiefling => 'Tiefling',
        PropType.raceDragonborn => 'Draconato',
        PropType.raceGoblin => 'Goblin',
        PropType.raceMinotaur => 'Minotauro',
        PropType.raceLefou => 'Lefou',
        PropType.raceDahllan => 'Dahllan',
        PropType.raceQareen => 'Qareen',
        PropType.raceOsteon => 'Osteon',
        PropType.raceTrog => 'Trog',
        PropType.raceGolem => 'Golem',
        PropType.raceMedusa => 'Medusa',
        PropType.peasant => 'Camponês',
        PropType.merchant => 'Mercador',
        PropType.guard => 'Guarda',
        PropType.kid => 'Criança de bicicleta',
        PropType.adult => 'Morador',
        PropType.scientist => 'Cientista do Loop',
        PropType.mGoblin => 'Goblin',
        PropType.mOrc => 'Orc',
        PropType.mSkeleton => 'Esqueleto',
        PropType.mTroll => 'Troll',
        PropType.mOwlbear => 'Urso-coruja',
        PropType.mBeholder => 'Beholder',
        PropType.mDragon => 'Dragão',
        PropType.mWolf => 'Lobo atroz',
        PropType.mLefeu => 'Lefeu',
        PropType.campfire => 'Fogueira',
        PropType.buccaneer => 'Bucaneiro',
        PropType.knight => 'Cavaleiro',
        PropType.raceKliren => 'Kliren',
        PropType.raceMermaid => 'Sereia / Tritão',
        PropType.raceSylph => 'Sílfide',
        PropType.raceSuraggel => 'Suraggel',
        PropType.mHobgoblin => 'Hobgoblin',
        PropType.mZombie => 'Zumbi',
        PropType.mSpider => 'Aranha gigante',
        PropType.mCube => 'Cubo gelatinoso',
        PropType.mRat => 'Ratos gigantes',


        PropType.toro => 'Lanterna de pedra',
        PropType.torii => 'Portal torii',
        PropType.elfLamp => 'Lâmpada élfica',
        PropType.tractor => 'Trator',
        PropType.dungeonEntrance => 'Entrada de masmorra',
        PropType.lantern => 'Lanterna',
      };
}

import 'dart:ui';
import '../domain/city_types.dart';
import '../domain/era.dart';
import 'settlement_type.dart';

/// Como as ruas são desenhadas.
enum RoadStyle { cobble, asphalt, neon }

/// Efeito animado sobre a área especial do sistema.
enum ZoneEffect {
  none,
  stormRift,
  loopField,
  thinVeil,
  cultFog,
  combatSparks,
  wildMotes
}

/// Visual do objeto "anomalia" de cada sistema.
enum AnomalyStyle {
  none,
  redCrystal,
  runeStone,
  loopTower,
  occultSymbol,
  obelisk,
  neonSign
}

class KindWeight {
  const KindWeight(this.kind, this.weight);
  final BuildingKind kind;
  final double weight;
}

class PropWeight {
  const PropWeight(this.type, this.weight);
  final PropType type;
  final double weight;
}

/// Identidade visual de um sistema: que construções e objetos aparecem, como são as
/// ruas, a área especial e o céu. Só dados; quem desenha está em `render/`.
class ArtProfile {
  const ArtProfile({
    required this.kinds,
    required this.road,
    required this.anomaly,
    required this.zoneEffect,
    required this.skyTop,
    required this.skyBottom,
    this.landmark,
    this.names = const {},
    this.landmarkNames = const [],
    this.filler = const [],
    this.street = const [],
    this.toolProps = const [],
    this.settlements = const [SettlementType.standard],
    this.era = Era.medieval,
    this.plazaCenter = PropType.fountain,
    this.plazaSides = const [PropType.stall],
    this.plazaCornerTrees = true,
    this.people = const [],
    this.population = const [],
    this.monsters = const [],
  });

  /// Mistura de construções comuns (peso relativo).
  final List<KindWeight> kinds;

  /// Construção única de destaque (castelo, instalação do Loop...). Uma por cidade.
  final BuildingKind? landmark;
  final List<String> landmarkNames;

  /// Nomes por tipo de construção; sem entrada, usa as listas do sistema.
  final Map<BuildingKind, List<String>> names;

  /// Objetos que enchem lotes vagos e as bordas (árvores, animais, caixotes...).
  final List<PropWeight> filler;

  /// Objetos ao lado das ruas.
  final List<PropWeight> street;

  /// Objetos da praça central: um no meio, outros nas laterais e árvores nos cantos.
  final PropType plazaCenter;
  final List<PropType> plazaSides;
  final bool plazaCornerTrees;

  /// Tipos de assentamento do cenário (o primeiro é o padrão).
  final List<SettlementType> settlements;

  /// Objetos extras oferecidos na ferramenta Objetos.
  final List<PropType> toolProps;

  /// Época do cenário: só construções e objetos dela são gerados.
  final Era era;

  /// Pessoas do cenário (classes, raças e povo) que andam pelas ruas e ficam na ferramenta.
  final List<PropType> people;

  /// Demografia padrão do cenário: raça de cada pessoa gerada, com pesos. Cada tipo de
  /// assentamento (e cada bairro) pode trocar pela sua própria, seguindo a lore.
  final List<PropWeight> population;

  /// Monstros que acampam fora da cidade, tramando algo em volta de uma fogueira.
  final List<PropType> monsters;

  final RoadStyle road;
  final AnomalyStyle anomaly;
  final ZoneEffect zoneEffect;
  final Color skyTop, skyBottom;

  static const plain = ArtProfile(
    kinds: [KindWeight(BuildingKind.house, 1)],
    road: RoadStyle.cobble,
    anomaly: AnomalyStyle.none,
    zoneEffect: ZoneEffect.none,
    skyTop: Color(0xFFCFEFF5),
    skyBottom: Color(0xFFF6F4E6),
  );
}

import 'dart:ui';
import '../domain/city_types.dart';
import '../domain/era.dart';
import 'art_profile.dart';

/// Preset de sistema de RPG: muda visual, nomes, tipos de construção,
/// povos, ganchos de aventura e a "área especial" (ex.: Área de Tormenta).
/// Para adicionar um sistema novo, basta incluir um item em [RpgSystems.all].
class RpgSystem {
  const RpgSystem({
    required this.id,
    required this.name,
    required this.setting,
    required this.era,
    required this.folk,
    required this.grassA,
    required this.grassB,
    required this.roadColor,
    required this.plazaColor,
    required this.soil,
    required this.walls,
    required this.roofs,
    required this.cityA,
    required this.cityB,
    required this.small,
    required this.medium,
    required this.large,
    required this.suffixes,
    required this.hooks,
    required this.props,
    this.zoneName,
    this.zoneNote = '',
    this.zoneColor = const Color(0xFFD94B4B),
    this.anomalyName = 'Anomalia',
    this.flatBias = 0.15,
    this.green = 1.0,
    this.art = ArtProfile.plain,
  });

  final String id, name, setting, era;
  final List<String> folk;
  final Color grassA, grassB, roadColor, plazaColor, soil;
  final List<Color> walls, roofs;
  final List<String> cityA, cityB;
  final List<String> small, medium, large, suffixes, hooks;
  final List<PropType> props;
  final String? zoneName;
  final String zoneNote;
  final Color zoneColor;
  final String anomalyName;
  final double flatBias; // chance de telhado plano
  final double green; // quanto de vegetação (0..1)
  final ArtProfile art;

  /// Objetos da ferramenta Objetos: os básicos do sistema mais os da identidade visual.
  /// Objetos da ferramenta Objetos: só os da época do cenário (o poste vira lanterna na Idade Média).
  /// Todos os objetos da época do cenário (os genéricos, como montanha, ruína e rocha,
  /// servem em qualquer sistema). Os do próprio sistema vêm primeiro na lista.
  List<PropType> get availableProps => {
        for (final p in [...props, ...art.toolProps, ...PropType.values])
          EraRules.adapt(p, art.era),
      }
          .where((p) => EraRules.allowsProp(p, art.era))
          .where((p) => p != PropType.anomaly || hasZone)
          // bonecos: só as pessoas e os monstros do próprio cenário
          .where((p) =>
              !Figures.isFigure(p) || art.people.contains(p) || art.monsters.contains(p))
          .toList();

  /// Objetos da ferramenta Objetos (sem pessoas e monstros).
  List<PropType> get availableObjects =>
      availableProps.where((p) => !Figures.isFigure(p)).toList();

  /// Classes, ocupações e monstros da ferramenta Personagens (a raça é escolhida à parte).
  List<PropType> get availableCharacters =>
      availableProps.where((p) => Figures.isFigure(p) && !Figures.races.contains(p)).toList();

  /// Raças do cenário, para combinar com a classe ou ocupação escolhida.
  List<PropType> get availableRaces =>
      availableProps.where(Figures.races.contains).toList();

  bool get hasZone => zoneName != null;
}

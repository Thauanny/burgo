import '../domain/city.dart';
import '../domain/city_types.dart';
import '../systems/rpg_system.dart';
import '../systems/settlement_type.dart';

/// Pedido de geração: a mesma combinação sempre produz a mesma cidade.
class GenerationRequest {
  const GenerationRequest({
    required this.seed,
    required this.tiles,
    required this.system,
    this.settlement = SettlementType.standard,
    this.mode = SettlementMode.cityWithFarms,
    this.withZone = true,
    this.farmGap = 2,
  });
  final int seed, tiles;
  final RpgSystem system;
  final SettlementType settlement;
  final SettlementMode mode;
  final bool withZone;

  /// Distância (em blocos) entre a cidade e as plantações (só com cidade + fazendas).
  final int farmGap;
}

/// Contrato de qualquer gerador de mapa (cidades hoje; masmorras depois).
abstract interface class CityGenerator {
  City generate(GenerationRequest request);
}

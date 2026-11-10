import 'rpg_system.dart';
import 'rpg_systems.dart';

/// Fonte dos presets de sistema de RPG. Hoje embutida; depois, arquivos JSON.
abstract interface class SystemRepository {
  List<RpgSystem> get all;
  RpgSystem get fallback;
  RpgSystem byId(String id);
}

class BuiltInSystemRepository implements SystemRepository {
  const BuiltInSystemRepository();

  @override
  List<RpgSystem> get all => RpgSystems.all;

  @override
  RpgSystem get fallback => RpgSystems.generic;

  @override
  RpgSystem byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => fallback);
}

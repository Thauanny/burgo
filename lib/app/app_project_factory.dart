import '../domain/city_types.dart';
import '../dungeon/dungeon_editor.dart';
import '../dungeon/dungeon_generator.dart';
import '../editor/editor_state.dart';
import '../generation/procedural_city_generator.dart';
import '../project/project_editor.dart';
import '../project/workspace.dart';
import '../systems/system_repository.dart';

/// Ponto único onde as dependências concretas dos projetos são escolhidas.
class AppProjectFactory implements ProjectFactory {
  const AppProjectFactory({this.systems = const BuiltInSystemRepository()});
  final SystemRepository systems;

  EditorState _city() => EditorState(
        generator: const ProceduralCityGenerator(),
        systems: systems,
        dungeonFactory: (systemId) => _dungeon(systemId: systemId),
      );

  DungeonEditor _dungeon({String? systemId}) => DungeonEditor(
        generator: const RoomsAndCorridorsGenerator(),
        systems: [for (final s in systems.all) (s.id, s.name)],
        systemId: systemId ?? systems.fallback.id,
      );

  @override
  ProjectEditor create(NewProject type, {String? systemId}) {
    final id = systemId ?? systems.fallback.id;
    return switch (type) {
      NewProject.city => _city()
        ..configure(systemId: id, mode: SettlementMode.cityOnly),
      NewProject.farm => _city()
        ..configure(systemId: id, mode: SettlementMode.farmsOnly),
      NewProject.mixed => _city()
        ..configure(systemId: id, mode: SettlementMode.cityWithFarms),
      NewProject.dungeon => _dungeon(systemId: id),
    };
  }

  @override
  ProjectEditor empty(ProjectKind kind) =>
      kind == ProjectKind.city ? _city() : _dungeon();
}

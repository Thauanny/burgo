import 'package:burgo/domain/city_types.dart';
import 'package:burgo/editor/editor_state.dart';
import 'package:burgo/generation/procedural_city_generator.dart';
import 'package:burgo/systems/system_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EditorState editor() =>
      EditorState(generator: const ProceduralCityGenerator(), systems: const BuiltInSystemRepository());

  test('trocar de sistema depois de Vectora volta ao mapa padrão (tamanho, escala, população)', () {
    final e = editor()..configure(systemId: 't20', settlementId: 'voadora');
    expect(e.city.size, greaterThan(CitySize.town.tiles), reason: 'Vectora é grande');
    final vectoraPeople = e.peopleCount;
    e.setSystemById('generico');
    expect(e.city.size, CitySize.town.tiles);
    expect(e.city.kmPerTile, 1);
    expect(e.peopleCount, lessThan(vectoraPeople));
  });

  test('o mesmo vale para uma aba aberta já em Vectora (projeto salvo)', () {
    final saved = (editor()..configure(systemId: 't20', settlementId: 'voadora')).toJson();
    final e = editor()..loadJson(saved);
    expect(e.city.size, greaterThan(CitySize.town.tiles));
    e.setSystemById('dnd5e');
    expect(e.city.size, CitySize.town.tiles);
  });

  test('trocar de lugar sai do tamanho especial do mapa oficial, mas mantém um tamanho escolhido', () {
    final e = editor()..configure(systemId: 't20', settlementId: 'voadora');
    e.setSettlement(e.system.art.settlements.firstWhere((s) => s.id == 'cidade_livre'));
    expect(e.city.size, CitySize.town.tiles);
    e.generate(size: CitySize.metropolis);
    e.setSettlement(e.system.art.settlements.firstWhere((s) => s.id == 'fortaleza'));
    expect(e.city.size, CitySize.metropolis.tiles, reason: 'metrópole escolhida pela pessoa fica');
  });
}

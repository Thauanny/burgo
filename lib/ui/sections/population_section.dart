import 'package:flutter/material.dart';

import '../../editor/editor_state.dart';
import '../section_title.dart';

/// Controle da população: quantas pessoas andam pela cidade e quantos monstros acampam
/// fora dela. Mudar o número põe ou tira gente sem refazer o resto do mapa.
class PopulationSection extends StatefulWidget {
  const PopulationSection({super.key, required this.editor});
  final EditorState editor;

  @override
  State<PopulationSection> createState() => _PopulationSectionState();
}

class _PopulationSectionState extends State<PopulationSection> {
  double? _people, _monsters;
  final Map<String, double> _roamDrag = {};

  Widget _roam(String label, int value, void Function(int) apply) {
    final v = _roamDrag[label] ?? value.toDouble();
    return Row(children: [
      SizedBox(width: 110, child: Text('$label: ${v.round()}')),
      Expanded(
        child: Slider(
          value: v,
          min: 0,
          max: 12,
          divisions: 12,
          label: '${v.round()}',
          onChanged: (x) => setState(() => _roamDrag[label] = x),
          onChangeEnd: (x) {
            apply(x.round());
            setState(() => _roamDrag.remove(label));
          },
        ),
      ),
    ]);
  }

  EditorState get e => widget.editor;

  @override
  Widget build(BuildContext context) {
    final maxPeople = e.maxPeople;
    final people = (_people ?? e.peopleCount.toDouble()).clamp(0, maxPeople.toDouble()).toDouble();
    final maxMonsters = e.maxMonsters;
    final monsters = (_monsters ?? e.monsterCount.toDouble()).clamp(0, maxMonsters.toDouble()).toDouble();
    final tt = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('População'),
      SubLabel('Pessoas na cidade: ${people.round()}', top: 0),
      if (maxPeople == 0)
        Text('Não há ruas ou praças livres para pôr gente.', style: tt.bodySmall)
      else
        Slider(
          value: people,
          min: 0,
          max: maxPeople.toDouble(),
          divisions: maxPeople,
          label: '${people.round()}',
          onChanged: (v) => setState(() => _people = v),
          onChangeEnd: (v) {
            e.setPeopleCount(v.round());
            setState(() => _people = null);
          },
        ),
      if (maxMonsters > 0) ...[
        SubLabel('Monstros acampados fora da cidade: ${monsters.round()}'),
        Slider(
          value: monsters,
          min: 0,
          max: maxMonsters.toDouble(),
          divisions: maxMonsters,
          label: '${monsters.round()}',
          onChanged: (v) => setState(() => _monsters = v),
          onChangeEnd: (v) {
            e.setMonsterCount(v.round());
            setState(() => _monsters = null);
          },
        ),
      ],
      Text(
          'As raças seguem a população do lugar. Para pôr alguém num ponto exato, use '
          'Editar › Personagens.',
          style: tt.bodySmall),
      const SubLabel('Raio de movimento (blocos em cada sentido)'),
      _roam('Pessoas', e.roamPeople, (v) => e.setRoamAll(people: v)),
      if (maxMonsters > 0) _roam('Monstros', e.roamMonsters, (v) => e.setRoamAll(monsters: v)),
      _roam('Animais soltos', e.roamAnimals, (v) => e.setRoamAll(animals: v)),
      Text(
          'Vale para todos e para os que você puser depois. 0 = parados. Para mudar só um, '
          'clique nele (com Mover ou Selecionar) e ajuste na aba Editar.',
          style: tt.bodySmall),
    ]);
  }
}

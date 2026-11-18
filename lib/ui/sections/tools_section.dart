import 'package:flutter/material.dart';

import '../../domain/city_types.dart';
import '../../editor/editor_state.dart';
import '../../editor/tool.dart';
import '../prop_categories.dart';
import '../retro/vintage.dart';
import '../section_title.dart';
import '../strings.dart';

const _toolIcons = {
  ToolId.pan: Icons.open_with,
  ToolId.select: Icons.pan_tool_alt,
  ToolId.road: Icons.add_road,
  ToolId.zone: Icons.warning_amber,
  ToolId.zoneSource: Icons.radar,
  ToolId.marker: Icons.place,
  ToolId.ruler: Icons.straighten,
  ToolId.water: Icons.water,
  ToolId.wall: Icons.fort,
  ToolId.farm: Icons.agriculture,
  ToolId.build: Icons.home_work,
  ToolId.prop: Icons.park,
  ToolId.character: Icons.groups,
  ToolId.erase: Icons.delete_outline,
};

class ToolsSection extends StatelessWidget {
  const ToolsSection({super.key, required this.editor, this.picker = true, this.options = true});
  final EditorState editor;

  /// Mostra os botões das ferramentas e/ou as opções da ferramenta ativa.
  final bool picker, options;

  /// Ferramentas em grupos, na ordem de uso: navegar, terreno, construir, anotar, apagar.
  static const _groups = [
    ('Navegar', [ToolId.pan, ToolId.select]),
    ('Terreno', [ToolId.road, ToolId.water, ToolId.wall, ToolId.zone, ToolId.zoneSource]),
    ('Construir', [ToolId.build, ToolId.farm, ToolId.prop, ToolId.character]),
    ('Anotar', [ToolId.marker, ToolId.ruler]),
    ('Apagar', [ToolId.erase]),
  ];

  @override
  Widget build(BuildContext context) {
    final sys = editor.system;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (picker)
      for (final (label, ids) in _groups) ...[
        SubLabel(label, top: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final id in ids)
            if ((id != ToolId.zone && id != ToolId.zoneSource) || sys.hasZone)
              PaperChip(
                avatar: Icon(_toolIcons[id], size: 18),
                label: Text(Strings.toolLabel(id, zoneName: sys.zoneName)),
                selected: editor.toolId == id,
                onSelected: (_) => editor.setTool(id),
              ),
        ]),
      ],
      if (options) ..._toolOptions(),
      if (options && editor.toolId == ToolId.prop)
        ..._grouped(PropGroup.objectGroups, editor.availableObjects, editor.propType,
            editor.setPropType),
      if (options && editor.toolId == ToolId.character) ...[
        ..._grouped(PropGroup.characterGroups, editor.availableCharacters,
            editor.characterType, editor.setCharacterType),
        if (Figures.isPerson(editor.characterType) && editor.availableRaces.isNotEmpty)
          ...raceChips(editor, editor.characterRace, editor.setCharacterRace),
      ],
    ]);
  }

  /// Opções da ferramenta ativa (tipo de rua, de muro) e uma dica de uso.
  List<Widget> _toolOptions() {
    Widget chips<T>(String label, List<(T, String, IconData)> items, T selected, void Function(T) pick) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SubLabel(label),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final (v, text, icon) in items)
              PaperChip(
                avatar: Icon(icon, size: 18),
                label: Text(text),
                selected: selected == v,
                onSelected: (_) => pick(v),
              ),
          ]),
        ]);
    return switch (editor.toolId) {
      ToolId.road => [
          chips<RoadKind>('Tipo de rua', const [
            (RoadKind.paved, 'Rua calçada', Icons.add_road),
            (RoadKind.dirt, 'Estrada de terra', Icons.terrain),
            (RoadKind.plaza, 'Praça', Icons.crop_square),
          ], editor.roadKind, editor.setRoadKind),
          _hint('Arraste para pintar; comece num tile já pintado para apagar.'),
        ],
      ToolId.wall => [
          chips<WallKind>('Tipo de muro', const [
            (WallKind.stone, 'Muralha de pedra', Icons.fort),
            (WallKind.palisade, 'Paliçada de madeira', Icons.fence),
            (WallKind.low, 'Muro baixo de pedra', Icons.horizontal_rule),
            (WallKind.fence, 'Cerca de madeira', Icons.fence),
            (WallKind.hedge, 'Sebe (cerca viva)', Icons.grass),
          ], editor.wallKind, editor.setWallKind),
          _hint('Arraste para pintar; comece num trecho já pintado para apagar. Uma rua cruzando '
              'a muralha vira portão; cercas e sebes se ligam entre si e aos muros.'),
        ],
      ToolId.water => [_hint('Arraste para pintar rios e lagos; sobre uma rua vira ponte.')],
      ToolId.pan => [
          _hint('Arraste para mover o mapa (nada sai do lugar). Clique num item para ver as '
              'opções dele — num personagem ou monstro, o raio de movimento.')
        ],
      ToolId.select => [_hint('Clique num item para ver as opções dele; arraste para movê-lo.')],
      ToolId.erase => [_hint('Clique em um item para apagá-lo.')],
      _ => const [],
    };
  }

  Widget _hint(String text) => Builder(
      builder: (context) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ));

  /// Chips de raça (combinada com a classe ou ocupação escolhida).
  static List<Widget> raceChips(EditorState editor, PropType? selected, void Function(PropType) onPick) {
    final sys = editor.system;
    return [
      const SubLabel('Raça'),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final r in editor.availableRaces)
          PaperChip(
            label: Text(Strings.propFor(r, sys.id)),
            selected: selected == r,
            onSelected: (_) => onPick(r),
          ),
      ]),
    ];
  }

  /// Chips separados por grupo (Natureza, Vila..., ou Classes, Raças...), cada grupo com título.
  List<Widget> _grouped(List<PropGroup> groups, List<PropType> items,
      PropType selected, void Function(PropType) onPick) {
    final sys = editor.system;
    return [
      for (final g in groups)
        if (items.any((p) => PropGroup.of(p) == g)) ...[
          SubLabel(g.label),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final p in items)
              if (PropGroup.of(p) == g)
                PaperChip(
                  label: Text(p == PropType.anomaly ? sys.anomalyName : Strings.propFor(p, sys.id)),
                  selected: selected == p,
                  onSelected: (_) => onPick(p),
                ),
          ]),
        ],
    ];
  }
}

import 'package:flutter/material.dart';

import '../../domain/city_types.dart';
import '../../editor/editor_state.dart';
import '../../editor/tool.dart';
import '../asset_browser.dart';
import '../prop_categories.dart';
import '../retro/vintage.dart';
import '../section_title.dart';
import '../strings.dart';
import '../thumbnails.dart';
import '../tool_palette.dart';

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
    ('Anotar e apagar', [ToolId.marker, ToolId.ruler, ToolId.erase]),
  ];

  @override
  Widget build(BuildContext context) {
    final sys = editor.system;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (picker)
        ToolPalette<ToolId>(
          groups: [
            for (final (label, ids) in _groups)
              (
                label,
                [
                  for (final id in ids)
                    if ((id != ToolId.zone && id != ToolId.zoneSource) || sys.hasZone)
                      PaletteItem(id, _toolIcons[id]!, Strings.toolLabel(id, zoneName: sys.zoneName)),
                ]
              ),
          ],
          selected: editor.toolId,
          onPick: editor.setTool,
        ),
      if (options) ..._toolOptions(),
      if (options && editor.toolId == ToolId.prop)
        objectBrowser(editor, PropGroup.objectGroups, editor.availableObjects, editor.propType, editor.setPropType),
      if (options && editor.toolId == ToolId.character) ...[
        if (Figures.isPerson(editor.characterType) && editor.availableRaces.isNotEmpty)
          ...raceChips(editor, editor.characterRace, editor.setCharacterRace),
        const SizedBox(height: 8),
        objectBrowser(editor, PropGroup.characterGroups, editor.availableCharacters, editor.characterType,
            editor.setCharacterType,
            hint: 'Buscar personagem…', race: editor.characterRace),
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
          chips<bool>('O que colocar', const [
            (false, 'Trecho de muro', Icons.horizontal_rule),
            (true, 'Portão', Icons.door_front_door),
          ], editor.wallGate, editor.setWallGate),
          chips<WallKind>(editor.wallGate ? 'Portão de qual muro?' : 'Tipo de muro', const [
            (WallKind.stone, 'Muralha de pedra', Icons.fort),
            (WallKind.palisade, 'Paliçada de madeira', Icons.fence),
            (WallKind.low, 'Muro baixo de pedra', Icons.horizontal_rule),
            (WallKind.fence, 'Cerca de madeira', Icons.fence),
            (WallKind.hedge, 'Sebe (cerca viva)', Icons.grass),
          ], editor.wallKind, editor.setWallKind),
          _hint(editor.wallGate
              ? 'Clique num trecho de muro (ou num tile livre) para pôr o portão do tipo escolhido: '
                  'arco de pedra com grade, portão de madeira entre mourões, porteira do muro baixo, '
                  'porteira de cerca ou arco da sebe. Clique de novo no portão para fechá-lo.'
              : 'Arraste para pintar; comece num trecho já pintado para apagar. Uma rua cruzando '
                  'a muralha também vira portão; cercas e sebes se ligam entre si e aos muros.'),
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

  /// Navegador de objetos ou personagens com miniaturas, busca e categorias.
  static Widget objectBrowser(EditorState editor, List<PropGroup> groups, List<PropType> items, PropType? selected,
      ValueChanged<PropType> onPick,
      {String hint = 'Buscar objeto…', PropType? race}) {
    final sys = editor.system;
    String label(PropType p) => p == PropType.anomaly ? sys.anomalyName : Strings.propFor(p, sys.id);
    return AssetBrowser(
      items: items,
      groups: groups,
      selected: selected,
      onPick: onPick,
      label: label,
      hint: hint,
      thumb: (p) => PropThumb(p,
          race: Figures.isPerson(p) && !Figures.loopFolk.contains(p) ? race : null,
          people: sys.art.people,
          anomaly: sys.art.anomaly),
    );
  }

  /// Chips de raça (combinada com a classe ou ocupação escolhida).
  static List<Widget> raceChips(EditorState editor, PropType? selected, void Function(PropType) onPick) {
    final sys = editor.system;
    final races = editor.availableRaces;
    // lista suspensa: com 17 raças, botões empurravam o resto do painel para baixo
    return [
      const SizedBox(height: 10),
      DropdownButtonFormField<PropType>(
        key: ValueKey('race-$selected'),
        initialValue: races.contains(selected) ? selected : null,
        isDense: true,
        decoration: const InputDecoration(labelText: 'Raça', isDense: true),
        items: [
          for (final r in races) DropdownMenuItem(value: r, child: Text(Strings.propFor(r, sys.id))),
        ],
        onChanged: (r) {
          if (r != null) onPick(r);
        },
      ),
    ];
  }

}

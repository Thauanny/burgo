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
  const ToolsSection({super.key, required this.editor});
  final EditorState editor;

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
      const SectionTitle(Strings.sectionTools),
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
      if (editor.toolId == ToolId.prop)
        ..._grouped(PropGroup.objectGroups, sys.availableObjects, editor.propType,
            editor.setPropType),
      if (editor.toolId == ToolId.character) ...[
        ..._grouped(PropGroup.characterGroups, sys.availableCharacters,
            editor.characterType, editor.setCharacterType),
        if (Figures.isPerson(editor.characterType) && sys.availableRaces.isNotEmpty)
          ...raceChips(editor, editor.characterRace, editor.setCharacterRace),
      ],
    ]);
  }

  /// Chips de raça (combinada com a classe ou ocupação escolhida).
  static List<Widget> raceChips(EditorState editor, PropType? selected, void Function(PropType) onPick) {
    final sys = editor.system;
    return [
      const SubLabel('Raça'),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final r in sys.availableRaces)
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

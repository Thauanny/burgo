import 'package:flutter/material.dart';

import '../../domain/city_types.dart';
import '../../domain/era.dart';
import '../../domain/map_item.dart';
import '../../editor/editor_state.dart';
import '../../render/layers/annotation_layer.dart' show formatKm;
import '../retro/vintage.dart';
import '../section_title.dart';
import '../strings.dart';
import 'color_swatches.dart';
import 'floors_section.dart';
import 'tools_section.dart';

const _wallSwatches = [
  Color(0xFFF4D9B5),
  Color(0xFFF7E7C6),
  Color(0xFFE9C9A0),
  Color(0xFFD9E6C3),
  Color(0xFFCFE3EA),
  Color(0xFFF2C9C0),
  Color(0xFFE6D5F0),
  Color(0xFFFFF1D6),
  Color(0xFFBBD2DC),
  Color(0xFF8F9BB0),
];
const _roofSwatches = [
  Color(0xFFC96B5A),
  Color(0xFF8E5A3C),
  Color(0xFF5E7FA8),
  Color(0xFF6BA583),
  Color(0xFFB5524A),
  Color(0xFF7B6A9A),
  Color(0xFFD08B4C),
  Color(0xFF4F5B66),
  Color(0xFF2F3744),
];

/// Editor da construção selecionada (ou do modelo) e ações do objeto selecionado.
class BuildingSection extends StatelessWidget {
  const BuildingSection({super.key, required this.editor});
  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    final b = editor.activeBuilding;
    final sel = editor.selected;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (b != null) ..._buildingEditor(b),
      if (sel is Prop && sel.type == PropType.dungeonEntrance)
        EntranceActions(editor: editor, entrance: sel),
      if (sel is Prop) ...[
        SectionTitle(sel.type == PropType.anomaly
            ? editor.system.anomalyName
            : Strings.propFor(sel.type, editor.system.id)),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final t in (Figures.isFigure(sel.type)
              ? editor.system.availableCharacters
              : editor.system.availableObjects))
            PaperChip(
              label: Text(t == PropType.anomaly
                  ? editor.system.anomalyName
                  : Strings.propFor(t, editor.system.id)),
              selected: sel.type == t,
              onSelected: (_) => editor.changeSelectedPropType(t),
            ),
        ]),
        if (Figures.isPerson(sel.type) && editor.system.availableRaces.isNotEmpty)
          ...ToolsSection.raceChips(editor, sel.race, editor.setSelectedRace),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: editor.deleteSelected,
          icon: const Icon(Icons.delete),
          label: const Text(Strings.removeProp),
        ),
      ],
    ]);
  }

  List<Widget> _buildingEditor(Building b) {
    final isDraft = editor.isEditingDraft;
    return [
      SectionTitle(
          isDraft ? Strings.newBuildingTemplate : Strings.selectedBuilding),
      if (!isDraft)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
              '${Strings.fromCenter}: ${formatKm(editor.city.distanceFromHubKm(b.x + b.width / 2, b.y + b.depth / 2))}',
              style: const TextStyle(fontSize: 12)),
        ),
      if (!isDraft)
        TextFormField(
          key: ValueKey('bn${b.id}'),
          initialValue: b.name,
          decoration: const InputDecoration(labelText: Strings.name),
          onChanged: (v) => editor.editBuilding((e) => e.copyWith(name: v)),
        ),
      const Text(Strings.buildingType,
          style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Wrap(spacing: 6, runSpacing: 4, children: [
        for (final k in BuildingKind.values)
          if (EraRules.allowsBuilding(k, editor.era))
            PaperChip(
                label: Text(Strings.buildingKind(k)),
                selected: b.kind == k,
                onSelected: (_) =>
                    editor.editBuilding((e) => e.copyWith(kind: k))),
      ]),
      const SizedBox(height: 6),
      LabeledSlider(
        label: Strings.floors,
        value: b.floors,
        min: BuildingLimits.minFloors,
        max: BuildingLimits.maxFloors,
        onChanged: (v) => editor.editBuilding((e) => e.copyWith(floors: v)),
      ),
      LabeledSlider(
        label: Strings.width,
        value: b.width,
        min: BuildingLimits.minSide,
        max: BuildingLimits.maxSide,
        onChanged: (v) => editor.editBuilding((e) => e.copyWith(width: v)),
      ),
      LabeledSlider(
        label: Strings.depth,
        value: b.depth,
        min: BuildingLimits.minSide,
        max: BuildingLimits.maxSide,
        onChanged: (v) => editor.editBuilding((e) => e.copyWith(depth: v)),
      ),
      const SizedBox(height: 4),
      SegmentedButton<RoofType>(
        showSelectedIcon: false,
        segments: [
          for (final r in RoofType.values)
            ButtonSegment(value: r, label: Text(Strings.roofType(r)))
        ],
        selected: {b.roof},
        onSelectionChanged: (s) =>
            editor.editBuilding((e) => e.copyWith(roof: s.first)),
      ),
      const SizedBox(height: 8),
      const Text(Strings.wall),
      const SizedBox(height: 4),
      ColorSwatches(
        colors: _wallSwatches,
        selected: b.wall,
        onSelected: (c) => editor.editBuilding((e) => e.copyWith(wall: c)),
      ),
      const SizedBox(height: 8),
      const Text(Strings.roof),
      const SizedBox(height: 4),
      ColorSwatches(
        colors: [..._roofSwatches, ...editor.system.roofs],
        selected: b.roofColor,
        onSelected: (c) => editor.editBuilding((e) => e.copyWith(roofColor: c)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(Strings.chimney),
        value: b.chimney,
        onChanged: (v) => editor.editBuilding((e) => e.copyWith(chimney: v)),
      ),
      if (!isDraft)
        Row(children: [
          OutlinedButton.icon(
              onPressed: editor.duplicateSelected,
              icon: const Icon(Icons.copy),
              label: const Text(Strings.duplicate)),
          const SizedBox(width: 8),
          OutlinedButton.icon(
              onPressed: editor.deleteSelected,
              icon: const Icon(Icons.delete),
              label: const Text(Strings.remove)),
        ])
      else
        const Text(Strings.clickToPlace),
    ];
  }
}

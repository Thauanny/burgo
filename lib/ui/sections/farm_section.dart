import 'package:flutter/material.dart';

import '../../domain/city_types.dart';
import '../../editor/editor_state.dart';
import '../../editor/tools/prop_tool.dart' show PropTool;
import '../../render/layers/annotation_layer.dart' show formatKm;
import '../prop_categories.dart';
import '../retro/vintage.dart';
import '../section_title.dart';
import '../strings.dart';
import 'color_swatches.dart';

/// Editor da fazenda selecionada (ou do modelo da ferramenta Fazenda).
class FarmSection extends StatelessWidget {
  const FarmSection({super.key, required this.editor});
  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    final f = editor.activeFarm;
    if (f == null) return const SizedBox.shrink();
    final isDraft = editor.isEditingFarmDraft;
    final placingObject = isDraft && editor.farmProp != null;
    final sys = editor.system;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(isDraft ? 'Fazenda' : Strings.selectedFarm),
      SubLabel(isDraft ? 'Plantações (dentro da cerca)' : Strings.crop, top: 0),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final c in CropType.values)
          PaperChip(
            label: Text(Strings.cropName(c)),
            selected: !placingObject && f.crop == c,
            onSelected: (_) {
              editor.setFarmProp(null);
              editor.editFarm((e) => e.copyWith(crop: c));
            },
          ),
      ]),
      if (isDraft)
        for (final g in PropGroup.farmGroups)
          if (editor.availableObjects.any((p) => PropGroup.of(p) == g)) ...[
            SubLabel(g.label),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final p in editor.availableObjects)
                if (PropGroup.of(p) == g)
                  PaperChip(
                    label: Text(Strings.propFor(p, sys.id)),
                    selected: editor.farmProp == p,
                    onSelected: (_) => editor.setFarmProp(p),
                  ),
            ]),
          ],
      if (placingObject) ...[
        const SizedBox(height: 8),
        Text(
            PropTool.linear.contains(editor.farmProp)
                ? 'Arraste no mapa para pintar a cerca; ela se liga às vizinhas.'
                : 'Clique no mapa para colocar.',
            style: Theme.of(context).textTheme.bodySmall),
      ] else ...[
      LabeledSlider(
        label: Strings.width,
        value: f.width,
        min: FarmLimits.minSide,
        max: FarmLimits.maxSide,
        onChanged: (v) => editor.editFarm((e) => e.copyWith(width: v)),
      ),
      LabeledSlider(
        label: Strings.depth,
        value: f.depth,
        min: FarmLimits.minSide,
        max: FarmLimits.maxSide,
        onChanged: (v) => editor.editFarm((e) => e.copyWith(depth: v)),
      ),
      if (!isDraft)
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(
              '${Strings.fromCenter}: ${formatKm(editor.city.distanceFromHubKm(f.x + f.width / 2, f.y + f.depth / 2))}',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      if (isDraft)
        const Text(Strings.clickToPlace)
      else
        OutlinedButton.icon(
          onPressed: editor.deleteSelected,
          icon: const Icon(Icons.delete),
          label: const Text(Strings.remove),
        ),
      ],
    ]);
  }
}

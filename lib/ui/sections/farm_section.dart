import 'package:flutter/material.dart';

import '../../domain/city_types.dart';
import '../../editor/editor_state.dart';
import '../../render/layers/annotation_layer.dart' show formatKm;
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(isDraft ? Strings.farmTemplate : Strings.selectedFarm),
      Text(Strings.crop, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      Wrap(spacing: 8, runSpacing: 4, children: [
        for (final c in CropType.values)
          PaperChip(
            label: Text(Strings.cropName(c)),
            selected: f.crop == c,
            onSelected: (_) => editor.editFarm((e) => e.copyWith(crop: c)),
          ),
      ]),
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
    ]);
  }
}

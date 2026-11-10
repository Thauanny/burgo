import 'package:flutter/material.dart';

import '../../domain/city_types.dart';
import '../../editor/editor_state.dart';
import '../../render/layers/annotation_layer.dart' show formatKm;
import '../retro/vintage.dart';
import '../section_title.dart';
import '../strings.dart';
import 'color_swatches.dart';

/// O que entra no mapa ao gerar: cidade, fazendas ou os dois (e a distância entre eles), e a área especial.
class GenerationSection extends StatelessWidget {
  const GenerationSection({super.key, required this.editor});
  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final sys = editor.system;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle(Strings.sectionGeneration),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final m in SettlementMode.values)
          PaperChip(
            label: Text(Strings.settlementMode(m)),
            selected: editor.mode == m,
            onSelected: (_) => editor.setMode(m),
          ),
      ]),
      if (editor.mode == SettlementMode.cityWithFarms) ...[
        const SizedBox(height: 8),
        LabeledSlider(
            label: Strings.farmGap,
            value: editor.farmGap,
            min: 2,
            max: 30,
            onChanged: editor.setFarmGap),
        Text(
          '${editor.farmGap} blocos ≈ ${formatKm(editor.farmGap * editor.city.kmPerTile)} entre a cidade e as plantações. O mapa cresce sozinho se for preciso (hoje ${editor.city.size}×${editor.city.size}).',
          style: tt.bodySmall?.copyWith(color: Vintage.muted),
        ),
      ],
      if (sys.hasZone)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(Strings.generateZone(sys.zoneName!)),
          value: editor.withZone,
          onChanged: editor.setWithZone,
        ),
    ]);
  }
}

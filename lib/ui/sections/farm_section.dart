import 'package:flutter/material.dart';

import '../../domain/city_types.dart';
import '../../domain/era.dart';
import '../../editor/editor_state.dart';
import '../../editor/tools/prop_tool.dart' show PropTool;
import '../../render/layers/annotation_layer.dart' show formatKm;
import '../asset_browser.dart';
import '../prop_categories.dart';
import '../retro/vintage.dart';
import '../section_title.dart';
import '../strings.dart';
import '../thumbnails.dart';
import 'color_swatches.dart';
import 'tools_section.dart';

/// Editor da fazenda selecionada (ou do modelo da ferramenta Fazenda).
class FarmSection extends StatelessWidget {
  const FarmSection({super.key, required this.editor});
  final EditorState editor;

  /// Construções de campo que existem na época do lugar: a casa, o celeiro, o silo, o moinho...
  static List<BuildingKind> _buildings(EditorState editor) => [
        for (final k in const [
          BuildingKind.countryHouse,
          BuildingKind.farmhouse,
          BuildingKind.gambrel,
          BuildingKind.ranch,
          BuildingKind.faluCabin,
          BuildingKind.barn,
          BuildingKind.stable,
          BuildingKind.silo,
          BuildingKind.windmill,
          BuildingKind.greenhouse,
        ])
          if (EraRules.allowsBuilding(k, editor.era)) k,
      ];

  @override
  Widget build(BuildContext context) {
    final f = editor.activeFarm;
    if (f == null) return const SizedBox.shrink();
    final isDraft = editor.isEditingFarmDraft;
    final tt = Theme.of(context).textTheme;
    // ferramenta Fazenda: três modos, um de cada vez (plantação, construção, objeto/animal)
    final mode = editor.farmBuilding != null ? 1 : (editor.farmProp != null ? 2 : 0);
    final farmObjects = [for (final p in editor.availableObjects) if (PropGroup.farmGroups.contains(PropGroup.of(p))) p];
    final buildings = _buildings(editor);
    Widget sizeSliders() => Column(children: [
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
        ]);
    Widget crops() => Wrap(spacing: 8, runSpacing: 6, children: [
          for (final c in CropType.values)
            PaperChip(
              label: Text(Strings.cropName(c)),
              selected: f.crop == c,
              onSelected: (_) => editor.editFarm((e) => e.copyWith(crop: c)),
            ),
        ]);
    if (!isDraft) {
      // plantação selecionada: cultivo, tamanho e remover
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Strings.selectedFarm, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        Text('${Strings.fromCenter}: ${formatKm(editor.city.distanceFromHubKm(f.x + f.width / 2, f.y + f.depth / 2))}',
            style: tt.bodySmall?.copyWith(color: Vintage.muted)),
        const SubLabel(Strings.crop),
        crops(),
        const SubLabel('Tamanho'),
        sizeSliders(),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: editor.deleteSelected,
          icon: const Icon(Icons.delete_outline, color: Vintage.terracotta),
          label: const Text(Strings.remove),
        ),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          const ButtonSegment(value: 0, icon: Icon(Icons.grass), label: Text('Plantação')),
          if (buildings.isNotEmpty) const ButtonSegment(value: 1, icon: Icon(Icons.home_work), label: Text('Construção')),
          if (farmObjects.isNotEmpty) const ButtonSegment(value: 2, icon: Icon(Icons.pets), label: Text('Objetos')),
        ],
        selected: {mode},
        onSelectionChanged: (sel) {
          switch (sel.first) {
            case 1:
              editor.setFarmBuilding(buildings.first);
            case 2:
              editor.setFarmProp(farmObjects.first);
            default:
              editor.setFarmProp(null);
          }
        },
      ),
      const SizedBox(height: 10),
      if (mode == 0) ...[
        const SubLabel('Cultivo (dentro da cerca)', top: 0),
        crops(),
        const SubLabel('Tamanho'),
        sizeSliders(),
        Text('Clique no mapa para plantar. Árvores e mato no terreno saem; os bichos se afastam.',
            style: tt.bodySmall),
      ] else if (mode == 1) ...[
        LayoutBuilder(builder: (context, c) {
          const gap = 6.0;
          final cols = (c.maxWidth / 92).floor().clamp(2, 5);
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (final k in buildings)
              SizedBox(
                width: w,
                child: AssetTile(
                  selected: editor.farmBuilding == k,
                  label: Strings.buildingKind(k),
                  thumb: BuildingThumb(k, size: 50, era: editor.era),
                  onTap: () => editor.setFarmBuilding(k),
                ),
              ),
          ]);
        }),
        const SizedBox(height: 8),
        Text('Clique no mapa para colocar. Depois, selecione a construção para mudar tamanho, telhado e cores.',
            style: tt.bodySmall),
      ] else ...[
        ToolsSection.objectBrowser(editor, PropGroup.farmGroups, farmObjects, editor.farmProp, editor.setFarmProp),
        const SizedBox(height: 8),
        Text(
            PropTool.linear.contains(editor.farmProp)
                ? 'Arraste no mapa para pintar a cerca; ela se liga às vizinhas.'
                : 'Clique no mapa para colocar.',
            style: tt.bodySmall),
      ],
    ]);
  }
}

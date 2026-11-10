import 'package:flutter/material.dart';
import '../../domain/city_types.dart';
import '../../editor/editor_state.dart';
import '../section_title.dart';
import '../strings.dart';

class CitySection extends StatelessWidget {
  const CitySection({super.key, required this.editor});
  final EditorState editor;

  @override
  Widget build(BuildContext context) {
    final city = editor.city;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle(Strings.sectionCity),
      TextFormField(
        key: ValueKey('cn${editor.revision}'),
        initialValue: city.name,
        decoration: const InputDecoration(labelText: Strings.cityName),
        onChanged: editor.renameCity,
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: TextFormField(
            key: ValueKey('sd${city.seed}-${editor.revision}'),
            initialValue: '${city.seed}',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: Strings.seed),
            onFieldSubmitted: (v) {
              final seed = int.tryParse(v);
              if (seed != null) editor.generate(seed: seed);
            },
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => editor.generate(),
          icon: const Icon(Icons.casino),
          label: const Text(Strings.generateNew),
        ),
      ]),
      const SubLabel(Strings.citySizeLabel),
      SegmentedButton<CitySize>(
        showSelectedIcon: false,
        segments: [
          for (final s in CitySize.values)
            ButtonSegment(value: s, label: Text(Strings.citySize(s)))
        ],
        selected: CitySize.values.any((s) => s.tiles == city.size)
            ? {CitySize.fromTiles(city.size)}
            : const {},
        emptySelectionAllowed: true,
        onSelectionChanged: (s) {
          if (s.isNotEmpty) editor.generate(seed: city.seed, size: s.first);
        },
      ),
    ]);
  }
}

import 'package:flutter/material.dart';

/// Linha de bolinhas de cor selecionáveis.
class ColorSwatches extends StatelessWidget {
  const ColorSwatches(
      {super.key,
      required this.colors,
      required this.selected,
      required this.onSelected});
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final c in colors)
          Semantics(
            button: true,
            selected: c == selected,
            child: GestureDetector(
              onTap: () => onSelected(c),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: c == selected ? Colors.black87 : Colors.black26,
                      width: c == selected ? 3 : 1),
                ),
              ),
            ),
          ),
      ]);
}

/// Slider de inteiros com rótulo e valor.
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value, min, max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: tt.bodyMedium)),
          Text('$value',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ]),
      ),
      Slider(
        value: value.clamp(min, max).toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: max - min,
        label: '$value',
        onChanged: (x) => onChanged(x.round()),
      ),
    ]);
  }
}

import 'package:flutter/material.dart';

import 'retro/vintage.dart';

/// Um botão da paleta de ferramentas.
class PaletteItem<T> {
  const PaletteItem(this.value, this.icon, this.label, {this.tooltip});
  final T value;
  final IconData icon;
  final String label;
  final String? tooltip;
}

/// Paleta compacta de ferramentas (como a barra de ferramentas de um editor): ícone grande e
/// nome curto embaixo, em grupos com uma legenda pequena. A ferramenta ativa fica em mostarda.
class ToolPalette<T> extends StatelessWidget {
  const ToolPalette({super.key, required this.groups, required this.selected, required this.onPick});
  final List<(String, List<PaletteItem<T>>)> groups;
  final T selected;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 6.0;
      final cols = (c.maxWidth / 70).floor().clamp(3, 6);
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final (label, items) in groups)
          if (items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(label.toUpperCase(),
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: .8, color: Vintage.muted)),
            ),
            Wrap(spacing: gap, runSpacing: gap, children: [
              for (final it in items)
                SizedBox(
                  width: w,
                  child: _PaletteButton(
                    icon: it.icon,
                    label: it.label,
                    tooltip: it.tooltip ?? it.label,
                    selected: it.value == selected,
                    onTap: () => onPick(it.value),
                  ),
                ),
            ]),
          ],
      ]);
    });
  }
}

class _PaletteButton extends StatefulWidget {
  const _PaletteButton(
      {required this.icon, required this.label, required this.tooltip, required this.selected, required this.onTap});
  final IconData icon;
  final String label, tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PaletteButton> createState() => _PaletteButtonState();
}

class _PaletteButtonState extends State<_PaletteButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.selected;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Semantics(
        button: true,
        selected: on,
        label: widget.label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              height: 52,
              decoration: BoxDecoration(
                color: on ? Vintage.mustard : (_hover ? Vintage.hotTop : Vintage.highlight),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: on ? Vintage.dark : Vintage.shadow, width: on ? 1.6 : 1),
                boxShadow: on ? const [BoxShadow(color: Vintage.dark, offset: Offset(1, 1))] : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(widget.icon, size: 22, color: Vintage.dark),
                const SizedBox(height: 3),
                Text(widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.w800 : FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

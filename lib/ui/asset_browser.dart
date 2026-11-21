import 'package:flutter/material.dart';

import '../domain/city_types.dart';
import 'prop_categories.dart';
import 'retro/vintage.dart';

/// Navegador de objetos (como os catálogos de assets dos editores de mapa): busca por nome,
/// abas de categoria e uma grade de miniaturas com o nome embaixo. Em "Tudo" a grade vem
/// separada por categoria; com busca, procura em todas.
class AssetBrowser extends StatefulWidget {
  const AssetBrowser({
    super.key,
    required this.items,
    required this.groups,
    required this.selected,
    required this.onPick,
    required this.label,
    required this.thumb,
    this.hint = 'Buscar objeto…',
  });

  final List<PropType> items;
  final List<PropGroup> groups;
  final PropType? selected;
  final ValueChanged<PropType> onPick;
  final String Function(PropType) label;
  final Widget Function(PropType) thumb;
  final String hint;

  @override
  State<AssetBrowser> createState() => _AssetBrowserState();
}

/// Tira acentos e caixa para a busca achar "arvore" em "Árvore".
String foldText(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    out.write(i < 0 ? ch : to[i]);
  }
  return out.toString();
}

class _AssetBrowserState extends State<AssetBrowser> {
  final _search = TextEditingController();
  PropGroup? _group;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = foldText(_search.text.trim());
    final present = [
      for (final g in widget.groups)
        if (widget.items.any((p) => PropGroup.of(p) == g)) g
    ];
    bool matches(PropType p) => query.isEmpty || foldText(widget.label(p)).contains(query);
    final searching = query.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(_search.clear)),
        ),
      ),
      if (!searching && present.length > 1) ...[
        const SizedBox(height: 8),
        // todas as categorias à vista (quebram linha), sem rolagem lateral escondida
        Wrap(runSpacing: 6, children: [
          _GroupTab(label: 'Tudo', selected: _group == null, onTap: () => setState(() => _group = null)),
          for (final g in present)
            _GroupTab(label: g.label, selected: _group == g, onTap: () => setState(() => _group = g)),
        ]),
      ],
      const SizedBox(height: 8),
      if (searching)
        _grid([for (final p in widget.items) if (matches(p)) p], emptyText: 'Nada com esse nome.')
      else
        for (final g in present)
          if (_group == null || _group == g) ...[
            if (_group == null && present.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(g.label.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .8, color: Vintage.muted)),
              ),
            _grid([for (final p in widget.items) if (PropGroup.of(p) == g) p]),
          ],
    ]);
  }

  Widget _grid(List<PropType> items, {String? emptyText}) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(emptyText ?? '', style: const TextStyle(color: Vintage.muted)),
      );
    }
    return LayoutBuilder(builder: (context, c) {
      const gap = 6.0;
      final cols = (c.maxWidth / 92).floor().clamp(2, 5);
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final p in items)
          SizedBox(
            width: w,
            child: AssetTile(
              selected: widget.selected == p,
              label: widget.label(p),
              thumb: widget.thumb(p),
              onTap: () => widget.onPick(p),
            ),
          ),
      ]);
    });
  }
}

class _GroupTab extends StatelessWidget {
  const _GroupTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: PaperChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}

/// Ladrilho de um item: miniatura em cima, nome embaixo; mostarda quando escolhido.
class AssetTile extends StatefulWidget {
  const AssetTile(
      {super.key, required this.selected, required this.label, required this.thumb, required this.onTap});
  final bool selected;
  final String label;
  final Widget thumb;
  final VoidCallback onTap;

  @override
  State<AssetTile> createState() => _AssetTileState();
}

class _AssetTileState extends State<AssetTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.selected;
    return Tooltip(
      message: widget.label,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
            decoration: BoxDecoration(
              color: on ? Vintage.mustard.withValues(alpha: .55) : (_hover ? Vintage.hotTop : Vintage.highlight),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: on ? Vintage.dark : Vintage.shadow, width: on ? 1.6 : 1),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(height: 50, child: Center(child: widget.thumb)),
              const SizedBox(height: 2),
              Text(widget.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, height: 1.15, fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }
}

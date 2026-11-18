import 'package:flutter/material.dart';

import 'retro/vintage.dart';

/// Cartão de um contexto do painel (o item selecionado, as ferramentas, as opções da
/// ferramenta, a geração...): fundo claro, contorno fino e título com ícone, para cada assunto
/// ficar separado dos outros.
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    this.highlight = false,
    required this.children,
  });

  final String? title;
  final IconData? icon;
  final Widget? trailing;

  /// Destaca o cartão (o item selecionado), com borda na cor de destaque.
  final bool highlight;
  final List<Widget> children;

  /// Está dentro de um cartão? (os títulos de seção ficam mais compactos.)
  static bool inCard(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_InCard>() != null;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Vintage.light,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlight ? Vintage.mustard : Vintage.shadow, width: highlight ? 2 : 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: _InCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Vintage.terracotta),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(title!.toUpperCase(),
                      style: tt.titleSmall?.copyWith(color: Vintage.terracotta, letterSpacing: 1.1)),
                ),
                if (trailing != null) trailing!,
              ]),
            ),
          ...children,
        ]),
      ),
    );
  }
}

class _InCard extends InheritedWidget {
  const _InCard({required super.child});
  @override
  bool updateShouldNotify(_InCard oldWidget) => false;
}

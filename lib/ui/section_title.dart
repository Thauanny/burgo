import 'package:flutter/material.dart';
import 'retro/vintage.dart';

/// Título de grupo em caixa-alta espaçada (terracota), com um fio de tinta ao lado.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 26, bottom: 10),
        child: Row(children: [
          Text(text.toUpperCase(),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 8),
          const Expanded(
              child: SizedBox(
                  height: 1.2,
                  child: DecoratedBox(
                      decoration: BoxDecoration(color: Vintage.shadow)))),
        ]),
      );
}

/// Rótulo de um grupo dentro de uma seção (ex.: "1 bloco ="), com respiro acima.
class SubLabel extends StatelessWidget {
  const SubLabel(this.text, {super.key, this.top = 12});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 6),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}

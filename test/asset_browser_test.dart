import 'package:burgo/domain/city_types.dart';
import 'package:burgo/ui/asset_browser.dart';
import 'package:burgo/ui/prop_categories.dart';
import 'package:burgo/ui/retro/vintage.dart';
import 'package:burgo/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navegador de objetos: busca sem acento, abas de categoria e escolha', (t) async {
    PropType? picked;
    const items = [PropType.tree, PropType.pine, PropType.well, PropType.fountain, PropType.barrel];
    await t.pumpWidget(MaterialApp(
      theme: vintageTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: AssetBrowser(
              items: items,
              groups: PropGroup.objectGroups,
              selected: PropType.pine,
              onPick: (p) => picked = p,
              label: (p) => Strings.propFor(p, 'generico'),
              thumb: (p) => const SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      ),
    ));
    expect(find.text('Árvore'), findsOneWidget);
    expect(find.text('Poço'), findsOneWidget);
    // busca sem acento
    await t.enterText(find.byType(TextField), 'arvore');
    await t.pump();
    expect(find.text('Árvore'), findsOneWidget);
    expect(find.text('Poço'), findsNothing);
    await t.enterText(find.byType(TextField), 'xyz');
    await t.pump();
    expect(find.text('Nada com esse nome.'), findsOneWidget);
    await t.enterText(find.byType(TextField), '');
    await t.pump();
    // aba de categoria
    await t.ensureVisible(find.text(PropGroup.village.label).first);
    await t.pumpAndSettle();
    await t.tap(find.text(PropGroup.village.label).first);
    await t.pump();
    expect(find.text('Árvore'), findsNothing);
    expect(find.text('Poço'), findsOneWidget);
    await t.tap(find.text('Poço'));
    expect(picked, PropType.well);
    expect(foldText('Lâmpada Élfica'), 'lampada elfica');
  });
}

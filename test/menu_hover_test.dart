import 'package:burgo/ui/retro/vintage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('item de menu fica destacado sob o mouse', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: vintageTheme(),
      home: Scaffold(
        body: Center(
          child: PopupMenuButton<int>(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('Salvar')),
              PopupMenuItem(value: 2, child: Text('Abrir')),
            ],
            child: const Text('Arquivo'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Arquivo'));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('Abrir')));
    await tester.pumpAndSettle();
    // o item do menu é um InkWell, que pinta o hoverColor do tema sob o mouse
    expect(find.ancestor(of: find.text('Abrir'), matching: find.byType(InkWell)), findsWidgets);
    expect(vintageTheme().hoverColor.a, greaterThan(0), reason: 'hover do tema não pode ser transparente');
    expect(vintageTheme().hoverColor, Vintage.hotBottom);
  });
}

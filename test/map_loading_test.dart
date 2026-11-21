import 'package:burgo/ui/map_loading_overlay.dart';
import 'package:burgo/ui/retro/vintage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Object key, {required VoidCallback onTap}) => MaterialApp(
        theme: vintageTheme(),
        home: Scaffold(
          body: Stack(children: [
            Positioned.fill(child: GestureDetector(onTap: onTap, child: const ColoredBox(color: Colors.green))),
            Positioned.fill(child: MapLoadingOverlay(warmKey: key, title: 'Vila', enabled: true)),
          ]),
        ),
      );

  bool shown(WidgetTester t) =>
      t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity == 1;

  testWidgets('aparece com cidade nova, segura o mapa e some quando os quadros firmam', (t) async {
    var taps = 0;
    await t.pumpWidget(host(1, onTap: () => taps++));
    expect(shown(t), isTrue);
    expect(find.text('Preparando o mapa…'), findsOneWidget);
    await t.tapAt(const Offset(200, 200));
    expect(taps, 0, reason: 'o mapa não recebe clique enquanto prepara');
    // quadros lentos (100 ms): continua
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(shown(t), isTrue);
    // quadros rápidos (16 ms) seguidos: some
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(shown(t), isFalse);
    await t.pump(const Duration(milliseconds: 400));
    await t.tapAt(const Offset(200, 200));
    expect(taps, 1, reason: 'depois o mapa volta a responder');
    // outra cidade: aparece de novo
    await t.pumpWidget(host(2, onTap: () => taps++));
    expect(shown(t), isTrue);
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(shown(t), isFalse);
  });

  testWidgets('nunca fica preso: some no tempo máximo mesmo com quadros lentos', (t) async {
    await t.pumpWidget(host(1, onTap: () {}));
    for (var i = 0; i < 80; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(shown(t), isFalse);
    await t.pump(const Duration(milliseconds: 400));
  });
}

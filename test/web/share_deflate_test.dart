@TestOn('browser')
library;

import 'package:burgo/project/share_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('o link com o projeto comprimido ida e volta no navegador (CompressionStream)', () async {
    const json = '{"app":"burgo","version":1,"kind":"city","data":{"x":[1,2,3],"nome":"Vila Ção"}}';
    final f = await ShareLink.projectFragment(json);
    expect(f, startsWith('p='));
    final back = await ShareLink.parse(f);
    expect((back! as SharedProject).projectJson, json);
  });
}

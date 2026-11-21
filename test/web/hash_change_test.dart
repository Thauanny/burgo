@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:burgo/ui/page_location_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('link colado com a página aberta: o app recebe o novo # e limpa o endereço', () async {
    final got = Completer<String>();
    onPageHashChange((h) {
      if (h.isNotEmpty && !got.isCompleted) got.complete(h);
    });
    (globalContext['location']! as JSObject).setProperty('hash'.toJS, 'g=abc'.toJS);
    expect(await got.future.timeout(const Duration(seconds: 5)), 'g=abc');
    clearPageHash();
    expect(pageHash(), '');
  });
}

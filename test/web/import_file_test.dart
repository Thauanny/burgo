@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:burgo/persistence/storage_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('importar arquivo: o seletor fica na página e devolve o texto do arquivo escolhido', () async {
    final storage = WebProjectStorage();
    final future = storage.pickFile();
    final doc = globalContext['document']! as JSObject;
    final input = doc.callMethod<JSObject?>('querySelector'.toJS, 'input[type=file]'.toJS);
    expect(input, isNotNull, reason: 'o campo de arquivo está na página enquanto o seletor está aberto');
    // escolhe um arquivo como o navegador faria
    final parts = <JSAny>['{"burgo":1,"ok":true}'.toJS].toJS;
    final file = (globalContext['File']! as JSFunction)
        .callAsConstructor<JSObject>(parts, 'cidade.burgo.json'.toJS);
    final dt = (globalContext['DataTransfer']! as JSFunction).callAsConstructor<JSObject>();
    (dt['items']! as JSObject).callMethod<JSAny?>('add'.toJS, file);
    input!.setProperty('files'.toJS, dt['files']);
    final event = (globalContext['Event']! as JSFunction).callAsConstructor<JSObject>('change'.toJS);
    input.callMethod<JSAny?>('dispatchEvent'.toJS, event);
    expect(await future, '{"burgo":1,"ok":true}');
    expect(doc.callMethod<JSObject?>('querySelector'.toJS, 'input[type=file]'.toJS), isNull,
        reason: 'o campo sai da página depois');
  });
}

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

JSObject get _location => globalContext['location']! as JSObject;

/// O que vem depois do `#` no endereço (sem o `#`).
String pageHash() {
  final h = (_location['hash'] as JSString?)?.toDart ?? '';
  return h.startsWith('#') ? h.substring(1) : h;
}

/// Endereço da página sem o `#...` (a base dos links de compartilhamento).
String pageAddress() {
  final href = (_location['href']! as JSString).toDart;
  final i = href.indexOf('#');
  return i < 0 ? href : href.substring(0, i);
}

/// Tira o `#...` do endereço sem recarregar (recarregar a página não abre o mapa de novo).
void clearPageHash() {
  final history = globalContext['history']! as JSObject;
  // estado vazio ({}), e não null: com null o navegador entende que faltam argumentos
  history.callMethod<JSAny?>('replaceState'.toJS, JSObject(), ''.toJS, pageAddress().toJS);
}

/// Chama [onHash] quando o `#...` do endereço muda com a página aberta (link do Burgo colado
/// na mesma aba do navegador: ele não recarrega a página, só troca o `#`).
void onPageHashChange(void Function(String hash) onHash) {
  globalContext.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'hashchange'.toJS,
      ((JSObject _) {
        onHash(pageHash());
      }).toJS);
}

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

JSFunction? _handler;

/// Com [on], o navegador pergunta antes de fechar ou recarregar a página (há abas com mudanças
/// não salvas na biblioteca nem exportadas). O texto da pergunta é o do próprio navegador.
void setUnloadGuard(bool on) {
  if (on && _handler == null) {
    final h = ((JSObject e) {
      e.callMethod<JSAny?>('preventDefault'.toJS);
      e.setProperty('returnValue'.toJS, ''.toJS);
    }).toJS;
    _handler = h;
    globalContext.callMethod<JSAny?>('addEventListener'.toJS, 'beforeunload'.toJS, h);
  } else if (!on && _handler != null) {
    globalContext.callMethod<JSAny?>('removeEventListener'.toJS, 'beforeunload'.toJS, _handler);
    _handler = null;
  }
}

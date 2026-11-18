import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Abre [url] numa nova aba. Endereço relativo (como `sobre.html`) segue o `<base href>` do
/// site, então no GitHub Pages vira `/burgo/sobre.html`.
void openPage(String url) =>
    globalContext.callMethod('open'.toJS, url.toJS, '_blank'.toJS);

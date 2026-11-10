import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'project_storage.dart';

ProjectStorage createProjectStorage() => WebProjectStorage();

/// Armazenamento do navegador: projetos no `localStorage`, exportação por download e importação por seletor de arquivo.
class WebProjectStorage implements ProjectStorage {
  static const _workspaceKey = 'burgo.workspace',
      _indexKey = 'burgo.index',
      _projectPrefix = 'burgo.project.';

  JSObject get _local => globalContext['localStorage']! as JSObject;

  String? _get(String key) {
    try {
      final v = _local.callMethod<JSAny?>('getItem'.toJS, key.toJS);
      return v.isA<JSString>() ? (v! as JSString).toDart : null;
    } catch (_) {
      return null; // modo privado ou armazenamento bloqueado
    }
  }

  void _set(String key, String value) {
    try {
      _local.callMethod<JSAny?>('setItem'.toJS, key.toJS, value.toJS);
    } catch (_) {
      // cota cheia ou bloqueado: o salvamento automático é "melhor esforço"
    }
  }

  void _remove(String key) {
    try {
      _local.callMethod<JSAny?>('removeItem'.toJS, key.toJS);
    } catch (_) {}
  }

  @override
  Future<String?> readWorkspace() async => _get(_workspaceKey);

  @override
  Future<void> writeWorkspace(String json) async => _set(_workspaceKey, json);

  List<SavedProject> _index() {
    final raw = _get(_indexKey);
    if (raw == null) return [];
    try {
      return [
        for (final j in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
          SavedProject.fromJson(j)
      ];
    } catch (_) {
      return [];
    }
  }

  void _writeIndex(List<SavedProject> items) =>
      _set(_indexKey, jsonEncode([for (final p in items) p.toJson()]));

  @override
  Future<List<SavedProject>> list() async =>
      _index()..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  @override
  Future<String?> read(String id) async => _get('$_projectPrefix$id');

  @override
  Future<void> write(SavedProject meta, String json) async {
    _set('$_projectPrefix${meta.id}', json);
    _writeIndex([..._index().where((p) => p.id != meta.id), meta]);
  }

  @override
  Future<void> delete(String id) async {
    _remove('$_projectPrefix$id');
    _writeIndex(_index().where((p) => p.id != id).toList());
  }

  @override
  Future<void> exportFile(String filename, String content) async {
    final doc = globalContext['document']! as JSObject;
    final a = doc.callMethod<JSObject>('createElement'.toJS, 'a'.toJS);
    a.setProperty(
        'href'.toJS,
        'data:application/json;charset=utf-8,${Uri.encodeComponent(content)}'
            .toJS);
    a.setProperty('download'.toJS, filename.toJS);
    final body = doc['body']! as JSObject;
    body.callMethod<JSAny?>('appendChild'.toJS, a);
    a.callMethod<JSAny?>('click'.toJS);
    body.callMethod<JSAny?>('removeChild'.toJS, a);
  }

  @override
  Future<void> exportBytes(String filename, Uint8List bytes, {String mime = 'image/png'}) async {
    // Blob + URL.createObjectURL: aguenta imagens grandes, que não cabem numa data URL
    final blobCtor = globalContext['Blob']! as JSFunction;
    final options = JSObject()..setProperty('type'.toJS, mime.toJS);
    final blob = blobCtor.callAsConstructor<JSObject>([bytes.toJS].toJS, options);
    final url = globalContext['URL']! as JSObject;
    final href = url.callMethod<JSString>('createObjectURL'.toJS, blob).toDart;
    final doc = globalContext['document']! as JSObject;
    final a = doc.callMethod<JSObject>('createElement'.toJS, 'a'.toJS);
    a.setProperty('href'.toJS, href.toJS);
    a.setProperty('download'.toJS, filename.toJS);
    final body = doc['body']! as JSObject;
    body.callMethod<JSAny?>('appendChild'.toJS, a);
    a.callMethod<JSAny?>('click'.toJS);
    body.callMethod<JSAny?>('removeChild'.toJS, a);
    url.callMethod<JSAny?>('revokeObjectURL'.toJS, href.toJS);
  }

  @override
  Future<String?> pickFile() {
    final completer = Completer<String?>();
    final doc = globalContext['document']! as JSObject;
    final input = doc.callMethod<JSObject>('createElement'.toJS, 'input'.toJS);
    input.setProperty('type'.toJS, 'file'.toJS);
    input.setProperty('accept'.toJS, '.json,application/json'.toJS);
    input.setProperty(
        'onchange'.toJS,
        ((JSObject _) {
          unawaited(_readChosen(input, completer));
        }).toJS);
    input.setProperty(
        'oncancel'.toJS,
        ((JSObject _) {
          if (!completer.isCompleted) completer.complete(null);
        }).toJS);
    input.callMethod<JSAny?>('click'.toJS);
    return completer.future;
  }

  /// Lê o arquivo escolhido (assíncrono, fora do callback que vai para o JavaScript).
  Future<void> _readChosen(JSObject input, Completer<String?> completer) async {
    try {
      final files = input['files']! as JSObject;
      final file = files.callMethod<JSObject?>('item'.toJS, 0.toJS);
      if (file == null) {
        completer.complete(null);
        return;
      }
      final text =
          await file.callMethod<JSPromise<JSString>>('text'.toJS).toDart;
      if (!completer.isCompleted) completer.complete(text.toDart);
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }
  }
}

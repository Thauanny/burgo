import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// Compressão deflate "crua" pelo `CompressionStream` do navegador (Chrome, Edge, Firefox e
/// Safari atuais).
Future<Uint8List> deflateRaw(Uint8List data) => _pipe(data, 'CompressionStream');

Future<Uint8List> inflateRaw(Uint8List data) => _pipe(data, 'DecompressionStream');

Future<Uint8List> _pipe(Uint8List data, String streamClass) async {
  final parts = <JSAny>[data.toJS].toJS;
  final blob = (globalContext['Blob']! as JSFunction).callAsConstructor<JSObject>(parts);
  final stream = blob.callMethod<JSObject>('stream'.toJS);
  final codec = (globalContext[streamClass]! as JSFunction).callAsConstructor<JSObject>('deflate-raw'.toJS);
  final piped = stream.callMethod<JSObject>('pipeThrough'.toJS, codec);
  final response = (globalContext['Response']! as JSFunction).callAsConstructor<JSObject>(piped);
  final buffer = await response.callMethod<JSPromise<JSArrayBuffer>>('arrayBuffer'.toJS).toDart;
  return buffer.toDart.asUint8List();
}

import 'dart:io';
import 'dart:typed_data';

/// Compressão deflate "crua" (sem cabeçalho), a mesma do `CompressionStream('deflate-raw')`
/// dos navegadores: um link feito num lugar abre no outro.
Future<Uint8List> deflateRaw(Uint8List data) async =>
    Uint8List.fromList(ZLibCodec(raw: true, level: 9).encode(data));

Future<Uint8List> inflateRaw(Uint8List data) async =>
    Uint8List.fromList(ZLibCodec(raw: true).decode(data));

import '../domain/tile_grid.dart';

/// Codificação compacta de grades: comprimentos de sequências alternadas, começando por "falso".
abstract final class TileGridCodec {
  static List<int> encode(TileGrid g) {
    final runs = <int>[];
    var current = false, count = 0;
    for (var x = 0; x < g.size; x++) {
      for (var y = 0; y < g.size; y++) {
        final v = g.at(x, y);
        if (v == current) {
          count++;
        } else {
          runs.add(count);
          current = v;
          count = 1;
        }
      }
    }
    runs.add(count);
    return runs;
  }

  static void decodeInto(List<dynamic> runs, TileGrid g) {
    var index = 0;
    var value = false;
    for (final r in runs) {
      final n = (r as num).toInt();
      if (value) {
        for (var i = 0; i < n; i++) {
          final cell = index + i;
          g.set(cell ~/ g.size, cell % g.size, true);
        }
      }
      index += n;
      value = !value;
    }
  }
}

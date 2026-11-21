import 'dart:typed_data';

/// Grade quadrada de flags por tile. Leituras fora dos limites devolvem `false`.
/// Guarda um byte por tile (uma lista de `bool` gastaria 8): mapas grandes como Valkaria e as
/// cópias do histórico de desfazer ficam bem mais leves.
class TileGrid {
  TileGrid(this.size) : _cells = Uint8List(size * size);

  final int size;
  final Uint8List _cells;

  /// Aumenta a cada mudança real; permite guardar desenhos em cache.
  int version = 0;

  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < size && y < size;

  bool at(int x, int y) => inBounds(x, y) && _cells[x * size + y] != 0;

  /// Quantos tiles estão marcados.
  int get count {
    var n = 0;
    for (final c in _cells) {
      n += c;
    }
    return n;
  }

  /// Ignora escritas fora dos limites.
  void set(int x, int y, bool value) {
    if (!inBounds(x, y)) return;
    final v = value ? 1 : 0;
    if (_cells[x * size + y] == v) return;
    _cells[x * size + y] = v;
    version++;
  }

  /// Copia [other] para esta grade, mexendo só nas células que mudam (o `version` só sobe se algo mudou).
  void replaceWith(TileGrid other) {
    for (var i = 0; i < _cells.length; i++) {
      if (_cells[i] != other._cells[i]) {
        _cells[i] = other._cells[i];
        version++;
      }
    }
  }

  /// Cópia em bloco de uma grade do mesmo tamanho (usada nas cópias do histórico).
  void copyFrom(TileGrid other) {
    assert(other.size == size);
    _cells.setAll(0, other._cells);
    version++;
  }

  /// Marca como verdadeiras as células de [other].
  void addAll(TileGrid other) {
    for (var i = 0; i < _cells.length; i++) {
      if (other._cells[i] != 0 && _cells[i] == 0) {
        _cells[i] = 1;
        version++;
      }
    }
  }
}

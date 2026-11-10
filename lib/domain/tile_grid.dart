/// Grade quadrada de flags por tile. Leituras fora dos limites devolvem `false`.
class TileGrid {
  TileGrid(this.size) : _cells = List.filled(size * size, false);

  final int size;
  final List<bool> _cells;

  /// Aumenta a cada mudança real; permite guardar desenhos em cache.
  int version = 0;

  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < size && y < size;

  bool at(int x, int y) => inBounds(x, y) && _cells[x * size + y];

  /// Ignora escritas fora dos limites.
  void set(int x, int y, bool value) {
    if (!inBounds(x, y) || _cells[x * size + y] == value) return;
    _cells[x * size + y] = value;
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

  /// Marca como verdadeiras as células de [other].
  void addAll(TileGrid other) {
    for (var i = 0; i < _cells.length; i++) {
      if (other._cells[i] && !_cells[i]) {
        _cells[i] = true;
        version++;
      }
    }
  }
}

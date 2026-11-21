import 'package:burgo/editor/viewport.dart';
import 'package:burgo/render/raster_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('durante o zoom a resolução das imagens de cache não muda; quando para, muda', () {
    final s = RasterScaler();
    final first = s.update(zoom: .5, devicePixelRatio: 2, sceneArea: 1e5);
    // zoom bem maior, ainda em andamento: mantém (as imagens só esticam)
    expect(s.update(zoom: 2, devicePixelRatio: 2, sceneArea: 1e5, settled: false), first);
    // a câmera parou: agora troca
    expect(s.update(zoom: 2, devicePixelRatio: 2, sceneArea: 1e5), greaterThan(first));
  });

  test('o viewport sabe quando a câmera acabou de mexer', () {
    final v = Viewport();
    expect(v.interacting, isFalse);
    v.zoomAround(const Offset(100, 100), v.zoom * 1.2);
    expect(v.interacting, isTrue);
    v.setHover(null); // passar o mouse não conta como mexer a câmera
  });
}

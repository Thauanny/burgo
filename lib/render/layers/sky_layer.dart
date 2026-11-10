import 'package:flutter/painting.dart';
import '../scene_view.dart';

/// Céu em degradê (cores do sistema) com nuvens que passam devagar.
class SkyLayer {
  const SkyLayer();

  void paint(Canvas cv, Size size, SceneView scene) {
    final art = scene.system.art;
    final rect = Offset.zero & size;
    cv.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [art.skyTop, art.skyBottom],
        ).createShader(rect),
    );
    final cloud = Paint()..color = const Color.fromRGBO(255, 255, 255, .35);
    for (var i = 0; i < 5; i++) {
      final speed = 6 + i * 2.5;
      final x =
          ((scene.time * speed + i * size.width / 5) % (size.width + 240)) -
              120;
      final y = size.height * (.08 + (i * 37 % 40) / 100);
      for (final (dx, dy, r) in [
        (0.0, 0.0, 22.0),
        (22.0, -6.0, 28.0),
        (50.0, 2.0, 20.0)
      ]) {
        cv.drawOval(
            Rect.fromCenter(
                center: Offset(x + dx, y + dy), width: r * 2.2, height: r),
            cloud);
      }
    }
    // luz do sol suave nos cantos
    cv.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
              center: Alignment(-.8, -.9),
              radius: 1.2,
              colors: [
                Color.fromRGBO(255, 244, 214, .35),
                Color(0x00FFF4D6)
              ]).createShader(rect));
  }
}

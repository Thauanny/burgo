import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../geometry/iso.dart';
import 'layers/annotation_layer.dart';
import 'layers/atmosphere_layer.dart';
import 'layers/compass_layer.dart';
import 'layers/entities_layer.dart';
import 'layers/ground_layer.dart';
import 'layers/overlay_layer.dart';
import 'layers/paper_layer.dart';
import 'layers/sky_layer.dart';
import 'layers/zone_effects_layer.dart';
import 'raster_image.dart';
import 'scene_view.dart';

/// Compõe as camadas do mapa. Repinta quando [repaint] notifica.
/// Receba a [ground] de fora: o cache do terreno precisa sobreviver entre quadros.
class CityPainter extends CustomPainter {
  CityPainter(this.scene,
      {required Listenable repaint,
      GroundLayer? ground,
      EntitiesLayer? entities,
      PaperLayer? paper})
      : ground = ground ?? GroundLayer(),
        entities = entities ?? EntitiesLayer(),
        paper = paper ?? PaperLayer(),
        super(repaint: repaint);

  final SceneView scene;
  final GroundLayer ground;
  final EntitiesLayer entities;
  final PaperLayer paper;
  final RasterScaler _scaler = RasterScaler();
  static const _sky = SkyLayer();
  final ZoneEffectsLayer _zone = ZoneEffectsLayer();
  final AtmosphereLayer _atmosphere = AtmosphereLayer();
  final AnnotationLayer _annotations = AnnotationLayer();
  final CompassLayer _compass = CompassLayer();

  @override
  void paint(Canvas canvas, Size size) {
    Iso.configure(scene.viewMode, scene.rotation, scene.city.tilesX,
        scene.city.tilesY);
    final bounds = GroundLayer.boundsOf(scene.city, scene.settlement.floating);
    final scale = _scaler.update(
      zoom: scene.zoom,
      devicePixelRatio: PlatformDispatcher.instance.views.isEmpty
          ? 1
          : PlatformDispatcher.instance.views.first.devicePixelRatio,
      sceneArea: bounds.width * bounds.height,
    );
    _sky.paint(canvas, size, scene);
    canvas.save();
    canvas.translate(scene.pan.dx, scene.pan.dy);
    canvas.scale(scene.zoom);
    ground.paint(canvas, scene, scale);
    _atmosphere.paint(canvas, scene);
    _zone.paintGround(canvas, scene);
    entities.paint(canvas, scene, scale);
    _zone.paintAir(canvas, scene);
    OverlayLayer(entities).paint(canvas, scene);
    canvas.restore();
    _annotations.paint(canvas, scene, size);
    _compass.paint(canvas, size);
    paper.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CityPainter old) => true;
}

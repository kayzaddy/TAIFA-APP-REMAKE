import 'package:flutter/material.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../domain/geo_point.dart';
import '../../domain/map_scene.dart';
import '../../domain/route_plan.dart';

/// Simulated map canvas used by [MockMapsProvider]. Projects [GeoPoint]s into
/// a local frame so Google/Mapbox adapters can replace this painter later.
class MockMapView extends StatelessWidget {
  const MockMapView({super.key, required this.scene});

  final MapScene scene;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPainter(scene: scene),
      child: const SizedBox.expand(),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.scene});

  final MapScene scene;

  GeoPoint get center => scene.effectiveCenter;
  RoutePlan? get route => scene.route;
  GeoPoint? get pickup => scene.pickup;
  GeoPoint? get dropoff => scene.dropoff;
  GeoPoint? get driver => scene.driver;
  double get progress => scene.progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0B1F18);
    canvas.drawRect(Offset.zero & size, bg);

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              TaifaColors.emerald700.withValues(alpha: 0.45),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: size.center(Offset.zero),
              radius: size.shortestSide * 0.7,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);

    _drawGrid(canvas, size);

    final points = <GeoPoint>[
      center,
      ?pickup,
      ?dropoff,
      ?driver,
      ...?route?.polyline,
    ];
    // Tighter pad when following so the moving driver stays framed.
    final pad = scene.followDriver ? 0.22 : 0.35;
    final projector = _Projector(
      size,
      points.isEmpty ? [center] : points,
      padFactor: pad,
    );

    if (route != null && route!.polyline.length >= 2) {
      final path = Path();
      final first = projector.project(route!.polyline.first);
      path.moveTo(first.dx, first.dy);
      for (final p in route!.polyline.skip(1)) {
        final o = projector.project(p);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = TaifaColors.gold500.withValues(alpha: 0.28)
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = TaifaColors.gold400
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Traversed segment highlight during in-trip progress.
      if (progress > 0) {
        final traversed = Path();
        final endT = progress.clamp(0.0, 1.0);
        final end = route!.pointAt(endT);
        final endIdx = ((route!.polyline.length - 1) * endT).floor().clamp(
          0,
          route!.polyline.length - 1,
        );
        final startPt = projector.project(route!.polyline.first);
        traversed.moveTo(startPt.dx, startPt.dy);
        for (var i = 1; i <= endIdx; i++) {
          final o = projector.project(route!.polyline[i]);
          traversed.lineTo(o.dx, o.dy);
        }
        final endO = projector.project(end);
        traversed.lineTo(endO.dx, endO.dy);
        canvas.drawPath(
          traversed,
          Paint()
            ..color = TaifaColors.ocean400.withValues(alpha: 0.85)
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    if (pickup != null) {
      _pin(canvas, projector.project(pickup!), TaifaColors.emerald500);
    }
    if (dropoff != null) {
      _pin(canvas, projector.project(dropoff!), TaifaColors.gold400);
    }
    if (driver != null) {
      final o = projector.project(driver!);
      canvas.drawCircle(
        o,
        14,
        Paint()..color = TaifaColors.black800.withValues(alpha: 0.55),
      );
      canvas.drawCircle(o, 10, Paint()..color = TaifaColors.ocean400);
      canvas.drawCircle(o, 4, Paint()..color = Colors.white);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 42.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _pin(Canvas canvas, Offset o, Color color) {
    canvas.drawCircle(o, 16, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(o, 9, Paint()..color = color);
    canvas.drawCircle(o, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.scene.cameraTarget != scene.cameraTarget ||
      oldDelegate.scene.route != scene.route ||
      oldDelegate.scene.pickup != scene.pickup ||
      oldDelegate.scene.dropoff != scene.dropoff ||
      oldDelegate.scene.driver != scene.driver ||
      oldDelegate.scene.progress != scene.progress ||
      oldDelegate.scene.followDriver != scene.followDriver;
}

class _Projector {
  _Projector(this.size, List<GeoPoint> points, {this.padFactor = 0.35}) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    final padLat = ((maxLat - minLat).abs() < 0.01
        ? 0.01
        : (maxLat - minLat) * padFactor);
    final padLon = ((maxLon - minLon).abs() < 0.01
        ? 0.01
        : (maxLon - minLon) * padFactor);
    _minLat = minLat - padLat;
    _maxLat = maxLat + padLat;
    _minLon = minLon - padLon;
    _maxLon = maxLon + padLon;
  }

  final Size size;
  final double padFactor;
  late final double _minLat, _maxLat, _minLon, _maxLon;

  Offset project(GeoPoint p) {
    final x = (p.longitude - _minLon) / (_maxLon - _minLon);
    final y = 1 - (p.latitude - _minLat) / (_maxLat - _minLat);
    const inset = 48.0;
    return Offset(
      inset + x * (size.width - inset * 2),
      inset + y * (size.height - inset * 2),
    );
  }
}

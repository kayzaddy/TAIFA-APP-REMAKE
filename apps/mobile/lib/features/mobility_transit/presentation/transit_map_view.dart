import 'package:flutter/material.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../mobility/domain/geo_point.dart';
import '../domain/transit_models.dart';

/// Corridor map painter for BRT live tracking (Phase 3).
class TransitMapView extends StatelessWidget {
  const TransitMapView({super.key, required this.liveMap});

  final TransitLiveMap liveMap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TransitMapPainter(liveMap: liveMap),
      child: const SizedBox.expand(),
    );
  }
}

class _TransitMapPainter extends CustomPainter {
  _TransitMapPainter({required this.liveMap});

  final TransitLiveMap liveMap;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0B1F18));

    final points = <GeoPoint>[
      ...liveMap.stations.map((s) => GeoPoint(s.latitude, s.longitude)),
      ...liveMap.vehicles.map((v) => GeoPoint(v.latitude, v.longitude)),
    ];
    if (points.isEmpty) return;

    final projector = _Projector(size, points);

    for (final route in liveMap.routes) {
      final polyline = route.polyline;
      if (polyline.length < 2) continue;
      final path = Path();
      final first = projector.project(
        GeoPoint(
          (polyline.first['lat'] as num?)?.toDouble() ?? 0,
          (polyline.first['lng'] as num?)?.toDouble() ?? 0,
        ),
      );
      path.moveTo(first.dx, first.dy);
      for (final stop in polyline.skip(1)) {
        final o = projector.project(
          GeoPoint(
            (stop['lat'] as num?)?.toDouble() ?? 0,
            (stop['lng'] as num?)?.toDouble() ?? 0,
          ),
        );
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = TaifaColors.emerald500.withValues(alpha: 0.35)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = TaifaColors.gold400
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final station in liveMap.stations) {
      _pin(canvas, projector.project(GeoPoint(station.latitude, station.longitude)), TaifaColors.gold400, 8);
    }

    for (final vehicle in liveMap.vehicles) {
      final o = projector.project(GeoPoint(vehicle.latitude, vehicle.longitude));
      canvas.drawCircle(o, 16, Paint()..color = Colors.black.withValues(alpha: 0.45));
      canvas.drawCircle(o, 12, Paint()..color = TaifaColors.ocean400);
      canvas.drawCircle(o, 4, Paint()..color = Colors.white);
    }
  }

  void _pin(Canvas canvas, Offset o, Color color, double r) {
    canvas.drawCircle(o, r + 6, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(o, r, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TransitMapPainter oldDelegate) =>
      oldDelegate.liveMap != liveMap;
}

class _Projector {
  _Projector(this.size, List<GeoPoint> points) {
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
    final padLat = ((maxLat - minLat).abs() < 0.01 ? 0.01 : (maxLat - minLat) * 0.2);
    final padLon = ((maxLon - minLon).abs() < 0.01 ? 0.01 : (maxLon - minLon) * 0.2);
    _minLat = minLat - padLat;
    _maxLat = maxLat + padLat;
    _minLon = minLon - padLon;
    _maxLon = maxLon + padLon;
  }

  final Size size;
  late final double _minLat, _maxLat, _minLon, _maxLon;

  Offset project(GeoPoint p) {
    final x = (p.longitude - _minLon) / (_maxLon - _minLon);
    final y = 1 - (p.latitude - _minLat) / (_maxLat - _minLat);
    const inset = 40.0;
    return Offset(
      inset + x * (size.width - inset * 2),
      inset + y * (size.height - inset * 2),
    );
  }
}

import 'package:flutter/material.dart';

import '../../mobility/domain/geo_point.dart';
import '../../mobility/domain/map_scene.dart';
import '../../mobility/gateways/mock_maps_provider.dart';
import '../domain/property_models.dart';

/// Discovery map using Mobility [MapsProvider] — pins as dropoff markers.
class PropertyDiscoveryMap extends StatelessWidget {
  const PropertyDiscoveryMap({
    super.key,
    required this.pins,
    required this.clusters,
    required this.onTap,
    this.selectedId,
  });

  final List<PropertyMapPin> pins;
  final List<PropertyMapCluster> clusters;
  final Future<void> Function(String) onTap;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final center = pins.isNotEmpty
        ? GeoPoint(pins.first.lat, pins.first.lng)
        : const GeoPoint(-6.7920, 39.2080);
    final selectedPin = pins.where((p) => p.id == selectedId).firstOrNull;
    final scene = MapScene(
      cameraTarget: selectedPin != null
          ? GeoPoint(selectedPin.lat, selectedPin.lng)
          : center,
      dropoff: selectedPin != null ? GeoPoint(selectedPin.lat, selectedPin.lng) : null,
    );

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MockMapsProvider().buildMap(scene: scene),
          ),
        ),
        if (clusters.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: clusters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final c = clusters[i];
                return ActionChip(
                  label: Text('${c.count} listings'),
                  onPressed: () {
                    if (c.pins.isNotEmpty) onTap(c.pins.first.id);
                  },
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pins.length,
            itemBuilder: (_, i) {
              final p = pins[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text('${p.title} · ${p.price.format()}'),
                  onPressed: () => onTap(p.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

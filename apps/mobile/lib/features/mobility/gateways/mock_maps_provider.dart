import 'package:flutter/widgets.dart';

import '../domain/map_scene.dart';
import '../presentation/widgets/mock_map_view.dart';
import 'maps_provider.dart';

/// Default maps adapter — CustomPaint canvas, no API keys.
class MockMapsProvider implements MapsProvider {
  const MockMapsProvider();

  @override
  Widget buildMap({Key? key, required MapScene scene}) {
    return MockMapView(key: key, scene: scene);
  }
}

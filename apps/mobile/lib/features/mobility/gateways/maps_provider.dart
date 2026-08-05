import 'package:flutter/widgets.dart';

import '../domain/map_scene.dart';

/// Maps SDK boundary. Demo uses [MockMapsProvider]; production swaps in
/// Google/Mapbox without changing Mobility screens or ride orchestration.
abstract interface class MapsProvider {
  Widget buildMap({Key? key, required MapScene scene});
}

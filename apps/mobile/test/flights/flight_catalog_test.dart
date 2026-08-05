import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/flights/application/flight_providers.dart';
import 'package:taifa/features/flights/data/flight_catalog.dart';

void main() {
  test('Flight catalog returns DAR→ZNZ offers', () {
    final offers = FlightCatalog.search(
      originCode: 'DAR',
      destinationCode: 'ZNZ',
      date: DateTime(2026, 8, 10),
    );
    expect(offers, isNotEmpty);
  });

  test('FlightController can search and select', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(flightControllerProvider.notifier);
    await ctrl.bootstrap();
    await ctrl.search();
    final state = container.read(flightControllerProvider);
    expect(state.results, isNotEmpty);
    ctrl.selectOffer(state.results.first);
    expect(
      container.read(flightControllerProvider).phase,
      FlightPhase.checkout,
    );
  });
}

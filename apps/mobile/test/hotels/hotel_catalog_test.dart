import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/hotels/application/stay_providers.dart';
import 'package:taifa/features/hotels/data/hotel_catalog.dart';

void main() {
  test('Hotel catalog has rooms', () {
    final all = HotelCatalog.all();
    expect(all, isNotEmpty);
    expect(all.first.rooms, isNotEmpty);
  });

  test('StayController computes nights and totals', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(stayControllerProvider.notifier);
    await ctrl.bootstrap();
    final hotel = HotelCatalog.all().first;
    ctrl.openHotel(hotel);
    ctrl.openRooms();
    ctrl.selectRoom(hotel.rooms.first);
    final state = container.read(stayControllerProvider);
    expect(state.nights, greaterThanOrEqualTo(1));
    expect(state.total.minorUnits, greaterThan(0));
    expect(state.phase, StayPhase.checkout);
  });
}

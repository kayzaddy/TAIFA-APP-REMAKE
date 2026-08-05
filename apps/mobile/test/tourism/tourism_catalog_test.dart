import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/tourism/application/seed_tourism_assist_repository.dart';
import 'package:taifa/features/tourism/application/seed_tourism_trip_repository.dart';
import 'package:taifa/features/tourism/application/tourism_providers.dart';
import 'package:taifa/features/tourism/application/tourism_trip_repository.dart';
import 'package:taifa/features/tourism/data/tourism_catalog.dart';

void main() {
  test('Tourism catalog has experiences', () {
    expect(TourismCatalog.all(), isNotEmpty);
  });

  test('TourismController opens checkout with total', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(tourismControllerProvider.notifier);
    await ctrl.bootstrap();
    final tour = TourismCatalog.all().first;
    ctrl.openTour(tour);
    ctrl.goCheckout();
    final state = container.read(tourismControllerProvider);
    expect(state.phase, TourismPhase.checkout);
    expect(state.total.minorUnits, greaterThan(0));
  });

  test('Trip plan flow selects itinerary', () async {
    final container = ProviderContainer(
      overrides: [
        tourismTripRepositoryProvider.overrideWithValue(
          SeedTourismTripRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final ctrl = container.read(tourismControllerProvider.notifier);
    await ctrl.bootstrap();
    ctrl.startPlanFlow();
    await ctrl.submitPlan();
    var state = container.read(tourismControllerProvider);
    expect(state.phase, TourismPhase.planOptions);
    expect(state.tripItineraries, isNotEmpty);
    final first = state.tripItineraries.first;
    await ctrl.confirmItinerary(first.id);
    state = container.read(tourismControllerProvider);
    expect(state.phase, TourismPhase.tripHub);
    expect(state.activeTrip?.selectedItineraryId, first.id);
  });

  test('Unified checkout pays trip with insurance', () async {
    final tripRepo = SeedTourismTripRepository();
    final trip = await tripRepo.createTrip(partySize: 2);
    await tripRepo.attachBooking(
      tripId: trip.id,
      bookingType: 'tour',
      bookingId: 'tour-booking-1',
    );
    final cart = await tripRepo.buildCart(trip.id);
    expect(cart.travelSubtotalMinor, greaterThan(0));
    expect(cart.insuranceQuote, isNotNull);

    final checkout = await tripRepo.createCheckout(
      tripId: trip.id,
      includeInsurance: true,
    );
    expect(checkout.includeInsurance, isTrue);
    expect(checkout.totalMinor, greaterThan(cart.travelSubtotalMinor));

    final paid = await tripRepo.payCheckout(
      tripId: trip.id,
      idempotencyKey: 'test-key',
    );
    expect(paid.isPaid, isTrue);
    expect(paid.insurancePolicyId, isNotNull);
  });

  test('Tourism assist SOS seed', () async {
    final repo = SeedTourismAssistRepository();
    final caseRow = await repo.sendSos(tripId: 'trip-1', notes: 'test');
    expect(caseRow.kind, 'sos');
    expect(caseRow.safetyIncidentId, isNotNull);
  });
}

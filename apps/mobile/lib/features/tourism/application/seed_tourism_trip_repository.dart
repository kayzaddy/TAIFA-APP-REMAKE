import 'package:uuid/uuid.dart';

import 'tourism_trip_repository.dart';
import '../domain/tourism_checkout_models.dart';
import '../domain/tourism_connectivity_models.dart';
import '../domain/tourism_trip_models.dart';

class SeedTourismTripRepository implements TourismTripRepository {
  final List<TourismTrip> _trips = [];
  final Map<String, List<TourismItinerary>> _itineraries = {};
  final Map<String, TourismCheckout> _checkouts = {};

  @override
  Future<List<TourismTrip>> listTrips() async => List.unmodifiable(_trips);

  @override
  Future<TourismTrip> createTrip({
    String title = 'My Tanzania trip',
    int partySize = 2,
    String budgetTier = 'mid',
    String travelStyle = 'leisure',
    List<String> interests = const [],
    DateTime? startDate,
  }) async {
    final id = const Uuid().v4();
    final trip = TourismTrip(
      id: id,
      title: title,
      status: 'planning',
      partySize: partySize,
      budgetTier: budgetTier,
      travelStyle: travelStyle,
      interests: interests,
      tourBookingIds: const [],
      stayBookingIds: const [],
      startDate: startDate,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    _trips.insert(0, trip);
    return trip;
  }

  @override
  Future<({TourismTrip trip, List<TourismItinerary> itineraries})> planTrip({
    required String tripId,
    int? partySize,
    String? budgetTier,
    String? travelStyle,
    List<String>? interests,
    DateTime? startDate,
  }) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx < 0) throw StateError('trip not found');
    final current = _trips[idx];
    final trip = TourismTrip(
      id: current.id,
      title: current.title,
      status: 'planning',
      partySize: partySize ?? current.partySize,
      budgetTier: budgetTier ?? current.budgetTier,
      travelStyle: travelStyle ?? current.travelStyle,
      interests: interests ?? current.interests,
      tourBookingIds: current.tourBookingIds,
      stayBookingIds: current.stayBookingIds,
      startDate: startDate ?? current.startDate,
      selectedItineraryId: current.selectedItineraryId,
      createdAt: current.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    _trips[idx] = trip;

    final itineraries = [
      TourismItinerary(
        id: const Uuid().v4(),
        tripId: tripId,
        version: 1,
        label: 'Safari + Zanzibar classic',
        summary: 'Northern circuit then beach',
        estimateMinor: 4_200_000_00,
        currency: 'TZS',
        days: const [
          TourismItineraryDay(
            day: 1,
            title: 'Arrival Dar es Salaam',
            items: [
              TourismItineraryItem(time: '14:00', title: 'Airport pickup', kind: 'transfer'),
            ],
          ),
          TourismItineraryDay(
            day: 2,
            title: 'Serengeti game drive',
            items: [
              TourismItineraryItem(time: '06:00', title: 'Game drive', kind: 'safari'),
            ],
          ),
        ],
      ),
      TourismItinerary(
        id: const Uuid().v4(),
        tripId: tripId,
        version: 2,
        label: 'Zanzibar escape',
        summary: 'Short beach break',
        estimateMinor: 1_500_000_00,
        currency: 'TZS',
        days: const [
          TourismItineraryDay(
            day: 1,
            title: 'Stone Town',
            items: [
              TourismItineraryItem(time: '10:00', title: 'Heritage walk', kind: 'culture'),
            ],
          ),
        ],
      ),
    ];
    _itineraries[tripId] = itineraries;
    return (trip: trip, itineraries: itineraries);
  }

  @override
  Future<TourismTrip> selectItinerary({
    required String tripId,
    required String itineraryId,
  }) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx < 0) throw StateError('trip not found');
    final current = _trips[idx];
    final trip = TourismTrip(
      id: current.id,
      title: current.title,
      status: 'ready',
      partySize: current.partySize,
      budgetTier: current.budgetTier,
      travelStyle: current.travelStyle,
      interests: current.interests,
      tourBookingIds: current.tourBookingIds,
      stayBookingIds: current.stayBookingIds,
      startDate: current.startDate,
      endDate: current.startDate?.add(const Duration(days: 7)),
      selectedItineraryId: itineraryId,
      createdAt: current.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    _trips[idx] = trip;
    return trip;
  }

  @override
  Future<TourismTrip> attachBooking({
    required String tripId,
    required String bookingType,
    required String bookingId,
  }) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx < 0) throw StateError('trip not found');
    final current = _trips[idx];
    final tours = List<String>.from(current.tourBookingIds);
    final stays = List<String>.from(current.stayBookingIds);
    if (bookingType == 'tour') {
      if (!tours.contains(bookingId)) tours.add(bookingId);
    } else {
      if (!stays.contains(bookingId)) stays.add(bookingId);
    }
    final trip = TourismTrip(
      id: current.id,
      title: current.title,
      status: current.status == 'planning' ? 'ready' : current.status,
      partySize: current.partySize,
      budgetTier: current.budgetTier,
      travelStyle: current.travelStyle,
      interests: current.interests,
      tourBookingIds: tours,
      stayBookingIds: stays,
      startDate: current.startDate,
      endDate: current.endDate,
      selectedItineraryId: current.selectedItineraryId,
      createdAt: current.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    _trips[idx] = trip;
    return trip;
  }

  @override
  Future<List<TourismItinerary>> listItineraries(String tripId) async =>
      List.unmodifiable(_itineraries[tripId] ?? const []);

  TourismCart _seedCart(TourismTrip trip, {bool includeInsuranceQuote = true}) {
    final lines = <TourismCartLine>[];
    var travel = 0;
    for (final id in trip.tourBookingIds) {
      const minor = 6_500_000;
      travel += minor;
      lines.add(
        TourismCartLine(
          section: 'travel',
          kind: 'tour',
          refId: id,
          title: 'Experience booking',
          amountMinor: minor,
          currency: 'TZS',
        ),
      );
    }
    for (final id in trip.stayBookingIds) {
      const minor = 12_000_000;
      travel += minor;
      lines.add(
        TourismCartLine(
          section: 'travel',
          kind: 'stay',
          refId: id,
          title: 'Stay booking',
          amountMinor: minor,
          currency: 'TZS',
        ),
      );
    }
    TourismTravelInsuranceQuote? quote;
    var protection = 0;
    if (includeInsuranceQuote) {
      protection = 2_500_000 * trip.partySize;
      quote = TourismTravelInsuranceQuote(
        planId: 'ins-travel',
        planName: 'Safari Travel Cover',
        provider: 'Strategies Insurance',
        premiumMinor: protection,
        coverageMinor: 200_000_000,
      );
      lines.add(
        TourismCartLine(
          section: 'protection',
          kind: 'insurance_quote',
          refId: 'ins-travel',
          title: quote.planName,
          amountMinor: protection,
          currency: 'TZS',
          optional: true,
          provider: quote.provider,
        ),
      );
    }
    TourismEsimQuote? esimQuote;
    var connectivity = 0;
    const esimMinor = 1_500_000;
    connectivity = esimMinor;
    esimQuote = const TourismEsimQuote(
      planId: 'esim-7d-5gb',
      planName: 'Tanzania 7 days · 5 GB',
      dataGb: 5,
      days: 7,
      priceMinor: esimMinor,
    );
    lines.add(
      TourismCartLine(
        section: 'connectivity',
        kind: 'esim_quote',
        refId: 'esim-7d-5gb',
        title: esimQuote.planName,
        amountMinor: esimMinor,
        currency: 'TZS',
        optional: true,
      ),
    );
    return TourismCart(
      tripId: trip.id,
      lines: lines,
      travelSubtotalMinor: travel,
      protectionSubtotalMinor: protection,
      connectivitySubtotalMinor: connectivity,
      totalMinor: travel + protection + connectivity,
      insuranceQuote: quote,
      esimQuote: esimQuote,
    );
  }

  @override
  Future<TourismCart> buildCart(
    String tripId, {
    bool includeInsuranceQuote = true,
  }) async {
    final trip = _requireTrip(tripId);
    return _seedCart(trip, includeInsuranceQuote: includeInsuranceQuote);
  }

  @override
  Future<TourismCheckout> createCheckout({
    required String tripId,
    bool includeInsurance = false,
    String insurancePlanId = 'ins-travel',
    bool includeEsim = false,
    String esimPlanId = 'esim-7d-5gb',
  }) async {
    final trip = _requireTrip(tripId);
    final cart = _seedCart(trip);
    final travel = cart.travelSubtotalMinor;
    var protection = 0;
    var connectivity = 0;
    final lineList = List<TourismCartLine>.from(cart.travelLines);
    if (includeInsurance && cart.insuranceQuote != null) {
      protection = cart.insuranceQuote!.premiumMinor;
      lineList.addAll(cart.lines.where((l) => l.section == 'protection'));
    }
    if (includeEsim && cart.esimQuote != null) {
      connectivity = cart.esimQuote!.priceMinor;
      lineList.addAll(cart.lines.where((l) => l.section == 'connectivity'));
    }
    final total = travel + protection + connectivity;
    if (total <= 0) {
      throw StateError('nothing to checkout');
    }
    final checkout = TourismCheckout(
      id: const Uuid().v4(),
      tripId: tripId,
      status: 'ready',
      includeInsurance: includeInsurance,
      includeEsim: includeEsim,
      lines: lineList,
      travelSubtotalMinor: travel,
      protectionSubtotalMinor: protection,
      connectivitySubtotalMinor: connectivity,
      totalMinor: total,
    );
    _checkouts[tripId] = checkout;
    return checkout;
  }

  @override
  Future<TourismCheckout> payCheckout({
    required String tripId,
    required String idempotencyKey,
  }) async {
    final checkout = _checkouts[tripId];
    if (checkout == null) throw StateError('checkout not found');
    if (checkout.isPaid) return checkout;
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx >= 0) {
      final t = _trips[idx];
      _trips[idx] = TourismTrip(
        id: t.id,
        title: t.title,
        status: 'active',
        partySize: t.partySize,
        budgetTier: t.budgetTier,
        travelStyle: t.travelStyle,
        interests: t.interests,
        tourBookingIds: t.tourBookingIds,
        stayBookingIds: t.stayBookingIds,
        startDate: t.startDate,
        endDate: t.endDate,
        selectedItineraryId: t.selectedItineraryId,
        createdAt: t.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
    }
    final paid = TourismCheckout(
      id: checkout.id,
      tripId: checkout.tripId,
      status: 'paid',
      includeInsurance: checkout.includeInsurance,
      includeEsim: checkout.includeEsim,
      lines: checkout.lines,
      travelSubtotalMinor: checkout.travelSubtotalMinor,
      protectionSubtotalMinor: checkout.protectionSubtotalMinor,
      connectivitySubtotalMinor: checkout.connectivitySubtotalMinor,
      totalMinor: checkout.totalMinor,
      insurancePolicyId: checkout.includeInsurance ? const Uuid().v4() : null,
      esimOrderId: checkout.includeEsim ? const Uuid().v4() : null,
      paymentRef: 'SEED-$idempotencyKey',
    );
    _checkouts[tripId] = paid;
    return paid;
  }

  TourismTrip _requireTrip(String tripId) {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx < 0) throw StateError('trip not found');
    return _trips[idx];
  }
}

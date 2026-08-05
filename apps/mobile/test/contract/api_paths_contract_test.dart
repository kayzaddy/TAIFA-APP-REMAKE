import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/admin/admin_api_paths.dart';
import 'package:taifa/data/chat/chat_api_paths.dart';
import 'package:taifa/data/driver/driver_api_paths.dart';
import 'package:taifa/data/education/education_api_paths.dart';
import 'package:taifa/data/family/family_api_paths.dart';
import 'package:taifa/data/flights/flight_api_paths.dart';
import 'package:taifa/data/food/food_api_paths.dart';
import 'package:taifa/data/gov/gov_api_paths.dart';
import 'package:taifa/data/health/health_api_paths.dart';
import 'package:taifa/data/hotels/stay_api_paths.dart';
import 'package:taifa/data/housing/housing_api_paths.dart';
import 'package:taifa/data/huduma/huduma_api_paths.dart';
import 'package:taifa/data/insurance/insurance_api_paths.dart';
import 'package:taifa/data/jobs/jobs_api_paths.dart';
import 'package:taifa/data/merchant/merchant_api_paths.dart';
import 'package:taifa/data/tourism/tour_api_paths.dart';
import 'package:taifa/data/tourism/tourism_assist_api_paths.dart';
import 'package:taifa/data/tourism/tourism_trip_api_paths.dart';
import 'package:taifa/data/trips/trip_api_paths.dart';
import 'package:taifa/data/wallet/payment_api_paths.dart';
import 'package:taifa/data/wealth/wealth_api_paths.dart';
import 'package:taifa/data/winga/winga_api_paths.dart';

/// Locks mobile path fragments against the backend OpenAPI surface
/// (`apps/backend/openapi.yaml` under `/api/v1/`).
void main() {
  test('PaymentApiPaths', () {
    expect(PaymentApiPaths.wallet, 'payments/wallet');
    expect(PaymentApiPaths.topups, 'payments/topups');
    expect(PaymentApiPaths.transfers, 'payments/transfers');
    expect(PaymentApiPaths.withdrawals, 'payments/withdrawals');
    expect(PaymentApiPaths.refunds, 'payments/refunds');
    expect(
      PaymentApiPaths.demoComplete('abc'),
      'payments/topups/abc/demo-complete',
    );
    expect(
      PaymentApiPaths.pollStatus('abc'),
      'payments/topups/abc/poll-status',
    );
    expect(PaymentApiPaths.transaction('abc'), 'payments/transactions/abc');
    expect(
      PaymentApiPaths.withdrawalApprove('abc'),
      'payments/withdrawals/abc/approve',
    );
    expect(PaymentApiPaths.reverse('abc'), 'payments/transactions/abc/reverse');
  });

  test('TripApiPaths', () {
    expect(TripApiPaths.trips, 'trips/');
    expect(TripApiPaths.trip('abc'), 'trips/abc');
  });

  test('Food / Stay / Flight / Tour ApiPaths', () {
    expect(FoodApiPaths.foodOrders, 'commerce/food-orders');
    expect(FoodApiPaths.foodOrder('abc'), 'commerce/food-orders/abc');
    expect(StayApiPaths.stayBookings, 'commerce/stay-bookings');
    expect(StayApiPaths.stayBooking('abc'), 'commerce/stay-bookings/abc');
    expect(FlightApiPaths.flightBookings, 'commerce/flight-bookings');
    expect(FlightApiPaths.flightBooking('abc'), 'commerce/flight-bookings/abc');
    expect(TourApiPaths.tourBookings, 'commerce/tour-bookings');
    expect(TourApiPaths.tourBooking('abc'), 'commerce/tour-bookings/abc');
  });

  test('TourismTripApiPaths', () {
    expect(TourismTripApiPaths.trips, 'tourism/trips');
    expect(TourismTripApiPaths.cartBuild('t1'), 'tourism/trips/t1/cart/build');
    expect(TourismTripApiPaths.checkout('t1'), 'tourism/trips/t1/checkout');
    expect(
      TourismTripApiPaths.checkoutPay('t1'),
      'tourism/trips/t1/checkout/pay',
    );
  });

  test('TourismAssistApiPaths', () {
    expect(TourismAssistApiPaths.nearby, 'tourism/assist/nearby');
    expect(TourismAssistApiPaths.sos, 'tourism/assist/sos');
    expect(TourismAssistApiPaths.esimQr('o1'), 'tourism/connectivity/esim/o1/qr');
  });

  test('WingaApiPaths', () {
    expect(WingaApiPaths.orders, 'commerce/winga-orders');
    expect(WingaApiPaths.order('abc'), 'commerce/winga-orders/abc');
    expect(WingaApiPaths.serviceBookings, 'commerce/winga-service-bookings');
    expect(WingaApiPaths.shops, 'commerce/winga-shops');
  });

  test('GovApiPaths', () {
    expect(GovApiPaths.govRequests, 'commerce/gov-requests');
    expect(GovApiPaths.govRequest('abc'), 'commerce/gov-requests/abc');
  });

  test('HealthApiPaths', () {
    expect(HealthApiPaths.healthAppointments, 'commerce/health-appointments');
    expect(
      HealthApiPaths.healthAppointment('abc'),
      'commerce/health-appointments/abc',
    );
  });

  test('EducationApiPaths', () {
    expect(EducationApiPaths.eduPayments, 'commerce/edu-payments');
    expect(EducationApiPaths.eduPayment('abc'), 'commerce/edu-payments/abc');
  });

  test('HousingApiPaths', () {
    expect(HousingApiPaths.housingInquiries, 'commerce/housing-inquiries');
    expect(
      HousingApiPaths.housingInquiry('abc'),
      'commerce/housing-inquiries/abc',
    );
  });

  test('WealthApiPaths', () {
    expect(WealthApiPaths.wealthContributions, 'commerce/wealth-contributions');
    expect(
      WealthApiPaths.wealthContribution('abc'),
      'commerce/wealth-contributions/abc',
    );
  });

  test('JobsApiPaths', () {
    expect(JobsApiPaths.jobAssignments, 'commerce/job-assignments');
    expect(JobsApiPaths.jobAssignment('abc'), 'commerce/job-assignments/abc');
  });

  test('InsuranceApiPaths', () {
    expect(InsuranceApiPaths.insurancePolicies, 'commerce/insurance-policies');
    expect(
      InsuranceApiPaths.insurancePolicy('abc'),
      'commerce/insurance-policies/abc',
    );
  });

  test('FamilyApiPaths', () {
    expect(FamilyApiPaths.familyTransfers, 'commerce/family-transfers');
    expect(
      FamilyApiPaths.familyTransfer('abc'),
      'commerce/family-transfers/abc',
    );
  });

  test('HudumaApiPaths', () {
    expect(HudumaApiPaths.hudumaBookings, 'commerce/huduma-bookings');
    expect(HudumaApiPaths.hudumaBooking('abc'), 'commerce/huduma-bookings/abc');
  });

  test('MerchantApiPaths', () {
    expect(MerchantApiPaths.merchantOrders, 'commerce/merchant-orders');
    expect(
      MerchantApiPaths.merchantOrder('abc'),
      'commerce/merchant-orders/abc',
    );
  });

  test('DriverApiPaths', () {
    expect(DriverApiPaths.driverJobs, 'commerce/driver-jobs');
    expect(DriverApiPaths.driverJob('abc'), 'commerce/driver-jobs/abc');
  });

  test('ChatApiPaths', () {
    expect(ChatApiPaths.chatThreads, 'commerce/chat-threads');
    expect(ChatApiPaths.chatThread('abc'), 'commerce/chat-threads/abc');
    expect(
      ChatApiPaths.chatMessages('abc'),
      'commerce/chat-threads/abc/messages',
    );
  });

  test('AdminApiPaths', () {
    expect(AdminApiPaths.adminCases, 'commerce/admin-cases');
    expect(AdminApiPaths.adminCase('abc'), 'commerce/admin-cases/abc');
  });
}

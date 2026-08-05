class TourismAssistApiPaths {
  static const nearby = 'tourism/assist/nearby';
  static const sos = 'tourism/assist/sos';

  static String esimQr(String orderId) => 'tourism/connectivity/esim/$orderId/qr';
}

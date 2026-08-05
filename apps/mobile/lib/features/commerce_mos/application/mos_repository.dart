import '../domain/mos_models.dart';

abstract interface class MosRepository {
  Future<MosAnalytics> bootstrap();

  Future<List<MosProduct>> products({String query = ''});

  Future<List<MosOrder>> orders();

  Future<List<MosSupplier>> suppliers();

  Future<List<MosPurchaseOrder>> purchaseOrders();

  Future<List<MosCustomer>> customers();

  Future<MosAnalytics> analytics();

  Future<MosOrder> createOrder({
    required List<({String productId, int quantity})> lines,
    String channel = 'pos',
  });

  Future<MosOrder> payOrder(String orderId, {required String idempotencyKey});

  Future<MosOrder> fulfillOrder(String orderId);

  Future<void> adjustStock({
    required String productId,
    required String kind,
    required num quantity,
  });

  Future<MosPosSession> openPosSession();

  Future<MosPosSession> closePosSession(String sessionId, {int closingCashMinor = 0});

  Future<List<String>> assist(String capability);

  Future<void> publishToWinga(String productId);
}

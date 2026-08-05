import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../mobility/domain/geo_point.dart';
import '../../mobility/domain/map_scene.dart';
import '../../mobility/domain/route_plan.dart';
import '../../mobility/presentation/widgets/mock_map_view.dart';
import '../application/express_providers.dart';
import '../domain/express_models.dart';

/// Live fulfillment timeline + delivery map (MapsProvider mock canvas).
class ExpressTrackScreen extends ConsumerStatefulWidget {
  const ExpressTrackScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ExpressTrackScreen> createState() => _ExpressTrackScreenState();
}

class _ExpressTrackScreenState extends ConsumerState<ExpressTrackScreen> {
  Timer? _tick;
  double _progress = 0.15;
  ExpressOrder? _order;

  static const _friendly = <String, String>{
    'basket_submitted': 'Shopping list received',
    'merchant_found': 'Best shop selected',
    'merchant_accepted': 'Merchant accepted',
    'paid': 'Payment confirmed',
    'preparing': 'Merchant preparing your order',
    'ready': 'Package ready for pickup',
    'rider_assigned': 'Rider has accepted delivery',
    'rider_arriving': 'Rider is arriving at the shop',
    'picked_up': 'Package collected',
    'on_the_way': 'Rider is on the way',
    'arriving': 'Almost there',
    'delivered': 'Delivered successfully',
    'completed': 'Order completed',
    'settlement_allocated': 'Settlement allocated',
  };

  static const _steps = <(String, String)>[
    ('basket_submitted', 'Shopping List Received'),
    ('merchant_found', 'Finding Best Merchant'),
    ('merchant_accepted', 'Merchant Accepted'),
    ('preparing', 'Preparing Order'),
    ('rider_assigned', 'Rider Assigned'),
    ('rider_arriving', 'Rider Heading To Shop'),
    ('picked_up', 'Package Picked Up'),
    ('on_the_way', 'On The Way'),
    ('arriving', 'Rider Nearby'),
    ('delivered', 'Delivered'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _tick = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() => _progress = math.min(0.95, _progress + 0.04));
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final fromState = ref.read(expressControllerProvider).lastOrder;
    if (fromState != null &&
        (fromState.id == widget.orderId || fromState.publicCode == widget.orderId)) {
      setState(() => _order = fromState);
      return;
    }
    final order =
        await ref.read(expressControllerProvider.notifier).refreshOrder(widget.orderId);
    if (mounted) setState(() => _order = order);
  }

  MapScene _scene(ExpressOrder order) {
    final customer = GeoPoint(order.customerLat, order.customerLng);
    // Approximate merchant slightly north-west of customer for demo map
    final merchant = GeoPoint(order.customerLat + 0.012, order.customerLng - 0.008);
    final route = RoutePlan(
      polyline: [
        merchant,
        GeoPoint(
          (merchant.latitude + customer.latitude) / 2,
          (merchant.longitude + customer.longitude) / 2 + 0.002,
        ),
        customer,
      ],
      distanceMeters: 1800,
      durationSeconds: (order.etaMinutes * 60).clamp(300, 3600),
    );
    final rider = route.pointAt(_progress);
    return MapScene(
      cameraTarget: customer,
      pickup: merchant,
      dropoff: customer,
      driver: rider,
      route: route,
      progress: _progress,
      followDriver: true,
    );
  }

  String _statusLine(ExpressOrder order) {
    final events = order.timelineEvents;
    if (events.isEmpty) return 'Tracking your order';
    final last = events.last;
    return _friendly[last] ?? last.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final order = _order ?? ref.watch(expressControllerProvider).lastOrder;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live tracking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final events = order.timelineEvents.toSet();
    final scene = _scene(order);

    return Scaffold(
      appBar: AppBar(
        title: Text(order.publicCode),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/express'),
        ),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 220,
            child: MockMapView(scene: scene),
          ),
          Padding(
            padding: const EdgeInsets.all(TaifaSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLine(order),
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.storeName.isEmpty ? 'Nearby merchant' : order.storeName}'
                  ' · ETA ~${order.etaMinutes} min'
                  ' · ${(scene.route?.distanceLabel) ?? ''}',
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (order.packageCode.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Package ${order.packageCode}', style: text.titleSmall),
                  if (order.packageQr.isNotEmpty)
                    Text(order.packageQr, style: text.bodySmall),
                  if (order.deliveryPin.isNotEmpty)
                    Text('Delivery PIN ${order.deliveryPin}', style: text.bodyMedium),
                ],
                const SizedBox(height: TaifaSpacing.lg),
                Text('Live timeline', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ..._steps.map((step) {
                  final (key, label) = step;
                  final done = events.contains(key) ||
                      (key == 'preparing' && events.contains('paid')) ||
                      (key == 'on_the_way' && events.contains('delivering'));
                  final live = !done &&
                      (key == 'rider_arriving' ||
                          key == 'on_the_way' ||
                          key == 'arriving') &&
                      events.contains('rider_assigned');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      done
                          ? Icons.check_circle
                          : (live ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                      color: done || live ? TaifaColors.emerald600 : scheme.outline,
                    ),
                    title: Text(label),
                    subtitle: Text(
                      done
                          ? 'Completed'
                          : (live ? 'Live' : 'Pending'),
                      style: text.bodySmall,
                    ),
                  );
                }),
                if (order.paymentRef.isNotEmpty)
                  Text(
                    'Paid · settlement ${order.settlementStatus}',
                    style: text.bodySmall,
                  ),
                const SizedBox(height: TaifaSpacing.md),
                OutlinedButton(
                  onPressed: () => context.go('/express'),
                  child: const Text('Back to Express'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

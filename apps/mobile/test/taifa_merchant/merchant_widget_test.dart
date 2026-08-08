import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taifa/features/taifa_merchant/presentation/auth/merchant_login_screen.dart';

void main() {
  testWidgets('Merchant login screen renders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MerchantLoginScreen()),
      ),
    );
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}

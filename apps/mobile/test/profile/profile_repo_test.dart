import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taifa/features/profile/application/profile_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SeedProfileRepository loads defaults and saves name', () async {
    final repo = SeedProfileRepository();
    final loaded = await repo.load();
    expect(loaded.displayName, 'Amani');
    final saved = await repo.save(loaded.copyWith(displayName: 'Neema'));
    expect(saved.displayName, 'Neema');
    final again = await repo.load();
    expect(again.displayName, 'Neema');
  });
}

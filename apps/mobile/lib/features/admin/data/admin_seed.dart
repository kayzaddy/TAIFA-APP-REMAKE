import '../domain/admin_models.dart';

class AdminSeed {
  const AdminSeed._();

  static List<AdminCase> cases() {
    final now = DateTime.now();
    return [
      AdminCase(
        id: 'adm-kyc-1',
        kind: AdminCaseKind.kyc,
        title: 'NIDA KYC review',
        subject: 'Fatuma Ally · +255 754…',
        detail:
            'Selfie + NIDA mismatch score 0.62. Needs manual approve/reject.',
        status: AdminCaseStatus.open,
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      AdminCase(
        id: 'adm-dsp-1',
        kind: AdminCaseKind.dispute,
        title: 'Food order dispute',
        subject: 'Order #FD-8821 · Spice Bazaar',
        detail: 'Customer claims missing items. Merchant marked delivered.',
        status: AdminCaseStatus.open,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AdminCase(
        id: 'adm-frz-1',
        kind: AdminCaseKind.freeze,
        title: 'Wallet freeze request',
        subject: 'Wallet •••• 4412',
        detail: 'Velocity alert: 12 outbound transfers in 9 minutes.',
        status: AdminCaseStatus.reviewing,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      AdminCase(
        id: 'adm-kyc-2',
        kind: AdminCaseKind.kyc,
        title: 'Merchant BRELA verify',
        subject: 'Ufundi Pros Huduma',
        detail: 'TIN + BRELA docs uploaded. Ready for activation.',
        status: AdminCaseStatus.open,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }
}

import '../domain/ai_models.dart';

/// Swappable LLM boundary — Demo Complete uses [MockAiGateway].
abstract interface class AiGateway {
  Future<ChatMessage> complete({
    required List<ChatMessage> history,
    required String userText,
  });
}

class MockAiGateway implements AiGateway {
  int _seq = 0;

  @override
  Future<ChatMessage> complete({
    required List<ChatMessage> history,
    required String userText,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final q = userText.toLowerCase();
    final reply = _reply(q);
    return ChatMessage(
      id: 'a-${DateTime.now().millisecondsSinceEpoch}-${_seq++}',
      role: ChatRole.assistant,
      text: reply,
      at: DateTime.now(),
    );
  }

  String _reply(String q) {
    // Hard rule: AI never authorizes or completes payments.
    if (q.contains('authorize') ||
        q.contains('approve payment') ||
        q.contains('pay for me') ||
        q.contains('complete payment') ||
        q.contains('send money now') ||
        q.contains('confirm transfer')) {
      return 'I can explain payment options and open the right screen, but I never authorize payments. You must confirm every transfer, QR pay, or checkout yourself in Wallet or Pay.';
    }
    if (q.contains('habari') || q.contains('hello') || q.contains('hi ')) {
      return 'Habari! Mimi ni TAIFA AI — your Super App assistant. I help you find rides, food, hotels, Winga deals, and Pay (QR/links). I never authorize payments. What do you need?';
    }
    if (q.contains('search') || q.contains('find') || q.contains('tafuta')) {
      return 'Open Universal Search from Home (search bar) or ask me a topic — I will point you to the right module. Try “ride”, “pay QR”, “Winga hotels”, or “food near me”.';
    }
    if (q.contains('qr') || q.contains('scan') || q.contains('lipa')) {
      return 'Use Scan on Home or Pay → Scan QR. Paste a taifa://pay payload or intent code (pi_…). Capture always goes through Taifa Payments / MAP — I only guide you.';
    }
    if (q.contains('ride') ||
        q.contains('taxi') ||
        q.contains('boda') ||
        q.contains('safari')) {
      return 'For a ride, open TAIFA Ride from Home. Pick pickup and drop-off, choose Go / Comfort / XL / Boda, then request. Matching and ETA are simulated for this Demo Complete sprint.';
    }
    if (q.contains('food') ||
        q.contains('chakula') ||
        q.contains('restaurant') ||
        q.contains('meal')) {
      return 'TAIFA Food has Spice Bazaar, Coast Kitchen and more in Dar. Browse a menu, checkout, then track a mock courier — all without a real delivery API yet.';
    }
    if (q.contains('hotel') || q.contains('stay') || q.contains('hoteli')) {
      return 'Hotels covers Hyatt Dar, Zanzibar Serena and more. Set dates and guests, pick a room, reserve, then pay with wallet.';
    }
    if (q.contains('flight') ||
        q.contains('ndege') ||
        q.contains('zanzibar weekend')) {
      return 'Flights search DAR ↔ ZNZ / JRO / NBO / EBB on Precision Air, Air Tanzania and Kenya Airways mocks. Hold seats, then pay to get a PNR.';
    }
    if (q.contains('tour') ||
        q.contains('tourism') ||
        q.contains('serengeti') ||
        q.contains('stone town')) {
      return 'Tourism books Stone Town walks, safari days and reef snorkels. Choose guests and a date, reserve, pay with wallet.';
    }
    if (q.contains('wallet') ||
        q.contains('pesa') ||
        q.contains('send') ||
        q.contains('balance')) {
      return 'Your wallet is live against the payments service when remote mode is on. Use Send Money for transfers or Top Up for M-Pesa STK funding. I will not send money for you.';
    }
    if (q.contains('winga') ||
        q.contains('shop') ||
        q.contains('commerce') ||
        q.contains('negotia')) {
      return 'Winga is TAIFA’s brokerage marketplace; Commerce MOS runs merchant ops. Open Winga or Commerce from Home/Menu. Checkout uses Wallet / MAP — never a second ledger.';
    }
    if (q.contains('nfc') || q.contains('translate') || q.contains('lugha')) {
      return 'NFC Tap-to-Translate demos phrase packs for travellers — open NFC from Home or Menu. No real NFC hardware in this mock.';
    }
    if (q.contains('help') || q.contains('msaada') || q.contains('what can')) {
      return 'Try: “Book a ride”, “Scan QR”, “Winga hotels”, “Food near me”, or “Send money”. I route you across the Super App — you always approve payments.';
    }
    return 'Nimekupata. Ask about Ride, Food, Hotels, Flights, Tourism, Wallet, Pay/QR, Winga, or say Habari. I assist — I never authorize payments.';
  }
}

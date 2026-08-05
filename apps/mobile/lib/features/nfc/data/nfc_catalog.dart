import '../domain/nfc_models.dart';

class NfcCatalog {
  const NfcCatalog._();

  static List<NfcPack> packs() => const [
    NfcPack(
      id: 'pack-market',
      title: 'Market & street',
      subtitle: 'Bei, salamu, directions',
      phrases: [
        PhrasePair(
          source: 'Habari za asubuhi',
          target: 'Good morning',
          sourceLang: 'SW',
          targetLang: 'EN',
        ),
        PhrasePair(
          source: 'Bei gani?',
          target: 'How much is this?',
          sourceLang: 'SW',
          targetLang: 'EN',
        ),
        PhrasePair(
          source: 'Naomba punguzo',
          target: 'Please give a discount',
          sourceLang: 'SW',
          targetLang: 'EN',
        ),
        PhrasePair(
          source: 'Asante sana',
          target: 'Thank you very much',
          sourceLang: 'SW',
          targetLang: 'EN',
        ),
      ],
    ),
    NfcPack(
      id: 'pack-travel',
      title: 'Travel cards',
      subtitle: 'Taxi, hotel, airport',
      phrases: [
        PhrasePair(
          source: 'Nipeleke hoteli',
          target: 'Take me to the hotel',
          sourceLang: 'SW',
          targetLang: 'EN',
        ),
        PhrasePair(
          source: 'Where is the gate?',
          target: 'Lango liko wapi?',
          sourceLang: 'EN',
          targetLang: 'SW',
        ),
        PhrasePair(
          source: 'I have a reservation',
          target: 'Nina uhifadhi',
          sourceLang: 'EN',
          targetLang: 'SW',
        ),
      ],
    ),
    NfcPack(
      id: 'pack-health',
      title: 'Clinic phrases',
      subtitle: 'Pharmacy & first aid',
      phrases: [
        PhrasePair(
          source: 'Ninaumwa kichwa',
          target: 'I have a headache',
          sourceLang: 'SW',
          targetLang: 'EN',
        ),
        PhrasePair(
          source: 'I need a doctor',
          target: 'Nahitaji daktari',
          sourceLang: 'EN',
          targetLang: 'SW',
        ),
      ],
    ),
  ];
}

class PhrasePair {
  const PhrasePair({
    required this.source,
    required this.target,
    required this.sourceLang,
    required this.targetLang,
  });

  final String source;
  final String target;
  final String sourceLang;
  final String targetLang;
}

class NfcPack {
  const NfcPack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.phrases,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<PhrasePair> phrases;
}

enum NfcPhase { home, scanning, result }

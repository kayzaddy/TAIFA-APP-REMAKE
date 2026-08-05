enum NotifKind { ride, food, payment, system, promo }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.at,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final NotifKind kind;
  final DateTime at;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    title: title,
    body: body,
    kind: kind,
    at: at,
    read: read ?? this.read,
  );
}

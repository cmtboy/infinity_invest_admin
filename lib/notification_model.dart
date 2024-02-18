class UserNotification {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
   bool seen;

  UserNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.seen,
  });
}

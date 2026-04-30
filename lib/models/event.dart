/// Modelo de evento para calendario mensual.
class Event {
  final String? remoteId;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;
  final String? location;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Event({
    this.remoteId,
    required this.title,
    this.description,
    required this.startAt,
    required this.endAt,
    this.allDay = false,
    this.location,
    this.updatedAt,
    this.deletedAt,
  });
}

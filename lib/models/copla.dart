/// Modelo específico para Coplero (coplas de solo letra).
class Copla {
  final String? remoteId;
  final String type; // JOTA / SEGUIDILLA
  final String subtype;
  final String text;
  final String? author;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Copla({
    this.remoteId,
    required this.type,
    required this.subtype,
    required this.text,
    this.author,
    this.updatedAt,
    this.deletedAt,
  });
}

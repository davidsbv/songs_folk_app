/// Partitura/tablatura asociada a un instrumento (cuerda, dulzaina, etc.).
///
/// Cada [Score] pertenece a un solo instrumento y puede tener
/// partitura o tablatura en PDF o imagen.
class Score {
  final String instrument; // Ej: "CUERDA", "DULZAINA"

  final String? scorePdfPath;
  final String? scoreImagePath;

  final String? tabPdfPath;
  final String? tabImagePath;

  const Score({
    required this.instrument,
    this.scorePdfPath,
    this.scoreImagePath,
    this.tabPdfPath,
    this.tabImagePath,
  });
}

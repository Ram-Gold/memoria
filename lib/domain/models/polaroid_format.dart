/// Authentic Polaroid film formats supported in Memoria.
enum PolaroidFormat {
  square(
    id: '1:1',
    ratio: 1.0,
    displayName: '1:1 Square',
    filmType: 'Polaroid 600',
    dimensions: '88 × 107 mm',
  ),
  portrait(
    id: '3:4',
    ratio: 3 / 4,
    displayName: '3:4 Portrait',
    filmType: 'Polaroid Go',
    dimensions: '54 × 67 mm',
  ),
  landscape(
    id: '4:3',
    ratio: 4 / 3,
    displayName: '4:3 Wide',
    filmType: 'Polaroid Wide',
    dimensions: '108 × 86 mm',
  );

  final String id;
  final double ratio;
  final String displayName;
  final String filmType;
  final String dimensions;

  const PolaroidFormat({
    required this.id,
    required this.ratio,
    required this.displayName,
    required this.filmType,
    required this.dimensions,
  });

  /// Resolves a [PolaroidFormat] from a format string or legacy layout id.
  /// Falls back to [PolaroidFormat.square] for unknown or legacy values.
  static PolaroidFormat fromId(String id) {
    final clean = id.trim().toLowerCase();
    return PolaroidFormat.values.firstWhere(
      (f) => f.id == id.trim() || f.name.toLowerCase() == clean,
      orElse: () => PolaroidFormat.square,
    );
  }
}

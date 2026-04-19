import 'dart:convert';

class ScannedDocument {
  const ScannedDocument({
    required this.id,
    required this.title,
    required this.pdfPath,
    required this.createdAt,
    required this.pageCount,
    this.thumbnailPath,
  });

  final String id;
  final String title;
  final String pdfPath;
  final DateTime createdAt;
  final int pageCount;
  final String? thumbnailPath;

  ScannedDocument copyWith({
    String? title,
    String? pdfPath,
    DateTime? createdAt,
    int? pageCount,
    String? thumbnailPath,
  }) {
    return ScannedDocument(
      id: id,
      title: title ?? this.title,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
      pageCount: pageCount ?? this.pageCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pdfPath': pdfPath,
      'createdAt': createdAt.toIso8601String(),
      'pageCount': pageCount,
      'thumbnailPath': thumbnailPath,
    };
  }

  factory ScannedDocument.fromJson(Map<String, dynamic> json) {
    return ScannedDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      pdfPath: json['pdfPath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      pageCount: json['pageCount'] as int,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }

  static String encodeList(List<ScannedDocument> docs) {
    final data = docs.map((doc) => doc.toJson()).toList(growable: false);
    return jsonEncode(data);
  }

  static List<ScannedDocument> decodeList(String raw) {
    if (raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => ScannedDocument.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}

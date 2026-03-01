class Note {
  final String id;
  String title;
  String content;
  String contentFormat; // 'plain' for legacy, 'delta' for Quill Delta JSON
  String category;
  String color;
  bool isPinned;
  final DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    this.content = '',
    this.contentFormat = 'delta',
    this.category = 'General',
    this.color = 'cream',
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDelta => contentFormat == 'delta';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'contentFormat': contentFormat,
      'category': category,
      'color': color,
      'isPinned': isPinned ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      contentFormat: (map['contentFormat'] as String?) ?? 'plain',
      category: (map['category'] as String?) ?? 'General',
      color: (map['color'] as String?) ?? 'cream',
      isPinned: (map['isPinned'] as int? ?? 0) == 1,
      createdAt: _parseDateSafe(map['createdAt']),
      updatedAt: _parseDateSafe(map['updatedAt']),
    );
  }

  static DateTime _parseDateSafe(dynamic value) {
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        // Corrupted date string — fall back to now
      }
    }
    return DateTime.now();
  }

  Note copyWith({
    String? title,
    String? content,
    String? contentFormat,
    String? category,
    String? color,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      contentFormat: contentFormat ?? this.contentFormat,
      category: category ?? this.category,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

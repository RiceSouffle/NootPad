class Note {
  final String id;
  String title;
  String content;
  String category;
  String color;
  bool isPinned;
  final DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    this.content = '',
    this.category = 'General',
    this.color = 'cream',
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'color': color,
      'isPinned': isPinned ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      color: map['color'] as String? ?? 'cream',
      isPinned: (map['isPinned'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Note copyWith({
    String? title,
    String? content,
    String? category,
    String? color,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

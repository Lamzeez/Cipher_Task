class TodoModel {
  final String id;
  final String title;
  final String encryptedNote; // AES-encrypted sensitive note
  final bool isDone;
  final int createdAt;
  final String ownerEmail; // which user owns this todo

  TodoModel({
    required this.id,
    required this.title,
    required this.encryptedNote,
    required this.isDone,
    required this.createdAt,
    required this.ownerEmail,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'encryptedNote': encryptedNote,
        'isDone': isDone,
        'createdAt': createdAt,
        'ownerEmail': ownerEmail,
      };

  factory TodoModel.fromMap(Map map) {
    final id = map['id'] as String;
    final title = map['title'] as String;
    final encryptedNote = map['encryptedNote'] as String;
    final isDone = map['isDone'] as bool;
    final createdAt = map['createdAt'] as int;

    // Backwards-compat: if old record has no ownerEmail, fall back to empty string
    final ownerEmail = (map['ownerEmail'] ?? '') as String;

    return TodoModel(
      id: id,
      title: title,
      encryptedNote: encryptedNote,
      isDone: isDone,
      createdAt: createdAt,
      ownerEmail: ownerEmail,
    );
  }

  TodoModel copyWith({
    String? title,
    String? encryptedNote,
    bool? isDone,
  }) {
    return TodoModel(
      id: id,
      title: title ?? this.title,
      encryptedNote: encryptedNote ?? this.encryptedNote,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      ownerEmail: ownerEmail,
    );
  }
}
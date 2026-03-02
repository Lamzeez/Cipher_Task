class TodoModel {
  final String id;
  final String title;
  final String encryptedNote; // AES-encrypted sensitive note
  final bool isDone;
  final int createdAt;

  TodoModel({
    required this.id,
    required this.title,
    required this.encryptedNote,
    required this.isDone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'encryptedNote': encryptedNote,
        'isDone': isDone,
        'createdAt': createdAt,
      };

  factory TodoModel.fromMap(Map map) => TodoModel(
        id: map['id'] as String,
        title: map['title'] as String,
        encryptedNote: map['encryptedNote'] as String,
        isDone: map['isDone'] as bool,
        createdAt: map['createdAt'] as int,
      );

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
    );
  }
}
class UserModel {
  final String email;
  final String displayName;

  UserModel({required this.email, required this.displayName});

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
      };

  factory UserModel.fromMap(Map map) => UserModel(
        email: map['email'] as String,
        displayName: map['displayName'] as String,
      );
}
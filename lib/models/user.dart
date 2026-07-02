/// Authenticated user of the MediCare app.
///
/// Passwords are stored as a SHA-256 hash with a per-user salt — never as
/// plain text. The `id` field maps 1-to-1 with the corresponding row in the
/// `profiles` table so that medicines/reminders can stay scoped to a user.
class User {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String salt;
  final String avatar;
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.salt,
    this.avatar = '👤',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email.toLowerCase(),
        'passwordHash': passwordHash,
        'salt': salt,
        'avatar': avatar,
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int?,
        name: map['name'] as String,
        email: map['email'] as String,
        passwordHash: map['passwordHash'] as String,
        salt: map['salt'] as String,
        avatar: (map['avatar'] as String?) ?? '👤',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? salt,
    String? avatar,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        salt: salt ?? this.salt,
        avatar: avatar ?? this.avatar,
        createdAt: createdAt,
      );
}

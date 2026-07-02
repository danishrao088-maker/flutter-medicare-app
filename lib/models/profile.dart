class Profile {
  final int? id;
  final String name;
  final String relation; // Self, Father, Mother, Child, Sibling, Spouse, Other
  final int age;
  final String avatar;
  final int userId; // owning account
  final DateTime createdAt;

  Profile({
    this.id,
    required this.name,
    required this.relation,
    required this.age,
    required this.avatar,
    required this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'relation': relation,
        'age': age,
        'avatar': avatar,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as int?,
        name: map['name'] as String,
        relation: map['relation'] as String,
        age: map['age'] as int,
        avatar: map['avatar'] as String,
        userId: map['userId'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Profile copyWith({
    int? id,
    String? name,
    String? relation,
    int? age,
    String? avatar,
    int? userId,
  }) =>
      Profile(
        id: id ?? this.id,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        age: age ?? this.age,
        avatar: avatar ?? this.avatar,
        userId: userId ?? this.userId,
        createdAt: createdAt,
      );
}

class MedicineLog {
  final int? id;
  final int medicineId;
  final String medicineName;
  final int profileId;
  final String profileName;
  final String status; // taken, skipped, missed
  final DateTime takenAt;
  final String dose;

  MedicineLog({
    this.id,
    required this.medicineId,
    required this.medicineName,
    required this.profileId,
    required this.profileName,
    required this.status,
    required this.takenAt,
    required this.dose,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicineId': medicineId,
        'medicineName': medicineName,
        'profileId': profileId,
        'profileName': profileName,
        'status': status,
        'takenAt': takenAt.toIso8601String(),
        'dose': dose,
      };

  factory MedicineLog.fromMap(Map<String, dynamic> map) => MedicineLog(
        id: map['id'] as int?,
        medicineId: map['medicineId'] as int,
        medicineName: map['medicineName'] as String,
        profileId: map['profileId'] as int,
        profileName: map['profileName'] as String,
        status: map['status'] as String,
        takenAt: DateTime.parse(map['takenAt'] as String),
        dose: map['dose'] as String,
      );
}

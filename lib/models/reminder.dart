class Reminder {
  final int? id;
  final int medicineId;
  final String medicineName;
  final String time; // HH:mm 24-hour
  final List<int> days; // 1=Mon ... 7=Sun. Empty list = every day.
  final bool isActive;
  final String dose;
  final DateTime createdAt;

  Reminder({
    this.id,
    required this.medicineId,
    required this.medicineName,
    required this.time,
    required this.days,
    this.isActive = true,
    required this.dose,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicineId': medicineId,
        'medicineName': medicineName,
        'time': time,
        'days': days.join(','),
        'isActive': isActive ? 1 : 0,
        'dose': dose,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Reminder.fromMap(Map<String, dynamic> map) {
    final raw = (map['days'] as String?) ?? '';
    final days = raw.trim().isEmpty
        ? <int>[]
        : raw.split(',').map((e) => int.parse(e.trim())).toList();

    return Reminder(
      id: map['id'] as int?,
      medicineId: map['medicineId'] as int,
      medicineName: map['medicineName'] as String,
      time: map['time'] as String,
      days: days,
      isActive: (map['isActive'] as int) == 1,
      dose: map['dose'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Reminder copyWith({
    int? id,
    int? medicineId,
    String? medicineName,
    String? time,
    List<int>? days,
    bool? isActive,
    String? dose,
  }) =>
      Reminder(
        id: id ?? this.id,
        medicineId: medicineId ?? this.medicineId,
        medicineName: medicineName ?? this.medicineName,
        time: time ?? this.time,
        days: days ?? this.days,
        isActive: isActive ?? this.isActive,
        dose: dose ?? this.dose,
        createdAt: createdAt,
      );

  String get daysText {
    if (days.isEmpty) return 'Daily';
    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d]).join(', ');
  }

  String get formattedTime {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

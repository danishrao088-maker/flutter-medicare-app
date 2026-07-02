import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/medicine.dart';
import '../models/profile.dart';
import '../models/reminder.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// Single ChangeNotifier that owns all app state.
///
/// All data operations are scoped to `currentUser` so that two accounts on
/// the same device never see each other's medicines, reminders, or logs.
class AppProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _auth = AuthService.instance;

  User? _currentUser;
  Profile? _selectedProfile;
  List<Profile> _profiles = [];
  List<Medicine> _medicines = [];
  List<Reminder> _reminders = [];
  List<MedicineLog> _logs = [];
  Map<String, int> _logStats = {'taken': 0, 'skipped': 0, 'missed': 0};
  bool _isLoading = false;

  // ===== Getters =====
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  Profile? get selectedProfile => _selectedProfile;
  List<Profile> get profiles => List.unmodifiable(_profiles);
  List<Medicine> get medicines => List.unmodifiable(_medicines);
  List<Reminder> get reminders => List.unmodifiable(_reminders);
  List<MedicineLog> get logs => List.unmodifiable(_logs);
  Map<String, int> get logStats => Map.unmodifiable(_logStats);
  bool get isLoading => _isLoading;

  List<Medicine> get lowStockMedicines =>
      _medicines.where((m) => m.isLowStock || m.isOutOfStock).toList();

  List<Medicine> get filteredMedicines {
    if (_selectedProfile == null) return _medicines;
    return _medicines
        .where((m) => m.profileId == _selectedProfile!.id)
        .toList();
  }

  // ===== Session =====
  Future<bool> tryRestoreSession() async {
    final user = await _auth.restoreSession();
    if (user == null) return false;
    _currentUser = user;
    await loadAll();
    return true;
  }

  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.logout();
    _currentUser = null;
    _selectedProfile = null;
    _profiles = [];
    _medicines = [];
    _reminders = [];
    _logs = [];
    _logStats = {'taken': 0, 'skipped': 0, 'missed': 0};
    notifyListeners();
  }

  // ===== Loading =====
  Future<void> loadAll() async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    final userId = _currentUser!.id!;
    _profiles = await _db.getProfilesByUser(userId);

    // Maintain selection across reloads, but reset if the profile is gone.
    if (_selectedProfile != null) {
      _selectedProfile = _profiles.firstWhere(
        (p) => p.id == _selectedProfile!.id,
        orElse: () => _profiles.isNotEmpty ? _profiles.first : _selectedProfile!,
      );
    }
    if (_selectedProfile == null && _profiles.isNotEmpty) {
      _selectedProfile = _profiles.first;
    }

    _medicines = await _db.getMedicinesByUser(userId);
    _reminders = await _db.getRemindersByUser(userId);
    _logs = await _db.getLogsByUser(userId);
    _logStats = await _db.getLogStatsByUser(userId);

    _isLoading = false;
    notifyListeners();
  }

  void selectProfile(Profile profile) {
    _selectedProfile = profile;
    notifyListeners();
  }

  // ===== Medicines =====
  Future<void> addMedicine(Medicine medicine) async {
    final id = await _db.insertMedicine(medicine);
    _medicines = [..._medicines, medicine.copyWith(id: id)]
      ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _db.updateMedicine(medicine);
    _medicines = _medicines
        .map((m) => m.id == medicine.id ? medicine : m)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> deleteMedicine(int id) async {
    await _db.deleteMedicine(id);
    // Cascade also clears scheduled notifications for each reminder.
    final removedReminderIds = _reminders
        .where((r) => r.medicineId == id)
        .map((r) => r.id!)
        .toList();
    for (final rid in removedReminderIds) {
      await NotificationService.instance.cancelReminder(rid);
    }
    _medicines = _medicines.where((m) => m.id != id).toList();
    _reminders = _reminders.where((r) => r.medicineId != id).toList();
    notifyListeners();
  }

  Future<void> takeMedicine(Medicine medicine) async {
    if (medicine.currentStock <= 0 || _currentUser == null) return;

    final newStock = medicine.currentStock - 1;
    await _db.updateMedicineStock(medicine.id!, newStock);

    _medicines = _medicines
        .map((m) =>
            m.id == medicine.id ? m.copyWith(currentStock: newStock) : m)
        .toList();

    final profile = _profiles.firstWhere(
      (p) => p.id == medicine.profileId,
      orElse: () => _selectedProfile ?? _profiles.first,
    );
    final log = MedicineLog(
      medicineId: medicine.id!,
      medicineName: medicine.name,
      profileId: profile.id!,
      profileName: profile.name,
      status: 'taken',
      takenAt: DateTime.now(),
      dose: medicine.dosage,
    );
    final logId = await _db.insertLog(log);
    _logs = [
      MedicineLog(
        id: logId,
        medicineId: log.medicineId,
        medicineName: log.medicineName,
        profileId: log.profileId,
        profileName: log.profileName,
        status: log.status,
        takenAt: log.takenAt,
        dose: log.dose,
      ),
      ..._logs,
    ];
    _logStats = {..._logStats, 'taken': (_logStats['taken'] ?? 0) + 1};

    if (newStock <= medicine.lowStockAlert) {
      await NotificationService.instance
          .showLowStockNotification(medicine.name, newStock);
    }

    notifyListeners();
  }

  Future<void> skipMedicine(Medicine medicine) async {
    if (_currentUser == null) return;
    final profile = _profiles.firstWhere(
      (p) => p.id == medicine.profileId,
      orElse: () => _selectedProfile ?? _profiles.first,
    );
    final log = MedicineLog(
      medicineId: medicine.id!,
      medicineName: medicine.name,
      profileId: profile.id!,
      profileName: profile.name,
      status: 'skipped',
      takenAt: DateTime.now(),
      dose: medicine.dosage,
    );
    final logId = await _db.insertLog(log);
    _logs = [
      MedicineLog(
        id: logId,
        medicineId: log.medicineId,
        medicineName: log.medicineName,
        profileId: log.profileId,
        profileName: log.profileName,
        status: log.status,
        takenAt: log.takenAt,
        dose: log.dose,
      ),
      ..._logs,
    ];
    _logStats = {..._logStats, 'skipped': (_logStats['skipped'] ?? 0) + 1};
    notifyListeners();
  }

  Future<void> refillMedicine(Medicine medicine, int quantity) async {
    if (quantity <= 0) return;
    final newStock = medicine.currentStock + quantity;
    final newTotal =
        newStock > medicine.totalStock ? newStock : medicine.totalStock;
    final updated =
        medicine.copyWith(currentStock: newStock, totalStock: newTotal);
    await _db.updateMedicine(updated);
    _medicines =
        _medicines.map((m) => m.id == medicine.id ? updated : m).toList();
    notifyListeners();
  }

  // ===== Reminders =====
  Future<void> addReminder(Reminder reminder) async {
    final id = await _db.insertReminder(reminder);
    final created = reminder.copyWith(id: id);
    _reminders = [..._reminders, created]
      ..sort((a, b) => a.time.compareTo(b.time));
    await NotificationService.instance.scheduleReminder(created);
    notifyListeners();
  }

  Future<void> toggleReminder(Reminder reminder) async {
    final updated = reminder.copyWith(isActive: !reminder.isActive);
    await _db.toggleReminder(reminder.id!, updated.isActive);
    _reminders =
        _reminders.map((r) => r.id == reminder.id ? updated : r).toList();
    if (updated.isActive) {
      await NotificationService.instance.scheduleReminder(updated);
    } else {
      await NotificationService.instance.cancelReminder(reminder.id!);
    }
    notifyListeners();
  }

  Future<void> deleteReminder(int id) async {
    await _db.deleteReminder(id);
    await NotificationService.instance.cancelReminder(id);
    _reminders = _reminders.where((r) => r.id != id).toList();
    notifyListeners();
  }

  // ===== Profiles =====
  Future<void> addProfile({
    required String name,
    required String relation,
    required int age,
    required String avatar,
  }) async {
    if (_currentUser == null) return;
    final newProfile = Profile(
      name: name,
      relation: relation,
      age: age,
      avatar: avatar,
      userId: _currentUser!.id!,
    );
    final id = await _db.insertProfile(newProfile);
    _profiles = [..._profiles, newProfile.copyWith(id: id)];
    notifyListeners();
  }

  Future<void> deleteProfile(int id) async {
    await _db.deleteProfile(id);
    _profiles = _profiles.where((p) => p.id != id).toList();
    if (_selectedProfile?.id == id) {
      _selectedProfile = _profiles.isNotEmpty ? _profiles.first : null;
    }
    // Refresh dependent data because cascade deletes may have removed medicines.
    await loadAll();
  }
}

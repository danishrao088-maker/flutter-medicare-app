import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../models/reminder.dart';
import '../services/app_provider.dart';
import '../theme.dart';
import 'add_medicine_screen.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Medicine medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _colorFromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  String _typeEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'tablet':
        return '💊';
      case 'syrup':
        return '🧴';
      case 'injection':
        return '💉';
      case 'capsule':
        return '🔴';
      case 'drops':
        return '💧';
      case 'cream':
        return '🧪';
      default:
        return '💊';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // If this medicine was deleted while the screen was open, pop back
        // on the next frame rather than rendering a stale snapshot.
        final exists =
            provider.medicines.any((m) => m.id == widget.medicine.id);
        if (!exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          // Render an empty placeholder for the one frame before pop.
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: SizedBox.shrink(),
          );
        }

        // Pick the latest version of the medicine from the provider so the
        // screen reflects stock changes immediately after "Take Now".
        final medicine = provider.medicines.firstWhere(
          (m) => m.id == widget.medicine.id,
        );
        final color = _colorFromHex(medicine.color);
        final reminders = provider.reminders
            .where((r) => r.medicineId == medicine.id)
            .toList();

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppTheme.background,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddMedicineScreen(medicine: medicine),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.35),
                          AppTheme.background,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _typeEmoji(medicine.type),
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${medicine.dosage} • ${medicine.type}',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: color,
                  labelColor: color,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Reminders'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(medicine: medicine, color: color),
                _RemindersTab(
                    medicine: medicine,
                    reminders: reminders,
                    color: color),
                _HistoryTab(medicine: medicine),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: medicine.isOutOfStock
                ? null
                : () => provider.takeMedicine(medicine),
            label: Text(
              medicine.isOutOfStock ? 'Out of Stock' : 'Take Now',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            icon: Icon(medicine.isOutOfStock
                ? Icons.block_rounded
                : Icons.check_circle_outline_rounded),
            backgroundColor:
                medicine.isOutOfStock ? AppTheme.textSecondary : color,
            foregroundColor: Colors.black,
          ),
        );
      },
    );
  }
}

// ===========================================================================
// OVERVIEW
// ===========================================================================
class _OverviewTab extends StatelessWidget {
  final Medicine medicine;
  final Color color;
  const _OverviewTab({required this.medicine, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      children: [
        Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: medicine.stockPercentage * 100,
                        color: color,
                        radius: 22,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (1 - medicine.stockPercentage) * 100,
                        color: AppTheme.surfaceLight,
                        radius: 22,
                        showTitle: false,
                      ),
                    ],
                    centerSpaceRadius: 56,
                    sectionsSpace: 2,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${medicine.currentStock}',
                      style: TextStyle(
                        color: color,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'remaining',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _InfoRow(
          label: 'Total stock',
          value: '${medicine.totalStock} units',
          icon: Icons.inventory_2_rounded,
        ),
        _InfoRow(
          label: 'Low stock alert',
          value: 'At ${medicine.lowStockAlert} units',
          icon: Icons.warning_rounded,
        ),
        _InfoRow(
          label: 'Status',
          value: medicine.isOutOfStock
              ? 'Out of stock'
              : medicine.isLowStock
                  ? 'Low stock'
                  : 'In stock',
          icon: Icons.circle_rounded,
          valueColor: medicine.isOutOfStock
              ? AppTheme.danger
              : medicine.isLowStock
                  ? AppTheme.warning
                  : AppTheme.success,
        ),
        if (medicine.notes.isNotEmpty)
          _InfoRow(
            label: 'Notes',
            value: medicine.notes,
            icon: Icons.notes_rounded,
            multiline: true,
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final bool multiline;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: AppTheme.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// REMINDERS
// ===========================================================================
class _RemindersTab extends StatelessWidget {
  final Medicine medicine;
  final List<Reminder> reminders;
  final Color color;

  const _RemindersTab({
    required this.medicine,
    required this.reminders,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        ElevatedButton.icon(
          onPressed: () => _showAddReminderSheet(context),
          icon: const Icon(Icons.add_alarm_rounded),
          label: const Text('Add reminder'),
          style: ElevatedButton.styleFrom(backgroundColor: color),
        ),
        const SizedBox(height: 16),
        if (reminders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.alarm_off_rounded,
                    size: 48, color: AppTheme.textSecondary),
                SizedBox(height: 8),
                Text('No reminders set',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          )
        else
          ...reminders.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: r.isActive
                        ? color.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.alarm_rounded,
                        color: r.isActive ? color : AppTheme.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.formattedTime,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${r.daysText} • ${r.dose}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: r.isActive,
                      onChanged: (_) =>
                          context.read<AppProvider>().toggleReminder(r),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.danger, size: 20),
                      onPressed: () =>
                          context.read<AppProvider>().deleteReminder(r.id!),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  void _showAddReminderSheet(BuildContext context) {
    TimeOfDay selectedTime = TimeOfDay.now();
    final selectedDays = <int>{};
    final doseCtrl = TextEditingController(text: medicine.dosage);
    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Add Reminder',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                    builder: (context, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                            primary: AppTheme.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (t != null) setS(() => selectedTime = t);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        selectedTime.format(ctx),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Tap to change',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Repeat days (none = daily)',
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final sel = selectedDays.contains(day);
                  return FilterChip(
                    label: Text(
                      dayNames[day],
                      style: TextStyle(
                        color: sel ? Colors.black : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    selected: sel,
                    onSelected: (_) => setS(() {
                      if (sel) {
                        selectedDays.remove(day);
                      } else {
                        selectedDays.add(day);
                      }
                    }),
                    backgroundColor: AppTheme.surfaceLight,
                    selectedColor: AppTheme.primary,
                    showCheckmark: false,
                    side: BorderSide.none,
                  );
                }),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: doseCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Dose',
                  prefixIcon: Icon(Icons.scale_rounded),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final reminder = Reminder(
                      medicineId: medicine.id!,
                      medicineName: medicine.name,
                      time:
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      days: selectedDays.toList()..sort(),
                      dose: doseCtrl.text.trim().isNotEmpty
                          ? doseCtrl.text.trim()
                          : medicine.dosage,
                    );
                    context.read<AppProvider>().addReminder(reminder);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Set reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// HISTORY
// ===========================================================================
class _HistoryTab extends StatelessWidget {
  final Medicine medicine;
  const _HistoryTab({required this.medicine});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(dt);
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today $timeStr';
    }
    return '${DateFormat('d MMM').format(dt)} $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final logs = provider.logs
            .where((l) => l.medicineId == medicine.id)
            .take(50)
            .toList();
        if (logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded,
                    size: 50, color: AppTheme.textSecondary),
                SizedBox(height: 8),
                Text('No history yet',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: logs.length,
          itemBuilder: (ctx, i) {
            final log = logs[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    log.status == 'taken'
                        ? Icons.check_circle_rounded
                        : log.status == 'skipped'
                            ? Icons.skip_next_rounded
                            : Icons.cancel_rounded,
                    color: log.status == 'taken'
                        ? AppTheme.success
                        : log.status == 'skipped'
                            ? AppTheme.warning
                            : AppTheme.danger,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${log.dose} • ${log.profileName}',
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  Text(
                    _formatDate(log.takenAt),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../models/profile.dart';
import '../services/app_provider.dart';
import '../theme.dart';
import '../widgets/medicine_card.dart';
import '../widgets/stat_card.dart';
import 'add_medicine_screen.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardTab(),
          MedicinesTab(),
          RemindersTab(),
          HistoryTab(),
          ProfilesTab(),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddMedicineScreen()),
              ),
              label: const Text('Add Medicine',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              icon: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.medication_rounded), label: 'Medicines'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.alarm_rounded), label: 'Reminders'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded), label: 'History'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people_alt_rounded), label: 'Family'),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// DASHBOARD
// ===========================================================================
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final user = provider.currentUser;
        final lowStock = provider.lowStockMedicines;
        final total = provider.filteredMedicines.length;
        final activeReminders =
            provider.reminders.where((r) => r.isActive).length;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 170,
              pinned: true,
              backgroundColor: AppTheme.background,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () => _confirmSignOut(context, provider),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D3B2E), Color(0xFF0F1923)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 60, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.medical_services_rounded,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'MediCare',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Hello, ${user?.name.split(' ').first ?? 'there'}! 👋',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Stay healthy, take your medicines on time',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeInUp(
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Medicines',
                            value: '$total',
                            icon: Icons.medication_rounded,
                            color: AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            title: 'Active Reminders',
                            value: '$activeReminders',
                            icon: Icons.alarm_on_rounded,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            title: 'Low Stock',
                            value: '${lowStock.length}',
                            icon: Icons.warning_rounded,
                            color: lowStock.isEmpty
                                ? AppTheme.success
                                : AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: AdherenceCard(stats: provider.logStats),
                  ),
                  if (lowStock.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: LowStockBanner(medicines: lowStock),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    "Today's Medicines",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (provider.filteredMedicines.isEmpty)
                    const EmptyState(
                      message: 'No medicines added yet',
                      hint: 'Tap the + button on Medicines to add one',
                      icon: Icons.medication_outlined,
                    )
                  else
                    ...provider.filteredMedicines.take(5).map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: MedicineCard(medicine: m),
                        )),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context, AppProvider provider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content:
            const Text('You will need to sign in again to access your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginScreen.routeName,
                (_) => false,
              );
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class AdherenceCard extends StatelessWidget {
  final Map<String, int> stats;
  const AdherenceCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = (stats['taken'] ?? 0) +
        (stats['skipped'] ?? 0) +
        (stats['missed'] ?? 0);
    final adherence =
        total > 0 ? ((stats['taken'] ?? 0) / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.18),
            AppTheme.secondary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medicine Adherence',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '$adherence%',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _AdherenceRow('Taken', stats['taken'] ?? 0, AppTheme.success),
                    const SizedBox(height: 6),
                    _AdherenceRow(
                        'Skipped', stats['skipped'] ?? 0, AppTheme.warning),
                    const SizedBox(height: 6),
                    _AdherenceRow(
                        'Missed', stats['missed'] ?? 0, AppTheme.danger),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdherenceRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _AdherenceRow(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const Spacer(),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class LowStockBanner extends StatelessWidget {
  final List<Medicine> medicines;
  const LowStockBanner({super.key, required this.medicines});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppTheme.danger, size: 20),
              SizedBox(width: 8),
              Text(
                'Low Stock Alert',
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...medicines.map((m) {
            Color color;
            try {
              color = Color(int.parse(m.color.replaceAll('#', '0xFF')));
            } catch (_) {
              color = AppTheme.danger;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    m.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    m.isOutOfStock ? 'Out of stock' : '${m.currentStock} left',
                    style: TextStyle(
                      color: m.isOutOfStock
                          ? AppTheme.danger
                          : AppTheme.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final String? hint;
  final IconData icon;
  const EmptyState({
    super.key,
    required this.message,
    this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 44, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// MEDICINES TAB
// ===========================================================================
class MedicinesTab extends StatefulWidget {
  const MedicinesTab({super.key});

  @override
  State<MedicinesTab> createState() => _MedicinesTabState();
}

class _MedicinesTabState extends State<MedicinesTab> {
  String _search = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        var meds = provider.filteredMedicines;
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          meds = meds.where((m) => m.name.toLowerCase().contains(q)).toList();
        }
        if (_filter == 'Low Stock') {
          meds = meds.where((m) => m.isLowStock || m.isOutOfStock).toList();
        } else if (_filter != 'All') {
          meds = meds.where((m) => m.type == _filter).toList();
        }

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.background,
              title: const Text('My Medicines'),
              automaticallyImplyLeading: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(110),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search medicines...',
                          prefixIcon: Icon(Icons.search_rounded),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            'All',
                            'Low Stock',
                            'Tablet',
                            'Capsule',
                            'Syrup',
                            'Injection',
                            'Drops',
                            'Cream',
                          ].map((f) {
                            final selected = _filter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  f,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? Colors.black
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _filter = f),
                                backgroundColor: AppTheme.surfaceLight,
                                selectedColor: AppTheme.primary,
                                showCheckmark: false,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (meds.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  message: 'No medicines found',
                  hint: 'Tap "Add Medicine" to get started',
                  icon: Icons.medication_outlined,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 250),
                        delay: Duration(milliseconds: i * 30),
                        child: MedicineCard(
                          medicine: meds[i],
                          showActions: true,
                        ),
                      ),
                    ),
                    childCount: meds.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ===========================================================================
// REMINDERS TAB
// ===========================================================================
class RemindersTab extends StatelessWidget {
  const RemindersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final reminders = provider.reminders;
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Reminders'),
            automaticallyImplyLeading: false,
          ),
          body: reminders.isEmpty
              ? const EmptyState(
                  message: 'No reminders set',
                  hint:
                      'Open a medicine and add a reminder to be notified on time',
                  icon: Icons.alarm_off_rounded,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: reminders.length,
                  itemBuilder: (ctx, i) {
                    final r = reminders[i];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 250),
                      delay: Duration(milliseconds: i * 30),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: r.isActive
                                ? AppTheme.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (r.isActive
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.alarm_rounded,
                                color: r.isActive
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.medicineName,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${r.formattedTime} • ${r.daysText}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Dose: ${r.dose}',
                                    style: TextStyle(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.85),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: r.isActive,
                              onChanged: (_) => provider.toggleReminder(r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.danger),
                              onPressed: () => provider.deleteReminder(r.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

// ===========================================================================
// HISTORY TAB
// ===========================================================================
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final logs = provider.logs;
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('History'),
            automaticallyImplyLeading: false,
          ),
          body: logs.isEmpty
              ? const EmptyState(
                  message: 'No history yet',
                  hint: 'Tap "Take Now" on a medicine to log it',
                  icon: Icons.history_rounded,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) {
                    final log = logs[i];
                    final color = log.status == 'taken'
                        ? AppTheme.success
                        : log.status == 'skipped'
                            ? AppTheme.warning
                            : AppTheme.danger;
                    final icon = log.status == 'taken'
                        ? Icons.check_circle_rounded
                        : log.status == 'skipped'
                            ? Icons.skip_next_rounded
                            : Icons.cancel_rounded;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.medicineName,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${log.profileName} • ${log.dose}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                log.status.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(log.takenAt),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(dt);
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today $timeStr';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday $timeStr';
    }
    return '${DateFormat('d MMM').format(dt)} $timeStr';
  }
}

// ===========================================================================
// PROFILES TAB
// ===========================================================================
class ProfilesTab extends StatelessWidget {
  const ProfilesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Family Profiles'),
            automaticallyImplyLeading: false,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddProfileSheet(context, provider),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add'),
          ),
          body: provider.profiles.isEmpty
              ? const EmptyState(
                  message: 'No profiles yet',
                  hint: 'Add family members to track their medicines',
                  icon: Icons.people_outline_rounded,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: provider.profiles.length,
                  itemBuilder: (ctx, i) {
                    final p = provider.profiles[i];
                    final isSelected =
                        provider.selectedProfile?.id == p.id;
                    return FadeInUp(
                      duration: const Duration(milliseconds: 250),
                      delay: Duration(milliseconds: i * 40),
                      child: GestureDetector(
                        onTap: () => provider.selectProfile(p),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(p.avatar,
                                      style: const TextStyle(fontSize: 28)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${p.relation} • Age ${p.age}',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: AppTheme.primary,
                                    size: 18,
                                  ),
                                ),
                              if (p.relation != 'Self')
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppTheme.danger,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, provider, p),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, Profile profile) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text(
          'Removing ${profile.name} will also remove all of their medicines and reminders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteProfile(profile.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddProfileSheet(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String relation = 'Father';
    String avatar = '👨';
    const avatars = ['👨', '👩', '👴', '👵', '🧒', '👦', '👧', '🧑'];
    const relations = [
      'Father',
      'Mother',
      'Child',
      'Sibling',
      'Spouse',
      'Other'
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
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
                  'Add Family Member',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Choose avatar',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: avatars.map((a) {
                    final sel = avatar == a;
                    return GestureDetector(
                      onTap: () => setSheet(() => avatar = a),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.primary.withValues(alpha: 0.18)
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                sel ? AppTheme.primary : Colors.transparent,
                          ),
                        ),
                        child:
                            Text(a, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null) return 'Enter a valid number';
                    if (n < 0 || n > 130) return 'Enter a realistic age';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
  value: relation,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Relation',
                    prefixIcon: Icon(Icons.family_restroom_rounded),
                  ),
                  items: relations
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) =>
                      setSheet(() => relation = v ?? relation),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await provider.addProfile(
                        name: nameCtrl.text.trim(),
                        relation: relation,
                        age: int.parse(ageCtrl.text.trim()),
                        avatar: avatar,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Add Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

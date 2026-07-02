import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../services/app_provider.dart';
import '../theme.dart';
import '../utils/validators.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine; // null = create; non-null = edit

  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _alertCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _type = 'Tablet';
  String _color = '#FF6B6B';
  bool _isSaving = false;

  static const _types = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Drops',
    'Cream',
  ];
  static const _typeEmojis = {
    'Tablet': '💊',
    'Capsule': '🔴',
    'Syrup': '🧴',
    'Injection': '💉',
    'Drops': '💧',
    'Cream': '🧪',
  };

  // Parallel list of hex codes for the colors in `AppTheme.medicineColors`.
  // Kept side-by-side rather than recomputed from `Color` so this file stays
  // compatible across Flutter SDK versions.
  static const _medicineColorHex = [
    '#FF6B6B',
    '#4ECDC4',
    '#45B7D1',
    '#F7DC6F',
    '#96CEB4',
    '#DDA0DD',
    '#FF8C69',
    '#87CEEB',
    '#FFB6C1',
    '#98FB98',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    if (m != null) {
      _nameCtrl.text = m.name;
      _dosageCtrl.text = m.dosage;
      _stockCtrl.text = m.currentStock.toString();
      _alertCtrl.text = m.lowStockAlert.toString();
      _notesCtrl.text = m.notes;
      _type = m.type;
      _color = m.color;
    } else {
      _stockCtrl.text = '30';
      _alertCtrl.text = '5';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _stockCtrl.dispose();
    _alertCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<AppProvider>();
    final stock = int.parse(_stockCtrl.text.trim());
    final alert = int.tryParse(_alertCtrl.text.trim()) ?? 5;
    final profileId = provider.selectedProfile?.id;

    if (profileId == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a profile before adding medicines.')),
      );
      return;
    }

    if (widget.medicine != null) {
      final updated = widget.medicine!.copyWith(
        name: _nameCtrl.text.trim(),
        dosage: _dosageCtrl.text.trim(),
        type: _type,
        currentStock: stock,
        totalStock: stock > widget.medicine!.totalStock
            ? stock
            : widget.medicine!.totalStock,
        lowStockAlert: alert,
        color: _color,
        notes: _notesCtrl.text.trim(),
      );
      await provider.updateMedicine(updated);
    } else {
      final medicine = Medicine(
        name: _nameCtrl.text.trim(),
        dosage: _dosageCtrl.text.trim(),
        type: _type,
        totalStock: stock,
        currentStock: stock,
        lowStockAlert: alert,
        color: _color,
        profileId: profileId,
        notes: _notesCtrl.text.trim(),
      );
      await provider.addMedicine(medicine);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.medicine != null
            ? 'Medicine updated'
            : 'Medicine added successfully'),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: Text(
          'Are you sure you want to delete ${widget.medicine!.name}? This will also delete all of its reminders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context
          .read<AppProvider>()
          .deleteMedicine(widget.medicine!.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicine != null;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Medicine' : 'Add Medicine'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const _SectionLabel(label: 'Medicine type'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final selected = _type == t;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withValues(alpha: 0.18)
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_typeEmojis[t] ?? '💊'),
                        const SizedBox(width: 6),
                        Text(
                          t,
                          style: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            const _SectionLabel(label: 'Color'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(AppTheme.medicineColors.length, (i) {
                final c = AppTheme.medicineColors[i];
                final hex = _medicineColorHex[i];
                final selected = _color == hex;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: c.withValues(alpha: 0.55),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Medicine name *',
                prefixIcon: Icon(Icons.medication_rounded),
              ),
              validator: (v) =>
                  Validators.notEmpty(v, field: 'Medicine name'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dosageCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g. 500mg, 5ml) *',
                prefixIcon: Icon(Icons.scale_rounded),
              ),
              validator: (v) => Validators.notEmpty(v, field: 'Dosage'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Current stock *',
                      prefixIcon: Icon(Icons.inventory_2_rounded),
                    ),
                    validator: (v) =>
                        Validators.positiveInt(v, field: 'Stock'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _alertCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Low alert at',
                      prefixIcon: Icon(Icons.warning_rounded),
                    ),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return null;
                      return Validators.positiveInt(v,
                          field: 'Alert threshold');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update medicine' : 'Add medicine',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete medicine'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side:
                        const BorderSide(color: AppTheme.danger, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      );
}

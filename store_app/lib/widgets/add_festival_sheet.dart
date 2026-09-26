import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
import '../models/festival_model.dart';
import '../services/festival_service.dart';

/// Manager/owner sheet to create a real festival in Firestore.
/// Dates and order-window are required — nothing is pre-seeded.
class AddFestivalSheet extends StatefulWidget {
  final String? storeId;
  final String? createdBy;
  final List<FestivalModel> existing;

  const AddFestivalSheet({
    super.key,
    this.storeId,
    this.createdBy,
    this.existing = const [],
  });

  static Future<FestivalModel?> show(
    BuildContext context, {
    String? storeId,
    String? createdBy,
    List<FestivalModel> existing = const [],
  }) {
    return showModalBottomSheet<FestivalModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFestivalSheet(
        storeId: storeId,
        createdBy: createdBy,
        existing: existing,
      ),
    );
  }

  @override
  State<AddFestivalSheet> createState() => _AddFestivalSheetState();
}

class _AddFestivalSheetState extends State<AddFestivalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _service = FestivalService();
  final _dateFmt = DateFormat('d MMM yyyy');

  DateTime? _startDate;
  DateTime? _endDate;
  int _advanceDays = 14;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime? get _orderBy {
    if (_startDate == null) return null;
    return _startDate!.subtract(Duration(days: _advanceDays));
  }

  List<FestivalModel> get _overlaps {
    if (_startDate == null || _endDate == null) return const [];
    return _service.overlappingFestivals(
      start: _startDate!,
      end: _endDate!,
      existing: widget.existing,
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? _today)
        : (_endDate ?? _startDate ?? _today);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_today) ? _today : initial,
      firstDate: _today,
      lastDate: _today.add(const Duration(days: 730)),
      helpText: isStart ? 'Festival start date' : 'Festival end date',
    );
    if (picked == null) return;
    final day = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      _error = null;
      if (isStart) {
        _startDate = day;
        if (_endDate == null || _endDate!.isBefore(day)) {
          _endDate = day;
        }
      } else {
        if (_startDate != null && day.isBefore(_startDate!)) {
          _error = 'End date cannot be before start date.';
          return;
        }
        _endDate = day;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      setState(() => _error = 'Choose start and end dates.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'End date cannot be before start date.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final created = await _service.createFestival(
        FestivalModel(
          id: '',
          name: _nameCtrl.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          advanceOrderDays: _advanceDays,
          createdAt: DateTime.now(),
          storeId: widget.storeId,
          createdBy: widget.createdBy,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save festival: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = (_startDate != null && _endDate != null)
        ? _endDate!.difference(_startDate!).inDays + 1
        : null;
    final orderBy = _orderBy;
    final daysUntil = _startDate?.difference(_today).inDays;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create festival',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set the real dates. Alerts and calendars follow the order window you choose.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Festival name *',
                    hintText: 'e.g. Diwali stock rush',
                    prefixIcon: Icon(Icons.celebration_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Enter a clearer name';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Starts',
                        value: _startDate == null
                            ? 'Pick date'
                            : _dateFmt.format(_startDate!),
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateButton(
                        label: 'Ends',
                        value: _endDate == null
                            ? 'Pick date'
                            : _dateFmt.format(_endDate!),
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Advance order days',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _advanceDays > 3
                          ? () => setState(() => _advanceDays -= 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_advanceDays',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      onPressed: _advanceDays < 90
                          ? () => setState(() => _advanceDays += 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                Slider(
                  value: _advanceDays.toDouble(),
                  min: 3,
                  max: 90,
                  divisions: 87,
                  activeColor: const Color(0xFFEA580C),
                  label: '$_advanceDays days',
                  onChanged: (v) => setState(() => _advanceDays = v.round()),
                ),
                if (orderBy != null && duration != null && daysUntil != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Text(
                      'Runs $duration day${duration == 1 ? '' : 's'}. '
                      'Starts in $daysUntil day${daysUntil == 1 ? '' : 's'}. '
                      'Order-by / first alert: ${_dateFmt.format(orderBy)}.',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF9A3412),
                        height: 1.4,
                      ),
                    ),
                  ),
                if (_overlaps.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Overlaps ${_overlaps.map((f) => f.name).join(', ')}. You can still save.',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_saving ? 'Saving…' : 'Save to Firestore'),
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

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 16, color: Color(0xFFEA580C)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

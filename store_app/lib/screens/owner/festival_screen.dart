import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../models/festival_model.dart';
import '../../widgets/store_header_widget.dart';

class FestivalScreen extends StatefulWidget {
  const FestivalScreen({super.key});

  @override
  State<FestivalScreen> createState() => _FestivalScreenState();
}

class _FestivalScreenState extends State<FestivalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Enterprise Top Header
            const StoreHeaderWidget(
              title: 'Festival Demand',
              subtitle: 'SEASONAL SURGE PLANNER • AI Spike Forecaster',
            ),

            // 2. Festive Warm Surge Hero Banner
            _buildFestiveHeroBanner(),

            // 3. Tab Bar
            _buildTabBar(),

            // 4. Content
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _FestivalsTab(db: _db),
                  _DemandAlertsTab(db: _db),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFestiveHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC2410C), Color(0xFFEA580C), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'AI SEASONAL SURGE PULSE',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddFestivalSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFC2410C),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text(
                  'Add Event',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Festival Demand & Stock Buffer',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Predict seasonal rush surges and lock supply lines 2-3 weeks in advance across all outlets.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabs,
        indicatorColor: const Color(0xFFEA580C),
        indicatorWeight: 3,
        labelColor: const Color(0xFFEA580C),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Festivals Schedule'),
          Tab(text: 'Demand Alerts'),
        ],
      ),
    );
  }

  void _showAddFestivalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddFestivalSheet(db: _db),
    );
  }
}

class _FestivalsTab extends StatelessWidget {
  final FirebaseFirestore db;
  const _FestivalsTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection(AppConstants.festivalsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('startDate')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError || snap.connectionState == ConnectionState.waiting) {
          if (snap.hasError) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.celebration_outlined,
                    size: 56, color: AppColors.textTertiary),
                SizedBox(height: 12),
                Text('No festivals added yet',
                    style: TextStyle(color: AppColors.textSecondary)),
              ]),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final festivals = snap.data?.docs
                .map(FestivalModel.fromFirestore)
                .toList() ??
            [];
        if (festivals.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.celebration_outlined,
                    size: 56, color: AppColors.textTertiary),
                SizedBox(height: 12),
                Text('No festivals added yet',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: festivals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _FestivalCard(festival: festivals[i]),
        );
      },
    );
  }
}

class _FestivalCard extends StatelessWidget {
  final FestivalModel festival;
  const _FestivalCard({required this.festival});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    Color statusColor;
    String statusLabel;
    if (festival.isOngoing) {
      statusColor = AppColors.success;
      statusLabel = 'ONGOING';
    } else if (festival.isUpcoming) {
      statusColor = festival.needsAlert ? AppColors.warning : AppColors.info;
      statusLabel = festival.needsAlert ? 'ORDER NOW' : 'UPCOMING';
    } else {
      statusColor = AppColors.textTertiary;
      statusLabel = 'PAST';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.celebration_rounded,
                    color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      festival.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dateFmt.format(festival.startDate)} – ${dateFmt.format(festival.endDate)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: statusColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 5),
                Text(
                  'Order by: ${dateFmt.format(festival.alertDate)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.schedule_rounded,
                    size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 5),
                Text(
                  '${festival.advanceOrderDays}d buffer',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemandAlertsTab extends StatelessWidget {
  final FirebaseFirestore db;
  const _DemandAlertsTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection(AppConstants.festivalAlertsCollection)
          .where('isAcknowledged', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        // Gracefully handle collection-not-found (400) or permission-denied
        if (snap.hasError) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_outline,
                  size: 56, color: AppColors.success),
              SizedBox(height: 12),
              Text('No pending festival alerts',
                  style: TextStyle(color: AppColors.textSecondary)),
            ]),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final alerts = snap.data?.docs
                .map(FestivalDemandAlert.fromFirestore)
                .toList() ??
            [];
        if (alerts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 56, color: AppColors.success),
                SizedBox(height: 12),
                Text('No pending festival alerts',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) =>
              _DemandAlertCard(alert: alerts[i], db: db),
        );
      },
    );
  }
}

class _DemandAlertCard extends StatelessWidget {
  final FestivalDemandAlert alert;
  final FirebaseFirestore db;
  const _DemandAlertCard({required this.alert, required this.db});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD97706), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  alert.productName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await db
                      .collection(AppConstants.festivalAlertsCollection)
                      .doc(alert.id)
                      .update({'isAcknowledged': true});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Acknowledge',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.celebration_outlined, size: 13, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'Festival: ${alert.festivalName}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AlertStat(
                  label: 'Current Stock',
                  value: '${alert.currentStock}',
                  color: const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _AlertStat(
                  label: 'Required',
                  value: '${alert.recommendedStock}',
                  color: const Color(0xFFD97706)),
              const SizedBox(width: 8),
              _AlertStat(
                  label: 'Shortfall',
                  value: '${alert.stockShortfall}',
                  color: const Color(0xFFDC2626)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AlertStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFestivalSheet extends StatefulWidget {
  final FirebaseFirestore db;
  const _AddFestivalSheet({required this.db});

  @override
  State<_AddFestivalSheet> createState() =>
      _AddFestivalSheetState();
}

class _AddFestivalSheetState extends State<_AddFestivalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int _advanceDays = 14;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select start and end dates')));
      return;
    }
    setState(() => _saving = true);
    final ref = widget.db
        .collection(AppConstants.festivalsCollection)
        .doc();
    final festival = FestivalModel(
      id: ref.id,
      name: _nameCtrl.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      advanceOrderDays: _advanceDays,
      createdAt: DateTime.now(),
    );
    await ref.set(festival.toFirestore());
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Festival added.')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add Festival',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Festival Name *',
                  prefixIcon: Icon(Icons.celebration_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_startDate != null
                        ? dateFmt.format(_startDate!)
                        : 'Start Date *'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_endDate != null
                        ? dateFmt.format(_endDate!)
                        : 'End Date *'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Advance order days:',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                const Spacer(),
                IconButton(
                  onPressed: _advanceDays > 7
                      ? () => setState(() => _advanceDays -= 7)
                      : null,
                  icon: const Icon(Icons.remove),
                  color: AppColors.primary,
                ),
                Text('$_advanceDays days',
                    style: const TextStyle(
                        fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                IconButton(
                  onPressed: () => setState(() => _advanceDays += 7),
                  icon: const Icon(Icons.add),
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Add Festival'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

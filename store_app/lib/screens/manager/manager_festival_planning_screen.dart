import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../config/app_theme.dart';
import '../../widgets/store_header_widget.dart';
import '../../providers/store_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/festival_model.dart';
import '../../models/inventory_model.dart';
import '../../services/festival_service.dart';
import '../../widgets/add_festival_sheet.dart';

/// Manager festival alerts, per-festival calendars, and stock buffers.
/// All lists stream live from Firestore.
class ManagerFestivalPlanningScreen extends StatefulWidget {
  const ManagerFestivalPlanningScreen({super.key});

  @override
  State<ManagerFestivalPlanningScreen> createState() =>
      _ManagerFestivalPlanningScreenState();
}

class _ManagerFestivalPlanningScreenState
    extends State<ManagerFestivalPlanningScreen>
    with SingleTickerProviderStateMixin {
  final FestivalService _festivalService = FestivalService();
  late TabController _tabs;

  FestivalModel? _selectedFestival;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Timer? _syncDebounce;
  String? _lastSyncKey;
  List<FestivalModel> _festivals = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  void _scheduleAlertSync({
    required String storeId,
    required String managerId,
    required List<FestivalModel> festivals,
  }) {
    final actionable = festivals
        .where((f) => f.requiresManagerAction)
        .map((f) => '${f.id}:${f.phase.name}')
        .join(',');
    final key = '$storeId|$actionable';
    if (key == _lastSyncKey) return;
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 900), () async {
      _lastSyncKey = key;
      try {
        await _festivalService.syncLogicalAlerts(
          storeId: storeId,
          managerId: managerId,
          festivals: festivals,
        );
      } catch (e) {
        debugPrint('Festival alert sync failed: $e');
      }
    });
  }

  Future<void> _openCreateFestival() async {
    final storeId = context.read<StoreProvider>().selectedStore?.id;
    final userId = context.read<AuthProvider>().currentUser?.id;
    final created = await AddFestivalSheet.show(
      context,
      storeId: storeId,
      createdBy: userId,
      existing: _festivals,
    );
    if (created == null || !mounted) return;
    setState(() {
      _selectedFestival = created;
      _focusedDay = created.startDay;
      _selectedDay = created.startDay;
    });
    _tabs.animateTo(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${created.name} saved. Calendar and alerts will follow these dates.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeId =
        context.watch<StoreProvider>().selectedStore?.id ?? '';
    final managerId = context.watch<AuthProvider>().currentUser?.id ?? '';
    final inventoryProvider = context.watch<InventoryProvider>();

    if (storeId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please select a store')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateFestival,
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create festival',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<FestivalModel>>(
          stream: _festivalService.getFestivalsStream(),
          builder: (context, festSnap) {
            if (festSnap.hasError) {
              return _ErrorState(
                message: 'Could not load festivals',
                detail: festSnap.error.toString(),
              );
            }

            final festivals = festSnap.data ?? [];
            final relevant = festivals.where((f) => !f.isPast).toList();
            _festivals = relevant;
            final selected = _resolveSelected(relevant);

            return StreamBuilder<List<InventoryModel>>(
              stream: inventoryProvider.watchInventory(storeId),
              builder: (context, invSnap) {
                final inventory = invSnap.data ?? [];
                if (festSnap.hasData) {
                  _scheduleAlertSync(
                    storeId: storeId,
                    managerId: managerId,
                    festivals: relevant,
                  );
                }

                return StreamBuilder<List<FestivalDemandAlert>>(
                  stream: _festivalService.getStoreFestivalAlertsStream(storeId),
                  builder: (context, alertSnap) {
                    final alerts = (alertSnap.data ?? [])
                        .where((a) =>
                            !a.isAcknowledged &&
                            a.alertKind == FestivalAlertKind.timeline)
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StoreHeaderWidget(
                          title: 'Festival Planning',
                          subtitle:
                              'LIVE FIRESTORE • Alerts, calendars & buffers',
                          onNotificationTap: () =>
                              context.go('/manager/notifications'),
                        ),
                        _HeroBanner(
                          festival: selected,
                          alertCount: alerts.length,
                          onCreate: _openCreateFestival,
                        ),
                        _TabBar(controller: _tabs, alertCount: alerts.length),
                        Expanded(
                          child: festSnap.connectionState ==
                                      ConnectionState.waiting &&
                                  !festSnap.hasData
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFEA580C),
                                  ),
                                )
                              : TabBarView(
                                  controller: _tabs,
                                  children: [
                                    _AlertsTab(
                                      alerts: alerts,
                                      festivals: relevant,
                                      onAcknowledge: (id) => _festivalService
                                          .acknowledgeFestivalAlert(id),
                                      onOpenCalendar: (festival) {
                                        setState(() {
                                          _selectedFestival = festival;
                                          _focusedDay = festival.startDay;
                                          _selectedDay = festival.startDay;
                                        });
                                        _tabs.animateTo(1);
                                      },
                                      onCreate: _openCreateFestival,
                                    ),
                                    _CalendarsTab(
                                      festivals: relevant,
                                      selectedFestival: selected,
                                      focusedDay: _focusedDay,
                                      selectedDay: _selectedDay,
                                      onCreate: _openCreateFestival,
                                      onSelectFestival: (festival) {
                                        setState(() {
                                          _selectedFestival = festival;
                                          _focusedDay = festival.startDay;
                                          _selectedDay = festival.startDay;
                                        });
                                      },
                                      onDaySelected: (day, focused) {
                                        setState(() {
                                          _selectedDay = day;
                                          _focusedDay = focused;
                                          final match = _festivalOnDay(
                                            relevant,
                                            day,
                                          );
                                          if (match != null) {
                                            _selectedFestival = match;
                                          }
                                        });
                                      },
                                      onPageChanged: (focused) {
                                        setState(() => _focusedDay = focused);
                                      },
                                    ),
                                    _PlanningTab(
                                      festivals: relevant,
                                      selectedFestival: selected,
                                      inventory: inventory,
                                      onCreate: _openCreateFestival,
                                      onSelectFestival: (festival) {
                                        setState(
                                          () => _selectedFestival = festival,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  FestivalModel? _resolveSelected(List<FestivalModel> festivals) {
    if (festivals.isEmpty) return null;
    if (_selectedFestival != null) {
      final match = festivals.where((f) => f.id == _selectedFestival!.id);
      if (match.isNotEmpty) return match.first;
    }
    final urgent = festivals.where((f) => f.requiresManagerAction);
    if (urgent.isNotEmpty) return urgent.first;
    return festivals.first;
  }

  FestivalModel? _festivalOnDay(List<FestivalModel> festivals, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    for (final f in festivals) {
      if (!d.isBefore(f.startDay) && !d.isAfter(f.endDay)) return f;
    }
    return null;
  }
}

class _TabBar extends StatelessWidget {
  final TabController controller;
  final int alertCount;
  const _TabBar({required this.controller, required this.alertCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        indicatorColor: const Color(0xFFEA580C),
        indicatorWeight: 3,
        labelColor: const Color(0xFFEA580C),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        tabs: [
          Tab(
            text: alertCount > 0 ? 'Alerts ($alertCount)' : 'Alerts',
          ),
          const Tab(text: 'Calendars'),
          const Tab(text: 'Planning'),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final FestivalModel? festival;
  final int alertCount;
  final VoidCallback onCreate;
  const _HeroBanner({
    required this.festival,
    required this.alertCount,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntil = festival?.daysUntilStart ?? 0;
    final phase = festival?.phase;
    String subtitle;
    if (festival == null) {
      subtitle = 'No upcoming festivals in Firestore';
    } else if (phase == FestivalPhase.ongoing) {
      subtitle = 'Festival is live — watch stock-outs';
    } else if (daysUntil >= 0) {
      subtitle = '$daysUntil days until ${festival!.name} starts';
    } else {
      subtitle = festival!.name;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFEA580C), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.celebration_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  festival?.name ?? 'Festival desk',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              alertCount == 0 ? 'Clear' : '$alertCount live',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEA580C),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onCreate,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  final List<FestivalDemandAlert> alerts;
  final List<FestivalModel> festivals;
  final Future<void> Function(String id) onAcknowledge;
  final void Function(FestivalModel festival) onOpenCalendar;
  final VoidCallback onCreate;

  const _AlertsTab({
    required this.alerts,
    required this.festivals,
    required this.onAcknowledge,
    required this.onOpenCalendar,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 56, color: AppColors.success),
            const SizedBox(height: 12),
            const Text(
              'No open festival alerts',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              festivals.isEmpty
                  ? 'Create a festival with start, end, and order-by dates. Alerts follow those dates automatically.'
                  : 'No festivals need action right now. Check the calendar for upcoming dates.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            if (festivals.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create festival'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final timeline = alerts.where((a) => a.alertKind == FestivalAlertKind.timeline);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (timeline.isNotEmpty) ...[
          const _SectionLabel('Festival timing'),
          const SizedBox(height: 8),
          ...timeline.map((alert) {
            final festival = festivals.cast<FestivalModel?>().firstWhere(
                  (f) => f?.id == alert.festivalId,
                  orElse: () => null,
                );
            return _AlertCard(
              alert: alert,
              onAcknowledge: () => onAcknowledge(alert.id),
              onCalendar: festival == null ? null : () => onOpenCalendar(festival),
            );
          }),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Color(0xFF64748B),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final FestivalDemandAlert alert;
  final VoidCallback onAcknowledge;
  final VoidCallback? onCalendar;
  final VoidCallback? onRestock;

  const _AlertCard({
    required this.alert,
    required this.onAcknowledge,
    this.onCalendar,
    this.onRestock,
  });

  Color get _color {
    switch (alert.severity) {
      case 'urgent':
        return const Color(0xFFDC2626);
      case 'info':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFFEA580C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alert.alertKind == FestivalAlertKind.timeline
                    ? Icons.event_available_rounded
                    : Icons.inventory_2_rounded,
                color: _color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.alertKind == FestivalAlertKind.timeline
                      ? alert.festivalName
                      : alert.productName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  alert.severity.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message.isNotEmpty
                ? alert.message
                : 'Festival ${alert.festivalName} needs attention.',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
          if (alert.alertKind == FestivalAlertKind.stock) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniStat('On hand', '${alert.currentStock}', const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _MiniStat('Need', '${alert.recommendedStock}', const Color(0xFFD97706)),
                const SizedBox(width: 8),
                _MiniStat('Gap', '${alert.stockShortfall}', const Color(0xFFDC2626)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: onAcknowledge,
                child: const Text('Acknowledge'),
              ),
              if (onCalendar != null)
                TextButton(
                  onPressed: onCalendar,
                  child: const Text('Open calendar'),
                ),
              if (onRestock != null)
                TextButton(
                  onPressed: onRestock,
                  child: const Text('Restock'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _festivalPalette = [
  Color(0xFFEA580C),
  Color(0xFF7C3AED),
  Color(0xFF0F766E),
  Color(0xFF2563EB),
  Color(0xFFDB2777),
];

Color _festivalColor(List<FestivalModel> festivals, FestivalModel festival) {
  final index = festivals.indexWhere((f) => f.id == festival.id);
  return _festivalPalette[index < 0 ? 0 : index % _festivalPalette.length];
}

class _CalendarsTab extends StatelessWidget {
  final List<FestivalModel> festivals;
  final FestivalModel? selectedFestival;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final ValueChanged<FestivalModel> onSelectFestival;
  final void Function(DateTime day, DateTime focused) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final VoidCallback onCreate;

  const _CalendarsTab({
    required this.festivals,
    required this.selectedFestival,
    required this.focusedDay,
    required this.selectedDay,
    required this.onSelectFestival,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onCreate,
  });

  Map<DateTime, List<FestivalModel>> _events() {
    final map = <DateTime, List<FestivalModel>>{};
    for (final festival in festivals) {
      var cursor = festival.startDay;
      while (!cursor.isAfter(festival.endDay)) {
        final key = DateTime(cursor.year, cursor.month, cursor.day);
        map.putIfAbsent(key, () => []).add(festival);
        cursor = cursor.add(const Duration(days: 1));
      }
      final orderKey = DateTime(
        festival.alertDate.year,
        festival.alertDate.month,
        festival.alertDate.day,
      );
      map.putIfAbsent(orderKey, () => []);
      if (!map[orderKey]!.contains(festival)) {
        map[orderKey]!.add(festival);
      }
    }
    return map;
  }

  List<FestivalModel> _loader(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events()[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (festivals.isEmpty) {
      return _EmptyFestivals(onCreate: onCreate);
    }

    final dateFmt = DateFormat('d MMM');
    final selected = selectedFestival ?? festivals.first;
    final accent = _festivalColor(festivals, selected);
    final dayEvents = _loader(selectedDay);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: festivals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final festival = festivals[i];
              return _FestivalChip(
                festival: festival,
                color: _festivalColor(festivals, festival),
                selected: festival.id == selected.id,
                onTap: () => onSelectFestival(festival),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _FestivalMonthCalendar(
          festivals: festivals,
          selectedFestival: selected,
          accent: accent,
          focusedDay: focusedDay,
          selectedDay: selectedDay,
          eventLoader: _loader,
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
        ),
        const SizedBox(height: 12),
        _CalendarLegend(accent: accent),
        const SizedBox(height: 14),
        _FestivalTimelineCard(
          festival: selected,
          accent: accent,
          dateFmt: dateFmt,
        ),
        if (dayEvents.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SelectedDayPanel(
            day: selectedDay,
            events: dayEvents,
            festivals: festivals,
            dateFmt: dateFmt,
          ),
        ],
      ],
    );
  }
}

class _FestivalChip extends StatelessWidget {
  final FestivalModel festival;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FestivalChip({
    required this.festival,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = festival.isOngoing
        ? 'Live now'
        : festival.isUrgent
            ? 'In ${festival.daysUntilStart}d'
            : DateFormat('d MMM').format(festival.startDate);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 168,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.78)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : const Color(0xFFE2E8F0),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    festival.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color,
              ),
            ),
            Text(
              '${festival.durationDays} day event',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: selected ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FestivalMonthCalendar extends StatelessWidget {
  final List<FestivalModel> festivals;
  final FestivalModel selectedFestival;
  final Color accent;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<FestivalModel> Function(DateTime) eventLoader;
  final void Function(DateTime day, DateTime focused) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  const _FestivalMonthCalendar({
    required this.festivals,
    required this.selectedFestival,
    required this.accent,
    required this.focusedDay,
    required this.selectedDay,
    required this.eventLoader,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C2D12),
                  accent,
                  const Color(0xFFF59E0B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(focusedDay),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${selectedFestival.name} highlighted',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
            child: TableCalendar<FestivalModel>(
              firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
              lastDay: DateTime.utc(DateTime.now().year + 2, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              eventLoader: eventLoader,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              rowHeight: 48,
              daysOfWeekHeight: 28,
              headerVisible: false,
              availableGestures: AvailableGestures.horizontalSwipe,
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
                weekendStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEA580C),
                ),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                markersMaxCount: 0,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focused) =>
                    _buildDay(day, outside: false),
                todayBuilder: (context, day, focused) =>
                    _buildDay(day, isToday: true),
                selectedBuilder: (context, day, focused) =>
                    _buildDay(day, isPicked: true),
                outsideBuilder: (context, day, focused) =>
                    _buildDay(day, outside: true),
              ),
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Row(
              children: [
                _MonthNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => onPageChanged(
                    DateTime(focusedDay.year, focusedDay.month - 1, 1),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    final now = DateTime.now();
                    onDaySelected(now, now);
                  },
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                const Spacer(),
                _MonthNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => onPageChanged(
                    DateTime(focusedDay.year, focusedDay.month + 1, 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDay(
    DateTime day, {
    bool isToday = false,
    bool isPicked = false,
    bool outside = false,
  }) {
    final inRange = !day.isBefore(selectedFestival.startDay) &&
        !day.isAfter(selectedFestival.endDay);
    final isStart = isSameDay(day, selectedFestival.startDay);
    final isEnd = isSameDay(day, selectedFestival.endDay);
    final isOrder = isSameDay(day, selectedFestival.alertDate);
    final events = eventLoader(day);
    final others = events.where((f) => f.id != selectedFestival.id).toList();

    Color textColor = const Color(0xFF0F172A);
    if (outside) textColor = const Color(0xFFCBD5E1);
    if (inRange) textColor = const Color(0xFF7C2D12);
    if (isStart || isEnd || isPicked) textColor = Colors.white;
    if (isOrder && !isStart && !isEnd && !isPicked) {
      textColor = const Color(0xFF1D4ED8);
    }

    BorderRadius radius = BorderRadius.circular(10);
    if (inRange && selectedFestival.durationDays > 1) {
      if (isStart) {
        radius = const BorderRadius.horizontal(left: Radius.circular(18));
      } else if (isEnd) {
        radius = const BorderRadius.horizontal(right: Radius.circular(18));
      } else {
        radius = BorderRadius.zero;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (inRange)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: isStart || isEnd || isPicked
                    ? accent
                    : accent.withValues(alpha: 0.16),
                borderRadius: radius,
              ),
            ),
          if (!inRange && isPicked)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
          if (!inRange && isToday && !isPicked)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: accent, width: 1.5),
                shape: BoxShape.circle,
              ),
            ),
          if (isOrder && !isStart && !isEnd)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2563EB), width: 2),
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
              if (others.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: others.take(3).map((f) {
                      return Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _festivalColor(festivals, f),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MonthNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: const Color(0xFF334155)),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  final Color accent;
  const _CalendarLegend({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _LegendPill(color: accent, label: 'Festival days'),
        const _LegendPill(color: Color(0xFF2563EB), label: 'Order-by', outlined: true),
        _LegendPill(color: accent, label: 'Start / end', filled: true),
        const _LegendPill(color: Color(0xFF94A3B8), label: 'Other events', dotted: true),
      ],
    );
  }
}

class _LegendPill extends StatelessWidget {
  final Color color;
  final String label;
  final bool outlined;
  final bool filled;
  final bool dotted;

  const _LegendPill({
    required this.color,
    required this.label,
    this.outlined = false,
    this.filled = false,
    this.dotted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotted)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          else
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: filled
                    ? color
                    : outlined
                        ? Colors.transparent
                        : color.withValues(alpha: 0.22),
                border: outlined ? Border.all(color: color, width: 2) : null,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _FestivalTimelineCard extends StatelessWidget {
  final FestivalModel festival;
  final Color accent;
  final DateFormat dateFmt;

  const _FestivalTimelineCard({
    required this.festival,
    required this.accent,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${festival.name} timeline',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _TimelineNode(
                title: 'Order by',
                value: dateFmt.format(festival.alertDate),
                color: const Color(0xFF2563EB),
              ),
              Expanded(child: Container(height: 2, color: accent.withValues(alpha: 0.25))),
              _TimelineNode(
                title: 'Starts',
                value: dateFmt.format(festival.startDate),
                color: accent,
              ),
              Expanded(child: Container(height: 2, color: accent.withValues(alpha: 0.25))),
              _TimelineNode(
                title: 'Ends',
                value: dateFmt.format(festival.endDate),
                color: const Color(0xFFC2410C),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _TimelineNode({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SelectedDayPanel extends StatelessWidget {
  final DateTime day;
  final List<FestivalModel> events;
  final List<FestivalModel> festivals;
  final DateFormat dateFmt;

  const _SelectedDayPanel({
    required this.day,
    required this.events,
    required this.festivals,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, d MMMM').format(day),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ...events.map((festival) {
          final color = _festivalColor(festivals, festival);
          String role = 'Festival day';
          if (isSameDay(day, festival.alertDate)) role = 'Order-by date';
          if (isSameDay(day, festival.startDay)) role = 'Festival starts';
          if (isSameDay(day, festival.endDay)) role = 'Festival ends';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        role,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${dateFmt.format(festival.startDate)} – ${dateFmt.format(festival.endDate)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PlanningTab extends StatelessWidget {
  final List<FestivalModel> festivals;
  final FestivalModel? selectedFestival;
  final List<InventoryModel> inventory;
  final ValueChanged<FestivalModel> onSelectFestival;
  final VoidCallback onCreate;

  const _PlanningTab({
    required this.festivals,
    required this.selectedFestival,
    required this.inventory,
    required this.onSelectFestival,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    if (festivals.isEmpty) return _EmptyFestivals(onCreate: onCreate);
    final festival = selectedFestival ?? festivals.first;
    final service = FestivalService();
    final daysUntil = festival.daysUntilStart;
    final isUrgent = festival.isUrgent || festival.isOngoing;

    final categoryGaps = <String, int>{};
    for (final item in inventory) {
      final recommended = service.recommendedFestivalStock(item);
      final gap = recommended - item.currentStock;
      if (gap > 0) {
        categoryGaps[item.category] =
            (categoryGaps[item.category] ?? 0) + gap;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (festivals.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: festivals.map((f) {
                final selected = f.id == festival.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 12),
                  child: ChoiceChip(
                    label: Text(f.name),
                    selected: selected,
                    onSelected: (_) => onSelectFestival(f),
                    selectedColor: const Color(0xFFEA580C),
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
              width: isUrgent ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                festival.isOngoing
                    ? '${festival.name} is ongoing'
                    : '$daysUntil days until ${festival.name}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateTime.now().isAfter(festival.alertDate) && festival.isUpcoming
                    ? 'Order deadline passed — rush orders if stock is short'
                    : 'Order by ${DateFormat('d MMM').format(festival.alertDate)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: DateTime.now().isAfter(festival.alertDate) &&
                          festival.isUpcoming
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category buffers',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ...FestivalService.categoryMultipliers.entries.map((entry) {
                final gap = categoryGaps[entry.key] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value}x',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                      if (gap > 0) ...[
                        const SizedBox(width: 10),
                        Text(
                          'short $gap',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => context.go('/manager/restocking'),
          icon: const Icon(Icons.shopping_cart_rounded, size: 18),
          label: const Text('Generate festival stock orders'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEA580C),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyFestivals extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyFestivals({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_outlined, size: 56, color: Color(0xFFEA580C)),
            const SizedBox(height: 12),
            const Text(
              'No upcoming festivals',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a festival with real start, end, and order-by dates. Calendars and alerts follow those dates from Firestore.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create festival'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String detail;
  const _ErrorState({required this.message, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

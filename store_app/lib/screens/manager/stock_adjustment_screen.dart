import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/inventory_model.dart';
import '../../widgets/store_header_widget.dart';

class StockAdjustmentScreen extends StatefulWidget {
  const StockAdjustmentScreen({super.key});

  @override
  State<StockAdjustmentScreen> createState() =>
      _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  String? _selectedProductId;
  String? _selectedProductName;
  int _currentStock = 0;
  int _adjustQty = 0;
  bool _isAddition = true;
  AdjustmentReason _reason = AdjustmentReason.countCorrection;
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStock(String productId) async {
    final storeId =
        context.read<StoreProvider>().selectedStore?.id ?? '';
    final inv = await context
        .read<InventoryProvider>()
        .getItem(storeId, productId);
    setState(() => _currentStock = inv?.currentStock ?? 0);
  }

  Future<void> _apply() async {
    if (_selectedProductId == null || _adjustQty == 0) {
      setState(() => _error = 'Select a product and enter a valid quantity');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final storeProvider = context.read<StoreProvider>();
    final quantityChange = _isAddition ? _adjustQty : -_adjustQty;
    try {
      await context.read<InventoryProvider>().adjustStock(
            storeId: storeProvider.selectedStore!.id,
            productId: _selectedProductId!,
            productName: _selectedProductName!,
            quantityChange: quantityChange,
            reason: _reason,
            userId: auth.currentUser!.id,
            userName: auth.currentUser!.name,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock adjustment recorded.')),
        );
        setState(() {
          _selectedProductId = null;
          _selectedProductName = null;
          _currentStock = 0;
          _adjustQty = 0;
          _notesCtrl.clear();
        });
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final newStock = _isAddition
        ? _currentStock + _adjustQty
        : (_currentStock - _adjustQty).clamp(0, 999999);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Enterprise Top Header
              const StoreHeaderWidget(
                title: 'Stock Adjustment',
                subtitle: 'INVENTORY RECONCILIATION • Downtown Hub',
              ),

              // 2. Reconciliation Gradient Banner
              _buildAdjustmentBanner(newStock),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stock adjustments are logged with reason and user. Only adjust for legitimate reasons.',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            const Text('Product *',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedProductId,
              decoration: const InputDecoration(
                hintText: 'Select product',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              items: productProvider.products
                  .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final product = productProvider.products
                    .firstWhere((p) => p.id == v);
                setState(() {
                  _selectedProductId = v;
                  _selectedProductName = product.name;
                });
                _loadStock(v);
              },
            ),
            const SizedBox(height: 16),

            if (_selectedProductId != null) ...[
              Row(
                children: [
                  _StockBox(
                    label: 'Current Stock',
                    value: _currentStock,
                    color: AppColors.primary,
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppColors.textTertiary),
                  _StockBox(
                    label: 'After Adjustment',
                    value: newStock,
                    color:
                        newStock < _currentStock ? AppColors.error : AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            const Text('Adjustment Type',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _TypeBtn(
                    label: 'Add Stock',
                    icon: Icons.add_circle_outline,
                    isSelected: _isAddition,
                    color: AppColors.secondary,
                    onTap: () => setState(() => _isAddition = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeBtn(
                    label: 'Remove Stock',
                    icon: Icons.remove_circle_outline,
                    isSelected: !_isAddition,
                    color: AppColors.error,
                    onTap: () => setState(() => _isAddition = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('Quantity *',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  onPressed: _adjustQty > 0
                      ? () => setState(() => _adjustQty--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primary,
                ),
                Container(
                  width: 72,
                  alignment: Alignment.center,
                  child: Text('$_adjustQty',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () => setState(() => _adjustQty++),
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                ),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        hintText: 'Or type quantity'),
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      setState(() => _adjustQty = n.abs());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('Reason *',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<AdjustmentReason>(
              initialValue: _reason,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AdjustmentReason.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.displayName),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _reason = v);
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_saving || _selectedProductId == null || _adjustQty == 0)
                    ? null
                    : _apply,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white)))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_saving ? 'Saving...' : 'Apply Adjustment'),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
),
);
  }

  // ── Stock Reconciliation Banner ──
  Widget _buildAdjustmentBanner(int newStock) {
    final hasProduct = _selectedProductId != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stock Reconciliation',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Real-Time Balance & Discrepancy Control',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Audit Mode',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _adjustmentBannerStat(
                  'Item',
                  hasProduct ? (_selectedProductName?.split(' ').first ?? 'Selected') : 'None',
                  Icons.inventory_2_outlined,
                  const Color(0xFF93C5FD),
                ),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _adjustmentBannerStat(
                  'Current',
                  hasProduct ? '$_currentStock units' : '--',
                  Icons.archive_outlined,
                  const Color(0xFFFDE68A),
                ),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                _adjustmentBannerStat(
                  'Projected',
                  hasProduct ? '$newStock units' : '--',
                  Icons.trending_up_rounded,
                  const Color(0xFF6EE7B7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adjustmentBannerStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9.5,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _StockBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StockBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? color : AppColors.textSecondary,
                size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color:
                        isSelected ? color : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

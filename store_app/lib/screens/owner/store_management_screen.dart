import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/store_provider.dart';
import '../../models/store_model.dart';

class StoreManagementScreen extends StatelessWidget {
  const StoreManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Store Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStoreSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Store'),
      ),
      body: storeProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : storeProvider.stores.isEmpty
              ? const Center(child: Text('No stores added'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: storeProvider.stores.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _StoreCard(store: storeProvider.stores[i]),
                ),
    );
  }

  void _showAddStoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddStoreSheet(),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final StoreModel store;
  const _StoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(store.city,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: store.isActive
                      ? AppColors.successBg
                      : AppColors.errorBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    store.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                        color: store.isActive
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(store.address,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(store.phone,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddStoreSheet extends StatefulWidget {
  @override
  State<_AddStoreSheet> createState() => _AddStoreSheetState();
}

class _AddStoreSheetState extends State<_AddStoreSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<StoreProvider>().addStore(StoreModel(
            id: '',
            name: _nameCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            managerId: '',
            createdAt: DateTime.now(),
          ));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store added successfully.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const Text('Add New Store',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Store Name *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(labelText: 'City *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Adding...' : 'Add Store'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

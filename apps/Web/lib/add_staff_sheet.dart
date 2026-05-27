import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';

/// Quick-add staff roster entry (no sub-account signup required).
Future<bool?> showAddStaffSheet(BuildContext context, WidgetRef ref) {
  final palette = DashboardPalette.of(context);
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: _AddStaffSheetBody(palette: palette),
    ),
  );
}

class _AddStaffSheetBody extends ConsumerStatefulWidget {
  const _AddStaffSheetBody({required this.palette});

  final DashboardPalette palette;

  @override
  ConsumerState<_AddStaffSheetBody> createState() => _AddStaffSheetBodyState();
}

class _AddStaffSheetBodyState extends ConsumerState<_AddStaffSheetBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _staffIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedRole = 'Technician';
  static const _roleOptions = [
    'Mechanic',
    'Lead Mechanic',
    'Technician',
    'Driver',
    'Dispatcher',
  ];

  bool _canViewFleet = true;
  bool _canAcceptSos = false;
  bool _canViewFinance = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _staffIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final providerId = ref.read(currentUserProvider)?.id;
    if (providerId == null) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(providerStaffServiceProvider);
      final email = _emailController.text.trim();
      String? linkedUserId;
      if (email.isNotEmpty) {
        linkedUserId = await service.lookupUserIdByEmail(email);
      }

      await service.addStaff(
        providerId: providerId,
        fullName: _nameController.text,
        staffRole: _selectedRole,
        staffInternalId: _staffIdController.text,
        phoneNumber: _phoneController.text,
        email: email.isEmpty ? null : email,
        canViewFleet: _canViewFleet,
        canAcceptSos: _canAcceptSos,
        canViewFinance: _canViewFinance,
        staffUserId: linkedUserId,
      );

      ref.invalidate(providerStaffProvider(providerId));
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            linkedUserId != null
                ? 'Staff added and linked to their BoostDrive account.'
                : 'Staff added to your roster.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add staff: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Add team member', style: DashboardTypography.headlineMd(palette)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: palette.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Build your roster in seconds. If they already use BoostDrive with this email, we link their account automatically.',
              style: DashboardTypography.bodySm(palette).copyWith(color: palette.muted),
            ),
            const SizedBox(height: 24),
            _field(
              controller: _nameController,
              label: 'Full name',
              icon: Icons.person_outline,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _roleDropdown(palette),
            const SizedBox(height: 12),
            _field(
              controller: _staffIdController,
              label: 'Employee ID (optional)',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            _field(controller: _phoneController, label: 'Phone', icon: Icons.phone_outlined),
            const SizedBox(height: 12),
            _field(
              controller: _emailController,
              label: 'Email (optional)',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            Text('Access', style: DashboardTypography.labelMd(palette)),
            const SizedBox(height: 8),
            _permToggle('View fleet', _canViewFleet, (v) => setState(() => _canViewFleet = v)),
            _permToggle('Accept SOS', _canAcceptSos, (v) => setState(() => _canAcceptSos = v)),
            _permToggle('Finance', _canViewFinance, (v) => setState(() => _canViewFinance = v)),
            const SizedBox(height: 24),
            ProviderDashboardUi.primaryFilledButton(
              palette: palette,
              label: _isSaving ? 'SAVING…' : 'ADD TO ROSTER',
              icon: Icons.check,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final palette = widget.palette;
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: DashboardTypography.bodyMd(palette),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: palette.muted, size: 20),
        filled: true,
        fillColor: palette.surfaceContainer,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _roleDropdown(DashboardPalette palette) {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      dropdownColor: palette.surfaceContainerLowest,
      decoration: InputDecoration(
        labelText: 'Role',
        filled: true,
        fillColor: palette.surfaceContainer,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: _roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _selectedRole = v);
      },
    );
  }

  Widget _permToggle(String label, bool value, ValueChanged<bool> onChanged) {
    final palette = widget.palette;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: DashboardTypography.bodyMd(palette)),
      value: value,
      activeColor: palette.primary,
      onChanged: onChanged,
    );
  }
}

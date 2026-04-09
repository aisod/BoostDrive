import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'web_utils.dart';
import 'admin_states.dart';
import 'notification_hub_view.dart';

class UserManagementView extends ConsumerStatefulWidget {
  const UserManagementView({super.key});

  @override
  ConsumerState<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends ConsumerState<UserManagementView> {
  String _searchQuery = '';
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  bool _isProviderRole(String role) {
    final r = role.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ' ');
    if (r.isEmpty) return false;
    if (r == 'service_provider') return true;
    return r.contains('service provider') ||
        r.contains('service pro') ||
        r.contains('mechanic') ||
        r.contains('towing') ||
        r.contains('logistics') ||
        r.contains('rental');
  }

  bool _matchesGroup(UserProfile p, AdminUserGroup? selectedGroup) {
    final role = p.role.trim().toLowerCase();
    switch (selectedGroup) {
      case AdminUserGroup.provider:
        return _isProviderRole(role);
      case AdminUserGroup.customerSeller:
        return role == 'customer' || role == 'seller';
      case AdminUserGroup.admin:
        return p.isAdmin == true || role == 'admin' || role == 'super_admin';
      case null:
        return true;
    }
  }

  void _enterGroup(AdminUserGroup g) {
    ref.read(adminUserGroupProvider.notifier).state = g;
    setState(() {
      _searchQuery = '';
      _searchController.text = '';
      _statusFilter = 'all';
      _roleFilter = 'all';
    });
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(allProfilesProvider);
    final selectedGroup = ref.watch(adminUserGroupProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedGroup != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildFilters(selectedGroup),
            ],
          ),
        if (selectedGroup != null) const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            clipBehavior: Clip.antiAlias,
            child: profilesAsync.when(
              data: (profiles) {
                if (selectedGroup == null) {
                  return _buildGroupCards(profiles);
                }

                final filtered = profiles.where((p) {
                  if (!_matchesGroup(p, selectedGroup)) return false;

                  final q = _searchQuery.toLowerCase();
                  final matchesSearch = p.displayName.toLowerCase().contains(q) ||
                      p.email.toLowerCase().contains(q) ||
                      p.phoneNumber.contains(_searchQuery);

                  if (!matchesSearch) return false;

                  if (_statusFilter != 'all' && p.status.toLowerCase() != _statusFilter) {
                    return false;
                  }

                  final role = p.role.toLowerCase();
                  if (_roleFilter != 'all' && role != _roleFilter) {
                    return false;
                  }
                  return true;
                }).toList();

                return _buildUserTable(filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading users: $err')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCards(List<UserProfile> profiles) {
    final providerCount = profiles.where((p) => _isProviderRole(p.role)).length;
    final memberCount = profiles.where((p) {
      final r = p.role.toLowerCase();
      return r == 'customer' || r == 'seller';
    }).length;
    final adminCount = profiles.where((p) => p.isAdmin == true || p.role.toLowerCase() == 'admin' || p.role.toLowerCase() == 'super_admin').length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _groupCard(
            title: 'Service Providers',
            subtitle: '$providerCount total',
            icon: Icons.build_outlined,
            onTap: () => _enterGroup(AdminUserGroup.provider),
          ),
          _groupCard(
            title: 'Customers & Sellers',
            subtitle: '$memberCount total',
            icon: Icons.people_outline,
            onTap: () => _enterGroup(AdminUserGroup.customerSeller),
          ),
          _groupCard(
            title: 'Admins',
            subtitle: '$adminCount total',
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => _enterGroup(AdminUserGroup.admin),
          ),
        ],
      ),
    );
  }

  Widget _groupCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(icon, color: BoostDriveTheme.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(fontFamily: 'Manrope', 
                      fontWeight: FontWeight.w800, 
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle, 
                    style: TextStyle(fontFamily: 'Manrope', 
                      color: Colors.black87, 
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(AdminUserGroup selectedGroup) {
    return Row(
      children: [
        Container(
          width: 300,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by name, email, or phone...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
              prefixIcon: Icon(Icons.search, size: 18, color: Colors.black38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        if (selectedGroup == AdminUserGroup.admin) ...[
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _showAddAdminModal,
            icon: const Icon(Icons.admin_panel_settings, size: 18),
            label: const Text('NEW ADMIN', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: BoostDriveTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
        const SizedBox(width: 16),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              dropdownColor: Colors.white,
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                DropdownMenuItem(value: 'frozen', child: Text('Frozen')),
              ],
              onChanged: (v) => setState(() => _statusFilter = v!),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _roleFilter,
              dropdownColor: Colors.white,
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
              items: _roleItemsForGroup(selectedGroup),
              onChanged: (v) => setState(() => _roleFilter = v!),
            ),
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _roleItemsForGroup(AdminUserGroup selectedGroup) {
    if (selectedGroup == AdminUserGroup.provider) {
      return const [
        DropdownMenuItem(value: 'all', child: Text('All Providers')),
        DropdownMenuItem(value: 'service_provider', child: Text('Service Provider')),
        DropdownMenuItem(value: 'mechanic', child: Text('Mechanic')),
        DropdownMenuItem(value: 'towing', child: Text('Towing')),
        DropdownMenuItem(value: 'logistics', child: Text('Logistics')),
        DropdownMenuItem(value: 'rental', child: Text('Rental')),
      ];
    }
    if (selectedGroup == AdminUserGroup.admin) {
      return const [
        DropdownMenuItem(value: 'all', child: Text('All Admins')),
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
        DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
      ];
    }
    return const [
      DropdownMenuItem(value: 'all', child: Text('All Customers & Sellers')),
      DropdownMenuItem(value: 'customer', child: Text('Customer')),
      DropdownMenuItem(value: 'seller', child: Text('Seller')),
    ];
  }

  Widget _buildUserTable(List<UserProfile> users) {
    if (users.isEmpty) {
      return const Center(child: Text('No users found matching filters', style: TextStyle(color: Colors.black38)));
    }

    return Column(
      children: [
        Container(
          color: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              _headerCell('USER', flex: 4),
              _headerCell('ROLE', flex: 2),
              _headerCell('STATUS', flex: 2),
              _headerCell('JOINED', flex: 1),
              _headerCell('ACTIONS', flex: 2, align: TextAlign.end),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: users.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.05)),
            itemBuilder: (context, index) => _buildUserRow(users[index]),
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String label, {int flex = 1, TextAlign align = TextAlign.start}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(fontFamily: 'Manrope', 
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.5,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildUserRow(UserProfile u) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: u.profileImg.isNotEmpty ? NetworkImage(u.profileImg) : null,
                  child: u.profileImg.isEmpty
                      ? Text(
                          getInitials(u.displayName),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BoostDriveTheme.primaryColor),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(u.displayName, style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black), overflow: TextOverflow.ellipsis),
                      Text(u.email.isEmpty ? u.phoneNumber : u.email, style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(u.role == 'customer' ? 'CUSTOMER' : u.role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BoostDriveTheme.primaryColor)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _getStatusColor(u.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(u.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(u.status))),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(DateFormat('MMM d, yyyy').format(u.createdAt), style: TextStyle(fontFamily: 'Manrope', fontSize: 13, color: Colors.black54)),
          ),
          Expanded(
            flex: 2,
            child: _buildActionButtons(u),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(UserProfile u) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _viewUserDetails(u),
          icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.black54),
          tooltip: 'Quick View',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () => _toggleSuspend(u),
          icon: Icon(
            u.status == 'suspended' || u.status == 'banned' ? Icons.settings_backup_restore_rounded : Icons.block_flipped,
            size: 18,
            color: u.status == 'suspended' || u.status == 'banned' ? Colors.green : Colors.red,
          ),
          tooltip: u.status == 'suspended' || u.status == 'banned' ? 'Reactivate Suspension' : 'Suspend Account',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () => _viewAuditLogs(u),
          icon: const Icon(Icons.history, size: 18, color: BoostDriveTheme.textDim),
          tooltip: 'Security Audit Logs',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () => _viewTransactionHistory(u),
          icon: const Icon(Icons.receipt_long_outlined, size: 18, color: Color(0xFF000000)),
          tooltip: 'Transaction History',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () => _showMoreActions(u),
          icon: const Icon(Icons.more_horiz, size: 18, color: Colors.black54),
          tooltip: 'More Actions',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.green.shade700;
      case 'suspended':
      case 'banned': return Colors.red.shade700;
      case 'frozen': return Colors.orange.shade800;
      default: return BoostDriveTheme.primaryColor.withValues(alpha: 0.1);
    }
  }

  void _viewUserDetails(UserProfile u) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 700,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(u),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (u.role.contains('provider') || u.role.contains('mechanic') || u.role.contains('towing')) ...[
                        _buildSectionTitle('BUSINESSS IDENTITY'),
                        Wrap(
                          spacing: 40,
                          runSpacing: 24,
                          children: [
                            _buildDetailItem('Trading Name', u.tradingName?.isNotEmpty == true ? u.tradingName! : u.displayName),
                            _buildDetailItem('Registered Name', u.registeredBusinessName ?? 'N/A'),
                            _buildDetailItem('Business Type', u.businessType?.toUpperCase() ?? 'N/A'),
                            _buildDetailItem('Years in Operation', u.yearsInOperation?.toString() ?? 'N/A'),
                            _buildDetailItem('Registration #', u.registrationNumber ?? 'N/A'),
                            _buildDetailItem('VAT #', u.taxVatNumber ?? 'N/A'),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                      _buildSectionTitle('CONTACT & LOCATION'),
                      Wrap(
                        spacing: 40,
                        runSpacing: 24,
                        children: [
                          _buildDetailItem('Business Phone', u.businessContactNumber?.isNotEmpty == true ? u.businessContactNumber! : u.phoneNumber),
                          _buildDetailItem('Email Address', u.email.isEmpty ? 'N/A' : u.email),
                          _buildDetailItem('Workshop Address', u.workshopAddress ?? 'N/A'),
                          _buildDetailItem('Service Area', u.serviceAreaDescription ?? 'N/A'),
                          _buildDetailItem('Preferred Comm.', u.preferredCommunication?.replaceAll('_', ' ').toUpperCase() ?? 'APP CHAT'),
                          _buildDetailItem('Website', u.websiteUrl ?? 'N/A', isLink: true),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (u.role.contains('provider')) ...[
                        _buildSectionTitle('EXPERTISE & SERVICES'),
                        _buildChipSection('Primary Category', [u.primaryServiceCategory ?? 'Other'], color: BoostDriveTheme.primaryColor),
                        const SizedBox(height: 16),
                        _buildChipSection('Service Specialties', u.serviceTags, color: BoostDriveTheme.primaryColor),
                        const SizedBox(height: 16),
                        _buildChipSection('Brand Expertise', u.brandExpertise, color: Colors.indigo),
                        const SizedBox(height: 16),
                        _buildChipSection('Towing Capabilities', u.towingCapabilities, color: Colors.orange),
                        const SizedBox(height: 32),
                      ],
                      if (u.role.contains('provider') || u.role.contains('mechanic') || u.role.contains('towing')) ...[
                        _buildSectionTitle('OPERATIONS & FINANCE'),
                        Wrap(
                          spacing: 40,
                          runSpacing: 24,
                          children: [
                            _buildDetailItem('Working Hours', u.workingHours ?? 'N/A'),
                            _buildDetailItem('24/7 Service', (u.businessHours24_7 ?? false) ? 'YES' : 'NO'),
                            _buildDetailItem('Service Radius', u.serviceRadiusKm != null ? '${u.serviceRadiusKm} km' : 'N/A'),
                            _buildDetailItem('Labor Rate', u.standardLaborRate != null ? 'N\$${u.standardLaborRate}/hr' : 'N/A'),
                            _buildDetailItem('Team Size', u.teamSize?.toString() ?? 'N/A'),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                      if ((u.businessBio != null && u.businessBio!.isNotEmpty) || (u.storeBiography != null && u.storeBiography!.isNotEmpty)) ...[
                        _buildSectionTitle('BUSINESS BIO'),
                        Text(
                          (u.businessBio?.isNotEmpty == true) ? u.businessBio! : u.storeBiography!,
                          style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: Colors.black87, height: 1.5),
                        ),
                        const SizedBox(height: 32),
                      ],
                      _buildSectionTitle('SYSTEM DETAILS'),
                      _buildDetailItem('Unique User ID (UID)', u.uid),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFFFF),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      ),
                      child: Text('Close', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildDialogHeader(UserProfile u) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFFFFFFFF),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
            backgroundImage: u.profileImg.isNotEmpty ? NetworkImage(u.profileImg) : null,
            child: u.profileImg.isEmpty ? Text(u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: BoostDriveTheme.primaryColor)) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.fullName, style: TextStyle(fontFamily: 'Manrope', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildBadge(u.role.toUpperCase(), BoostDriveTheme.primaryColor),
                    const SizedBox(width: 8),
                    _buildBadge(u.verificationStatus.toUpperCase(), u.verificationStatus == 'approved' ? Colors.green : Colors.orange),
                    const SizedBox(width: 8),
                    _buildBadge(u.status.toUpperCase(), _getStatusColor(u.status)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(title, style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black38, letterSpacing: 1.2)));
  }

  Widget _buildDetailItem(String label, String value, {bool isLink = false}) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Manrope', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black45)),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'N/A' : value,
            style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w700, color: isLink ? BoostDriveTheme.primaryColor : Colors.black87, decoration: isLink ? TextDecoration.underline : null),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildChipSection(String label, List<String> tags, {required Color color}) {
    if (tags.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Manrope', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black45)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: tags.map((t) => _buildBadge(UserProfile.getSpecializationLabel(t), color)).toList()),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
    );
  }

  Future<void> _toggleSuspend(UserProfile u) async {
    final isSuspended = u.status == 'suspended' || u.status == 'banned';
    final newStatus = isSuspended ? 'active' : 'suspended';
    final action = isSuspended ? 'reactivate' : 'suspend';
    
    String? reason;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('${isSuspended ? "REACTIVATE" : "SUSPEND"} ACCOUNT', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to $action ${u.fullName}?',
                style: TextStyle(fontFamily: 'Manrope', fontSize: 14),
              ),
              if (!isSuspended) ...[
                const SizedBox(height: 20),
                Text(
                  'REASON FOR SUSPENSION',
                  style: TextStyle(fontFamily: 'Manrope', fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black45, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'e.g. Non-compliance with safety standards',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0x22FF6600)),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                if (!isSuspended && controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a mandatory reason for suspension'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                reason = controller.text.trim();
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuspended ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isSuspended ? 'REACTIVATE' : 'SUSPEND', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final admin = ref.read(currentUserProvider);
      if (admin == null) return;
      try {
        await ref.read(userServiceProvider).updateUserStatus(
          uid: u.uid, 
          status: newStatus, 
          adminUid: admin.id, 
          reason: reason,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account ${isSuspended ? "reactivated" : "suspended"} successfully'),
              backgroundColor: isSuspended ? Colors.green : Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showMoreActions(UserProfile u) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(height: 4, width: 40, decoration: BoxDecoration(color: Color(0x22FF6600), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.email_outlined, color: Colors.black87),
            title: Text(
              'Send Message',
              style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
              _showMessageDialog(u);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showMessageDialog(UserProfile u) {
    final controller = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.email_outlined, color: BoostDriveTheme.primaryColor),
              const SizedBox(width: 12),
              Text('Message ${u.fullName}', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Send a direct message to this provider.', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: Colors.black87)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0x22FF6600)),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isSending ? null : () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                setDialogState(() => isSending = true);

                try {
                  final admin = ref.read(currentUserProvider);
                  if (admin == null) throw Exception('Admin not authenticated');

                  final messageService = ref.read(messageServiceProvider);
                  final conversationId = await messageService.getOrCreateDirectConversation(
                    userId: admin.id,
                    providerId: u.uid,
                  );

                  await messageService.sendMessage(
                    conversationId: conversationId,
                    senderId: admin.id,
                    content: text,
                  );

                  // Log audit action
                  await ref.read(userServiceProvider).logAuditAction(
                    adminId: admin.id,
                    targetId: u.uid,
                    actionType: 'ADMIN_MESSAGE_SENT',
                    notes: 'Admin sent a direct message to ${u.fullName}',
                    metadata: {'message_length': text.length},
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Message sent to ${u.fullName}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    setDialogState(() => isSending = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BoostDriveTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: isSending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('SEND MESSAGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFreeze(UserProfile u) async {
    final newStatus = u.status == 'frozen' ? 'active' : 'frozen';
    final action = u.status == 'frozen' ? 'unfreeze' : 'freeze';
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;
    try {
      await ref.read(userServiceProvider).updateUserStatus(
        uid: u.uid, 
        status: newStatus, 
        adminUid: admin.id, 
        reason: 'Manually $action by admin',
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User ${u.fullName} $action successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _viewAuditLogs(UserProfile u) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor)),
    );

    try {
      final logs = await ref.read(userServiceProvider).getAuditLogs(u.uid);
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showAuditLogsDialog(u, logs);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch logs: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showAuditLogsDialog(UserProfile u, List<Map<String, dynamic>> logs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Security & Audit Trail', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
                Text('Compliance record for ${u.displayName}', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: Colors.black54)),
              ],
            ),
            const Spacer(),
            CircleAvatar(
              backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.security, color: BoostDriveTheme.primaryColor, size: 20),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: logs.isEmpty 
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_toggle_off, size: 48, color: Color(0x22FF6600)),
                    SizedBox(height: 16),
                    Text('No compliance records found.', style: TextStyle(color: Colors.black38)),
                  ],
                ),
              )
            : Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final date = log['created_at'] != null ? DateTime.parse(log['created_at']) : DateTime.now();
                    final isSystem = (log['action_type'] as String).startsWith('SYSTEM');
                    final metadata = log['metadata'] as Map<String, dynamic>? ?? {};
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSystem ? const Color(0xFFF8F9FA) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isSystem ? BoostDriveTheme.primaryColor.withValues(alpha: 0.1) : BoostDriveTheme.primaryColor).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log['action_type']?.toString().replaceAll('_', ' ') ?? 'ACTION',
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w900, 
                                    color: isSystem ? Colors.black54 : BoostDriveTheme.primaryColor,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, HH:mm:ss').format(date),
                                style: const TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            log['notes'] ?? 'Administrative change recorded.',
                            style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                          ),
                          
                          // Granular Field-Level Changes
                          if (metadata.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Divider(height: 1, color: Color(0x22FF6600)),
                            const SizedBox(height: 8),
                            ...metadata.entries.map((e) {
                              final val = e.value;
                              if (val is Map && val.containsKey('before')) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.arrow_right, size: 16, color: BoostDriveTheme.textDim),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(fontFamily: 'Manrope', fontSize: 12, color: Colors.black87),
                                            children: [
                                              TextSpan(text: '${e.key.replaceAll('_', ' ').toUpperCase()}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
                                              TextSpan(text: '"${val['before'] ?? 'N/A'}"', style: const TextStyle(color: Colors.redAccent, decoration: TextDecoration.lineThrough)),
                                              const TextSpan(text: ' → '),
                                              TextSpan(text: '"${val['after'] ?? 'N/A'}"', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox();
                            }).toList(),
                          ],

                          const SizedBox(height: 12),
                          // Security Context
                          Row(
                            children: [
                              const Icon(Icons.fingerprint, size: 12, color: BoostDriveTheme.textDim),
                              const SizedBox(width: 4),
                              Text(
                                log['admin_id'] != null 
                                  ? 'Staff: ${log['admin_id'].toString().substring(0, 8).toUpperCase()}' 
                                  : 'System Trigger',
                                style: const TextStyle(fontSize: 10, color: BoostDriveTheme.textDim, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              if (log['ip_address'] != null) ...[
                                const Icon(Icons.lan_outlined, size: 12, color: Colors.black38),
                                const SizedBox(width: 4),
                                Text(log['ip_address'], style: const TextStyle(fontSize: 10, color: Colors.black38)),
                                const SizedBox(width: 8),
                              ],
                              if (log['device_info'] != null) ...[
                                Icon(log['device_info'].contains('Web') ? Icons.laptop : Icons.smartphone, size: 12, color: Colors.black38),
                                const SizedBox(width: 4),
                                Text(log['device_info'], style: const TextStyle(fontSize: 10, color: Colors.black38)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('DISMISS', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAdminModal() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isProcessing = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF000000), // Dark background for premium look
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SECURE INVITE', style: TextStyle(fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w900, color: BoostDriveTheme.primaryColor, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text('Create Admin Account', style: TextStyle(fontFamily: 'Manrope', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFieldLabel('FULL NAME'),
                TextField(
                  controller: nameController,
                  cursorColor: Colors.black,
                  decoration: _adminInputDecoration('e.g. Karlos Brian'),
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('OFFICIAL EMAIL'),
                TextField(
                  controller: emailController,
                  cursorColor: Colors.black,
                  decoration: _adminInputDecoration('e.g. karlos@boostdrive.na'),
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('TEMPORARY PASSWORD'),
                TextField(
                  controller: passwordController,
                  cursorColor: Colors.black,
                  decoration: _adminInputDecoration('Choose a strong password').copyWith(
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black45,
                          size: 20,
                        ),
                        onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                        splashRadius: 20,
                      ),
                    ),
                  ),
                  obscureText: obscurePassword,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : () async {
                      if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
                        return;
                      }
                      
                      final confirm = await _showSecurityConfirmation();
                      if (confirm == true) {
                        setModalState(() => isProcessing = true);
                        try {
                          final currentAdmin = ref.read(currentUserProvider);
                          final exists = await ref.read(userServiceProvider).checkEmailExists(emailController.text);
                          if (exists) {
                            throw 'An account with this email already exists.';
                          }
                          
                          // 1. Initialize Temp Client for Session-less SignUp
                          bool isDotEnvInitialized = false;
                          try { await dotenv.load(fileName: ".env"); isDotEnvInitialized = true; } catch (_) {}
                          
                          final url = isDotEnvInitialized ? (dotenv.maybeGet('SUPABASE_URL') ?? WebUtils.getEnv('SUPABASE_URL')) : WebUtils.getEnv('SUPABASE_URL');
                          final key = isDotEnvInitialized ? (dotenv.maybeGet('SUPABASE_ANON_KEY') ?? WebUtils.getEnv('SUPABASE_ANON_KEY')) : WebUtils.getEnv('SUPABASE_ANON_KEY');
                          
                          if (url.isEmpty || key.isEmpty) throw 'Configuration error: Missing Supabase URL/Key';
                          
                          final tempClient = SupabaseClient(url, key, authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit));

                          // 2. Trigger Native Supabase SignUp (dispatches automated email)
                          final response = await tempClient.auth.signUp(
                            email: emailController.text.trim(),
                            password: passwordController.text,
                            data: {
                              'full_name': nameController.text.trim(),
                              'role': 'admin',
                            },
                          );
                          
                          if (response.user != null) {
                            Navigator.pop(context); // Close Form Modal
                            _showOtpVerificationModal(
                              tempClient: tempClient,
                              fullName: nameController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text,
                              newUserId: response.user!.id,
                            );
                          } else {
                            throw 'Failed to initialize account invitation.';
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        } finally {
                          setModalState(() => isProcessing = false);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BoostDriveTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isProcessing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('GENERATE ACCOUNT', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOtpVerificationModal({
    required SupabaseClient tempClient,
    required String fullName,
    required String email,
    required String password,
    required String newUserId,
  }) {
    final otpController = TextEditingController();
    int resendCooldown = 0;
    bool isResending = false;
    bool isProcessing = false;
    
    void startResendTimer(void Function(void Function()) setModalState) {
      setModalState(() => resendCooldown = 60);
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!context.mounted) {
          timer.cancel();
          return;
        }
        setModalState(() {
          if (resendCooldown > 0) {
            resendCooldown--;
          } else {
            timer.cancel();
          }
        });
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read_outlined, color: BoostDriveTheme.primaryColor, size: 48),
                const SizedBox(height: 24),
                const Text('Verify Email', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 12),
                Text(
                  'A verification code has been sent to $email using your standard email configuration. Please ask the new admin for the code.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                _buildFieldLabel('VERIFICATION CODE'),
                TextField(
                  controller: otpController,
                  cursorColor: Colors.black,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.black),
                  decoration: _adminInputDecoration('000000').copyWith(counterText: ""),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : () async {
                      if (otpController.text.length < 6) return;
                      
                      setModalState(() => isProcessing = true);
                      try {
                        // 1. Verify OTP using native Supabase Auth
                        await tempClient.auth.verifyOTP(
                          type: OtpType.signup,
                          email: email,
                          token: otpController.text.trim(),
                        );

                        // 2. Finalize & Elevate Account
                        final currentAdmin = ref.read(currentUserProvider);
                        final result = await ref.read(userServiceProvider).finalizeAdminAccount(
                          targetUid: newUserId,
                          adminUid: currentAdmin!.id,
                          email: email,
                          fullName: fullName,
                        );
                        
                        if (result['success'] == true) {
                          Navigator.pop(context); // Close OTP Modal
                          _showInviteSuccessModal(fullName, email, password);
                        } else {
                          throw result['error'] ?? 'Failed to finalize account';
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      } finally {
                        setModalState(() => isProcessing = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BoostDriveTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isProcessing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('VERIFY & FINALIZE', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: (resendCooldown > 0 || isResending) ? null : () async {
                    setModalState(() => isResending = true);
                    try {
                      await tempClient.auth.resend(
                        type: OtpType.signup,
                        email: email,
                      );
                      startResendTimer(setModalState);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification code resent successfully!'), backgroundColor: Colors.green));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to resend: $e'), backgroundColor: Colors.red));
                    } finally {
                      setModalState(() => isResending = false);
                    }
                  },
                  child: Text(
                    resendCooldown > 0 
                      ? 'RESEND CODE IN ${resendCooldown}s' 
                      : (isResending ? 'SENDING...' : 'RESEND CODE'),
                    style: TextStyle(
                      color: resendCooldown > 0 ? Color(0x22FF6600) : BoostDriveTheme.primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showSecurityConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Text('Security Confirmation', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
        content: const Text(
          'Are you sure? This user will have full access to freeze accounts, view financials, and manage all providers across the Namibian automotive ecosystem.',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white, elevation: 0),
            child: const Text('CONFIRM ELEVATION', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showInviteSuccessModal(String name, String email, String password) {
    final inviteText = """
Hello $name,

You have been invited as an Administrator for BoostDrive.

Dashboard URL: https://admin.boostdrive.na
Email: $email
Temporary Password: $password

Please change your password immediately after your first login.
""";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 24),
              const Text('Account Created!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 12),
              const Text('The admin account is ready. Copy the credentials below and share them securely.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12)),
                child: Text(inviteText, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.black87)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation copied to clipboard!')));
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                      label: const Text('COPY INVITE', style: TextStyle(color: Colors.white70)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0x22FF6600)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0x22FF6600),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('DISMISS', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.5)));
  }

  InputDecoration _adminInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0x22FF6600)),
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFFCCAA))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFFCCAA))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BoostDriveTheme.primaryColor)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
  // ─── NOTIFICATION HUB ───────────────────────────────────────────────────────

  void _showNotificationModal({String preselectedGroup = 'all_users'}) {
    showDialog(
      context: context,
      builder: (context) => NotificationDialog(initialGroup: preselectedGroup),
    );
  }

  Future<void> _viewTransactionHistory(UserProfile u) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor)),
    );

    try {
      final txns = await ref.read(paymentServiceProvider).getTransactionsFuture(u.uid);
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showTransactionHistoryDialog(u, txns);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch transactions: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showTransactionHistoryDialog(UserProfile u, List<Map<String, dynamic>> txns) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transaction History', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
                Text('Billing audit for ${u.displayName}', style: const TextStyle(fontFamily: 'Manrope', fontSize: 12, color: Colors.black54)),
              ],
            ),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20)),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 500,
          child: txns.isEmpty 
            ? const Center(child: Text('No transactions found for this account.', style: TextStyle(color: Colors.black38)))
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Expanded(child: Text('ID/DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54))),
                        Expanded(child: Text('METHOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54))),
                        Expanded(child: Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54))),
                        Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: txns.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final txn = txns[index];
                        final isCompleted = txn['status']?.toString().toLowerCase() == 'completed';
                        final date = txn['created_at'] != null ? DateTime.parse(txn['created_at']) : DateTime.now();
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text('#${txn['id']?.toString().substring(0, 10).toUpperCase()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                          subtitle: Text(DateFormat('MMM d, yyyy HH:mm').format(date), style: const TextStyle(fontSize: 11, color: Colors.black38)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Payment System', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                  Text(txn['payment_method']?.toString().toUpperCase() ?? 'N/A', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BoostDriveTheme.textDim)),
                                ],
                              ),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: 80,
                                child: Text('N\$${txn['amount']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87), textAlign: TextAlign.right),
                              ),
                              const SizedBox(width: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: (isCompleted ? Colors.green : Colors.orange).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(txn['status']?.toString().toUpperCase() ?? 'UNKNOWN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green : Colors.orange)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

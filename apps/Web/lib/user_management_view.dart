import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_states.dart';

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
      if (g == AdminUserGroup.provider) _roleFilter = 'all_providers';
      if (g == AdminUserGroup.customerSeller) _roleFilter = 'all_member';
      if (g == AdminUserGroup.admin) _roleFilter = 'all_admin';
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
                  final matchesSearch = p.fullName.toLowerCase().contains(q) ||
                      p.email.toLowerCase().contains(q) ||
                      p.phoneNumber.contains(_searchQuery);

                  if (!matchesSearch) return false;

                  if (_statusFilter != 'all' && p.status.toLowerCase() != _statusFilter) {
                    return false;
                  }

                  final role = p.role.toLowerCase();
                  switch (_roleFilter) {
                    case 'all':
                    case 'all_providers':
                    case 'all_member':
                    case 'all_admin':
                      return true;
                    default:
                      return role == _roleFilter;
                  }
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
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800, 
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle, 
                    style: GoogleFonts.manrope(
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
            color: const Color(0xFFF2F4F7),
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
        const SizedBox(width: 16),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
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
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _roleFilter,
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
        DropdownMenuItem(value: 'all_providers', child: Text('All Providers')),
        DropdownMenuItem(value: 'service_provider', child: Text('Service Provider')),
        DropdownMenuItem(value: 'mechanic', child: Text('Mechanic')),
        DropdownMenuItem(value: 'towing', child: Text('Towing')),
        DropdownMenuItem(value: 'logistics', child: Text('Logistics')),
        DropdownMenuItem(value: 'rental', child: Text('Rental')),
      ];
    }
    if (selectedGroup == AdminUserGroup.admin) {
      return const [
        DropdownMenuItem(value: 'all_admin', child: Text('All Admins')),
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
        DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
      ];
    }
    return const [
      DropdownMenuItem(value: 'all_member', child: Text('All Customers & Sellers')),
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
          color: const Color(0xFFF2F4F7),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              _headerCell('USER', flex: 4),
              _headerCell('ROLE', flex: 2),
              _headerCell('STATUS', flex: 2),
              _headerCell('JOINED', flex: 2),
              _headerCell('ACTIONS', flex: 1, align: TextAlign.end),
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
        style: GoogleFonts.manrope(
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
                          (u.fullName.isNotEmpty ? u.fullName[0] : '?').toUpperCase(),
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
                      Text(u.fullName, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black), overflow: TextOverflow.ellipsis),
                      Text(u.email.isEmpty ? u.phoneNumber : u.email, style: GoogleFonts.manrope(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis),
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
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(u.role == 'customer' ? 'CUSTOMER' : u.role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
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
            flex: 2,
            child: Text(DateFormat('MMM d, yyyy').format(u.createdAt), style: GoogleFonts.manrope(fontSize: 13, color: Colors.black54)),
          ),
          Expanded(
            flex: 1,
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
          icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.black54),
          tooltip: 'Quick View',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _toggleSuspend(u),
          icon: Icon(
            u.status == 'suspended' || u.status == 'banned' ? Icons.settings_backup_restore_rounded : Icons.block_flipped,
            size: 20,
            color: u.status == 'suspended' || u.status == 'banned' ? Colors.green : Colors.red,
          ),
          tooltip: u.status == 'suspended' || u.status == 'banned' ? 'Reactivate (Undo) Suspension' : 'Suspend Account',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _showMoreActions(u),
          icon: const Icon(Icons.more_horiz, size: 20, color: Colors.black54),
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
      default: return Colors.grey.shade700;
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
                            _buildDetailItem('Trading Name', u.tradingName?.isNotEmpty == true ? u.tradingName! : u.fullName),
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
                        _buildChipSection('Primary Category', [u.primaryServiceCategory ?? 'Other'], color: Colors.blue),
                        const SizedBox(height: 16),
                        _buildChipSection('Service Specialties', u.serviceTags, color: BoostDriveTheme.primaryColor),
                        const SizedBox(height: 16),
                        _buildChipSection('Brand Expertise', u.brandExpertise, color: Colors.indigo),
                        const SizedBox(height: 16),
                        _buildChipSection('Towing Capabilities', u.towingCapabilities, color: Colors.orange),
                        const SizedBox(height: 32),
                      ],
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
                          _buildDetailItem('Loyalty Points', u.loyaltyPoints.toString()),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if ((u.businessBio != null && u.businessBio!.isNotEmpty) || (u.storeBiography != null && u.storeBiography!.isNotEmpty)) ...[
                        _buildSectionTitle('BUSINESS BIO'),
                        Text(
                          (u.businessBio?.isNotEmpty == true) ? u.businessBio! : u.storeBiography!,
                          style: GoogleFonts.manrope(fontSize: 14, color: Colors.black87, height: 1.5),
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
                        backgroundColor: const Color(0xFFF2F4F7),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      ),
                      child: Text('Close', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
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
      color: const Color(0xFFF9FAFB),
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
                Text(u.fullName, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildBadge(u.role.toUpperCase(), Colors.blue),
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
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(title, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black38, letterSpacing: 1.2)));
  }

  Widget _buildDetailItem(String label, String value, {bool isLink = false}) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black45)),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'N/A' : value,
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: isLink ? Colors.blue : Colors.black87, decoration: isLink ? TextDecoration.underline : null),
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
        Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black45)),
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
          title: Text('${isSuspended ? "REACTIVATE" : "SUSPEND"} ACCOUNT', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to $action ${u.fullName}?',
                style: GoogleFonts.manrope(fontSize: 14),
              ),
              if (!isSuspended) ...[
                const SizedBox(height: 20),
                Text(
                  'REASON FOR SUSPENSION',
                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black45, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'e.g. Non-compliance with safety standards',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.black26),
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
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                if (!isSuspended && controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a reason for suspension')),
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
              content: Text('User ${u.fullName} ${isSuspended ? "reactivated" : "suspended"} successfully'),
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
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.ac_unit, color: Colors.orange),
            title: Text(u.status == 'frozen' ? 'Unfreeze Account' : 'Freeze Account'),
            onTap: () {
              Navigator.pop(context);
              _toggleFreeze(u);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('View Audit Logs'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
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
}

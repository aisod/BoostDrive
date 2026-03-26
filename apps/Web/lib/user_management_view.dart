import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:intl/intl.dart';

class UserManagementView extends ConsumerStatefulWidget {
  const UserManagementView({super.key});

  @override
  ConsumerState<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends ConsumerState<UserManagementView> {
  _UserGroup? _selectedGroup;
  String _searchQuery = '';
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  bool _isProviderRole(String role) {
    final r = role.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), ' ');
    if (r.isEmpty) return false;
    if (r == 'provider') return true;
    return r.contains('service provider') ||
        r.contains('service pro') ||
        r.contains('mechanic') ||
        r.contains('towing') ||
        r.contains('logistics') ||
        r.contains('rental') ||
        r == 'service_provider' ||
        r == 'service_pro';
  }

  bool _matchesGroup(UserProfile p) {
    final role = p.role.trim().toLowerCase();
    switch (_selectedGroup) {
      case _UserGroup.provider:
        return _isProviderRole(role);
      case _UserGroup.customerSeller:
        return role == 'customer' || role == 'seller';
      case _UserGroup.admin:
        return p.isAdmin == true || role == 'admin' || role == 'super_admin';
      case null:
        return true;
    }
  }

  void _enterGroup(_UserGroup g) {
    setState(() {
      _selectedGroup = g;
      _searchQuery = '';
      _searchController.text = '';
      _statusFilter = 'all';
      _roleFilter = 'all';
      if (g == _UserGroup.provider) _roleFilter = 'all_providers';
      if (g == _UserGroup.customerSeller) _roleFilter = 'all_member';
      if (g == _UserGroup.admin) _roleFilter = 'all_admin';
    });
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(allProfilesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'User Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            if (_selectedGroup != null) _buildFilters(),
          ],
        ),
        const SizedBox(height: 24),
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
                if (_selectedGroup == null) {
                  return _buildGroupCards(profiles);
                }

                final filtered = profiles.where((p) {
                  if (!_matchesGroup(p)) return false;

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

                return Column(
                  children: [
                    _buildGroupHeader(),
                    const Divider(height: 1),
                    Expanded(child: _buildUserTable(filtered)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading users: $err')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupHeader() {
    String title = 'Users';
    if (_selectedGroup == _UserGroup.provider) title = 'Providers';
    if (_selectedGroup == _UserGroup.customerSeller) title = 'Customers & Sellers';
    if (_selectedGroup == _UserGroup.admin) title = 'Admins';

    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => setState(() => _selectedGroup = null),
            icon: const Icon(Icons.arrow_back, size: 18),
          ),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            '${_statusFilter.toUpperCase()} • ${_roleFilter.replaceAll('_', ' ').toUpperCase()}',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
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
            title: 'Providers',
            subtitle: '$providerCount total',
            icon: Icons.build_outlined,
            onTap: () => _enterGroup(_UserGroup.provider),
          ),
          _groupCard(
            title: 'Customers & Sellers',
            subtitle: '$memberCount total',
            icon: Icons.people_outline,
            onTap: () => _enterGroup(_UserGroup.customerSeller),
          ),
          _groupCard(
            title: 'Admins',
            subtitle: '$adminCount total',
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => _enterGroup(_UserGroup.admin),
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        // Search
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
        // Status Filter
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
                DropdownMenuItem(value: 'banned', child: Text('Banned')),
                DropdownMenuItem(value: 'frozen', child: Text('Frozen')),
              ],
              onChanged: (v) => setState(() => _statusFilter = v!),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Role Filter
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
              items: _roleItemsForGroup(),
              onChanged: (v) => setState(() => _roleFilter = v!),
            ),
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _roleItemsForGroup() {
    if (_selectedGroup == _UserGroup.provider) {
      return const [
        DropdownMenuItem(value: 'all_providers', child: Text('All Providers')),
        DropdownMenuItem(value: 'provider', child: Text('Provider')),
        DropdownMenuItem(value: 'service_provider', child: Text('Service Provider')),
        DropdownMenuItem(value: 'service_pro', child: Text('Service Pro')),
        DropdownMenuItem(value: 'mechanic', child: Text('Mechanic')),
        DropdownMenuItem(value: 'towing', child: Text('Towing')),
        DropdownMenuItem(value: 'logistics', child: Text('Logistics')),
        DropdownMenuItem(value: 'rental', child: Text('Rental')),
      ];
    }
    if (_selectedGroup == _UserGroup.admin) {
      return const [
        DropdownMenuItem(value: 'all_admin', child: Text('All Admins')),
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
        DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
      ];
    }
    // Customer/Seller
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

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        dataRowMinHeight: 65,
        dataRowMaxHeight: 75,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F2F5)),
        horizontalMargin: 24,
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('USER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5, color: Colors.black87))),
          DataColumn(label: Text('ROLE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5, color: Colors.black87))),
          DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5, color: Colors.black87))),
          DataColumn(label: Text('JOINED', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5, color: Colors.black87))),
          DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5, color: Colors.black87))),
        ],
        rows: users.map((u) => _buildUserRow(u)).toList(),
      ),
    );
  }

  DataRow _buildUserRow(UserProfile u) {
    return DataRow(
      cells: [
        // User Info
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: u.profileImg.isNotEmpty ? NetworkImage(u.profileImg) : null,
                  child: u.profileImg.isEmpty
                      ? Text(
                          (u.fullName.isNotEmpty ? u.fullName[0] : '?').toUpperCase(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BoostDriveTheme.primaryColor),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                    Text(u.email.isEmpty ? u.phoneNumber : u.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Role
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(u.role == 'customer' ? 'CUSTOMER' : u.role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ),
        // Status
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(u.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(u.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(u.status))),
          ),
        ),
        // Joined Date
        DataCell(Text(DateFormat('MMM d, yyyy').format(u.createdAt), style: const TextStyle(fontSize: 12, color: Colors.black54))),
        // Actions
        DataCell(
           Row(
             children: [
               IconButton(
                 icon: Icon(Icons.remove_red_eye_outlined, size: 20, color: Colors.blueGrey.shade600),
                 onPressed: () => _viewUserDetails(u),
                 tooltip: 'View Profile',
                 splashRadius: 20,
               ),
               IconButton(
                 icon: Icon(u.status == 'banned' ? Icons.lock_open : Icons.block, size: 20, color: u.status == 'banned' ? Colors.green.shade600 : Colors.red.shade600),
                 onPressed: () => _toggleBan(u),
                 tooltip: u.status == 'banned' ? 'Unban User' : 'Ban User',
                 splashRadius: 20,
               ),
               IconButton(
                 icon: Icon(Icons.more_vert, size: 20, color: Colors.blueGrey.shade600),
                 onPressed: () => _showMoreActions(u),
                 splashRadius: 20,
               ),
             ],
           ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.green.shade700;
      case 'banned': return Colors.red.shade700;
      case 'frozen': return Colors.orange.shade800;
      default: return Colors.grey.shade700;
    }
  }

  void _viewUserDetails(UserProfile u) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${u.fullName}\'s Profile Summarized'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UID: ${u.uid}'),
            Text('Email: ${u.email}'),
            Text('Phone: ${u.phoneNumber}'),
            Text('Loyalty Points: ${u.loyaltyPoints}'),
            Text('Verification (Provider): ${u.verificationStatus}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _toggleBan(UserProfile u) async {
    final newStatus = u.status == 'banned' ? 'active' : 'banned';
    final action = u.status == 'banned' ? 'unban' : 'ban';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.toUpperCase()} User?'),
        content: Text('Are you sure you want to $action ${u.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action.toUpperCase(), style: TextStyle(color: u.status == 'banned' ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final admin = ref.read(currentUserProvider);
      if (admin == null) return;

      try {
        await ref.read(userServiceProvider).updateUserStatus(
          uid: u.uid,
          status: newStatus,
          adminUid: admin.id,
          notes: 'Manually $action by admin',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User ${u.fullName} $action successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
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
              // Future: Show specific audit logs
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
        notes: 'Manually $action by admin',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User ${u.fullName} $action successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

enum _UserGroup { provider, customerSeller, admin }

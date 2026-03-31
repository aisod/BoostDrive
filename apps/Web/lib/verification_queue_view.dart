import 'package:flutter/material.dart'; // summary-fix-touch
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:url_launcher/url_launcher.dart';
// If document_viewer or similar is needed for PDF, we might need a package, but for now we'll build a stub
// or use simple Image networks if they are images, or a url_launcher to open PDFs.

class VerificationQueueView extends ConsumerStatefulWidget {
  const VerificationQueueView({super.key});

  @override
  ConsumerState<VerificationQueueView> createState() => _VerificationQueueViewState();
}

class _VerificationQueueViewState extends ConsumerState<VerificationQueueView> {
  UserProfile? _selectedProvider;
  bool _isLoading = false;
  Map<String, String> _documentStatuses = {}; // document_type -> status
  Map<String, String> _rejectionReasons = {}; // document_type -> reason

  // Search & filter state
  String _searchQuery = '';
  String? _selectedRoleFilter; // null = All
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _roleFilters = ['All', 'service_provider', 'mechanic', 'towing'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDocumentStatuses(String providerId) async {
    final docs = await ref.read(userServiceProvider).getProviderDocuments(providerId);
    
    if (mounted) {
      setState(() {
        _documentStatuses = {};
        _rejectionReasons = {};
        
        for (final doc in docs) {
          // Robust column access (handle potential case differences)
          final type = (doc['document_type'] ?? doc['Document_type'] ?? '').toString().trim();
          final status = (doc['status'] ?? doc['Status'] ?? '').toString().trim();
          final reason = (doc['rejection_reason'] ?? doc['Rejection_reason'] ?? '').toString().trim();
          
          if (type.isNotEmpty) {
            _documentStatuses[type] = status;
            _rejectionReasons[type] = reason;
          }
        }
      });
    }
  }

  void _updateDocStatus(String docType, String status, {String? reason}) async {
    if (_selectedProvider == null) return;
    final admin = ref.read(currentUserProvider);
    final adminUid = admin?.id ?? '';
    
    try {
      await ref.read(userServiceProvider).updateDocumentStatus(
        providerId: _selectedProvider!.uid,
        documentType: docType,
        status: status,
        adminUid: adminUid,
        reason: reason,
      );
      if (mounted) {
        setState(() {
          _documentStatuses[docType] = status;
          if (reason != null) _rejectionReasons[docType] = reason;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Document Status Saved: $status'), duration: const Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Update Failed'),
            content: Text('Could not save document status: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  void _showRejectionDialog(String docType, String docLabel) {
    final controller = TextEditingController(text: _rejectionReasons[docType]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject $docLabel'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g. Document is expired or blurry',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
                return;
              }
              Navigator.pop(context);
              _updateDocStatus(docType, 'rejected', reason: reason);
            },
            child: const Text('REJECT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReasonDialog(String docType, String docLabel) {
    final reason = _rejectionReasons[docType] ?? 'No reason provided';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rejection Reason: $docLabel'),
        content: Text(reason),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _undoDocStatus(String docType) async {
    if (_selectedProvider == null) return;
    try {
      await ref.read(userServiceProvider).deleteDocumentStatus(
        providerId: _selectedProvider!.uid,
        documentType: docType,
      );
      if (mounted) {
        setState(() {
          _documentStatuses.remove(docType);
          _rejectionReasons.remove(docType);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification status reset.'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }

  void _approveProvider(UserProfile provider) async {
    setState(() => _isLoading = true);
    try {
      final admin = ref.read(currentUserProvider);
      if (admin == null) throw Exception('Admin not logged in');

      await ref.read(userServiceProvider).updateVerificationStatus(
        uid: provider.uid,
        status: 'approved',
        adminUid: admin.id,
      );
      
      if (mounted) {
        // Force the provider to refresh so the user is removed from the pending list immediately
        ref.invalidate(pendingVerificationsProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${provider.fullName} Approved', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
          );
        }
        setState(() {
          _selectedProvider = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Approval Failed'),
            content: Text('Could not approve provider: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  void _rejectProvider(UserProfile provider) async {
    setState(() => _isLoading = true);
    try {
      final admin = ref.read(currentUserProvider);
      if (admin == null) throw Exception('Admin not logged in');

      await ref.read(userServiceProvider).updateVerificationStatus(
        uid: provider.uid,
        status: 'rejected',
        adminUid: admin.id,
      );
      
      if (mounted) {
        // Force the provider to refresh
        ref.invalidate(pendingVerificationsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${provider.fullName} Rejected', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
          );
        }
        setState(() {
          _selectedProvider = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Rejection Failed'),
            content: Text('Could not reject provider: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedProvider != null) {
      return _buildSplitScreenReviewer();
    }
    return _buildQueueList();
  }

  List<UserProfile> _applyFilters(List<UserProfile> all) {
    var list = List<UserProfile>.from(all);
    // Role filter
    if (_selectedRoleFilter != null && _selectedRoleFilter != 'All') {
      final filter = _selectedRoleFilter!;
      list = list.where((p) {
        final role = p.role == null ? '' : p.role!.toLowerCase();
        final category = p.primaryServiceCategory == null ? '' : p.primaryServiceCategory!.toLowerCase();
        return role == filter || category == filter;
      }).toList();
    }
    // Text search
    final q = _searchQuery.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) {
        final name = p.fullName.toLowerCase();
        final email = p.email.toLowerCase();
        final role = p.role == null ? '' : p.role!.toLowerCase();
        return name.contains(q) || email.contains(q) || role.contains(q);
      }).toList();
    }
    return list;
  }

  Widget _buildQueueList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final count = ref.watch(pendingVerificationsProvider).maybeWhen(
                  data: (pending) => pending.length,
                  orElse: () => 0,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$count Pending', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Search bar ──────────────────────────────────────────────
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search by name, email or role...',
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF98A2B3)),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF667085)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF667085)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Filter chips ────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._roleFilters.map((role) {
                final isSelected = (role == 'All' && _selectedRoleFilter == null) ||
                    role == _selectedRoleFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      role == 'All' ? 'All' : role.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF667085),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      _selectedRoleFilter = role == 'All' ? null : role;
                    }),
                    selectedColor: BoostDriveTheme.primaryColor,
                    backgroundColor: const Color(0xFFF2F4F7),
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(
                      color: isSelected ? BoostDriveTheme.primaryColor : Colors.transparent,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }),
              // Clear all filters button (only when any filter is active)
              if (_selectedRoleFilter != null || _searchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedRoleFilter = null;
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off, size: 16, color: Colors.red),
                  label: const Text('Clear Filters', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: Colors.red.withValues(alpha: 0.07),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Provider table ─────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildListHeader(),
              const Divider(height: 1),
              Consumer(
                builder: (context, ref, child) {
                  return ref.watch(pendingVerificationsProvider).when(
                    data: (pending) {
                      final filtered = _applyFilters(pending);
                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 40, color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text(
                                  pending.isEmpty ? 'No providers pending verification.' : 'No results match your search.',
                                  style: const TextStyle(color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) => _buildQueueItem(filtered[index]),
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                    error: (err, _) => Padding(padding: const EdgeInsets.all(32), child: Text('Error: $err')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFFF8F9FA),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text('SERVICE PROVIDER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))),
          Expanded(flex: 1, child: Text('JOINED DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))),
          Expanded(flex: 2, child: Text('ROLE / CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))),
          SizedBox(width: 100, child: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildQueueItem(UserProfile p) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedProvider = p;
          _documentStatuses = {};
          _rejectionReasons = {};
        });
        _loadDocumentStatuses(p.uid);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(getInitials(p.fullName), style: const TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
                        Text(p.email, style: const TextStyle(color: Colors.black54, fontSize: 13), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                p.createdAt != null ? '${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}' : 'Unknown',
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(p.role.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedProvider = p;
                      _documentStatuses = {};
                      _rejectionReasons = {};
                    });
                    _loadDocumentStatuses(p.uid);
                  },
                  child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitScreenReviewer() {
    final p = _selectedProvider!;
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            InkWell(
              onTap: () => setState(() {
                _selectedProvider = null;
                _documentStatuses = {};
                _rejectionReasons = {};
              }),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.arrow_back, size: 18, color: BoostDriveTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Back to Queue', style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text(
                      'Document Viewer',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text(
                      'Provider Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Split Screen
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Documents
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      ),
                      child: _buildDocumentViewerList(p),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Side: Provider Bio
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                                  child: Text(getInitials(p.fullName), style: const TextStyle(fontSize: 24, color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      const SizedBox(height: 4),
                                      Text(p.email, style: const TextStyle(color: Colors.black54)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: p.verificationStatus.toLowerCase() == 'approved' 
                                            ? Colors.green.withValues(alpha: 0.1) 
                                            : p.verificationStatus.toLowerCase() == 'rejected' 
                                              ? Colors.red.withValues(alpha: 0.1) 
                                              : Colors.orange.withValues(alpha: 0.1), 
                                          borderRadius: BorderRadius.circular(6)
                                        ),
                                        child: Text(
                                          p.verificationStatus.toUpperCase() == 'PENDING' ? 'PENDING VERIFICATION' : p.verificationStatus.toUpperCase(), 
                                          style: TextStyle(
                                            color: p.verificationStatus.toLowerCase() == 'approved' 
                                              ? Colors.green 
                                              : p.verificationStatus.toLowerCase() == 'rejected' 
                                                ? Colors.red 
                                                : Colors.orange, 
                                            fontSize: 10, 
                                            fontWeight: FontWeight.w900
                                          )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            const Text('Business Contact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 8),
                            Text(p.businessContactNumber ?? 'N/A', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                            const Divider(height: 32, color: Colors.black12),
                            const Text('Business Registration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 8),
                            const Text('Not Provided', style: TextStyle(fontSize: 16, color: Colors.black87)),
                            const Divider(height: 32, color: Colors.black12),
                            const Text('Primary Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 8),
                            Text(p.primaryServiceCategory ?? 'Auto Repair', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Action Footer - Only show if pending/unverified
            if (p.verificationStatus.toLowerCase() == 'pending' || p.verificationStatus.toLowerCase() == 'unverified')
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isLoading ? null : () => _rejectProvider(p),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      ),
                      child: const Text('Reject Application', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _approveProvider(p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Approve Provider', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (_isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.white54,
              child: Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor)),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentViewerList(UserProfile p) {
    // Slot mapping from profile_settings_page.dart
    final docTypes = [
      {'label': 'BIPA or CC1 business registration', 'index': 0},
      {'label': 'Certified copy of owner ID', 'index': 1},
      {'label': 'Municipal fitness certificate', 'index': 2},
      {'label': 'NTA trade certificate', 'index': 3},
      {'label': 'Road Carrier Permit (towing)', 'index': 4},
      {'label': 'NamRA tax certificate', 'index': 5},
      {'label': 'Social Security good standing', 'index': 6},
    ];

    final isTowing = p.role.toLowerCase() == 'towing' || (p.primaryServiceCategory ?? '').toLowerCase() == 'towing';

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: docTypes.length,
      itemBuilder: (context, i) {
        final doc = docTypes[i];
        final index = doc['index'] as int;
        final label = doc['label'] as String;
        
        // Skip Road Carrier Permit if not towing
        if (index == 4 && !isTowing) return const SizedBox.shrink();

        final hasDoc = index < p.galleryUrls.length && p.galleryUrls[index].trim().isNotEmpty;
        final url = hasDoc ? p.galleryUrls[index] : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Icon(
                  hasDoc ? Icons.description : Icons.description_outlined,
                  color: hasDoc ? BoostDriveTheme.primaryColor : Colors.black26,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text(
                        hasDoc ? 'Document uploaded' : 'Not uploaded',
                        style: TextStyle(fontSize: 12, color: hasDoc ? Colors.green : Colors.black38),
                      ),
                    ],
                  ),
                ),
                if (hasDoc) ...[
                  // Tick (Approve)
                  IconButton(
                    icon: Icon(
                      (_documentStatuses[label.trim()] ?? '').toLowerCase() == 'approved' ? Icons.check_circle : Icons.check_circle_outline,
                      color: (_documentStatuses[label.trim()] ?? '').toLowerCase() == 'approved' ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => _updateDocStatus(label.trim(), 'approved'),
                    tooltip: 'Approve Document',
                  ),
                  // X (Reject)
                  IconButton(
                    icon: Icon(
                      (_documentStatuses[label.trim()] ?? '').toLowerCase() == 'rejected' ? Icons.cancel : Icons.cancel_outlined,
                      color: (_documentStatuses[label.trim()] ?? '').toLowerCase() == 'rejected' ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => _showRejectionDialog(label.trim(), label.trim()),
                    tooltip: 'Reject Document',
                  ),
                  if ((_documentStatuses[label.trim()]?? '').isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.history, size: 20, color: Colors.blueGrey),
                      onPressed: () => _undoDocStatus(label.trim()),
                      tooltip: 'Undo/Reset Status',
                    ),
                  if ((_documentStatuses[label.trim()] ?? '').toLowerCase() == 'rejected' && (_rejectionReasons[label.trim()] ?? '').isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.comment, size: 20, color: Colors.orange),
                      onPressed: () => _showReasonDialog(label.trim(), label.trim()),
                      tooltip: 'View Rejection Reason',
                    ),
                  // View
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20, color: BoostDriveTheme.primaryColor),
                    onPressed: () => _launchURL(url!),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
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

  Widget _buildQueueList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             const Text(
              'Pending Verifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
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
        const SizedBox(height: 24),
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
              // Simulated list. In reality, we'd fetch this from Riverpod provider `pendingVerificationsProvider`
              Consumer(
                builder: (context, ref, child) {
                  return ref.watch(pendingVerificationsProvider).when(
                    data: (pending) {
                      if (pending.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Text('No providers pending.'));
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pending.length,
                        separatorBuilder: (_,__) => const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) => _buildQueueItem(pending[index]),
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
          Expanded(flex: 2, child: Text('PROVIDER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))),
          Expanded(flex: 1, child: Text('JOINED DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))),
          Expanded(flex: 2, child: Text('ROLE / CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54))),
          SizedBox(width: 100, child: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildQueueItem(UserProfile p) {
    return InkWell(
      onTap: () => setState(() => _selectedProvider = p),
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
                  onPressed: () => setState(() => _selectedProvider = p),
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
              onTap: () => setState(() => _selectedProvider = null),
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
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      ),
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
                                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('PENDING VERIFICATION', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w900)),
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
                ],
              ),
            ),
            // Action Footer
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
                if (hasDoc)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20, color: BoostDriveTheme.primaryColor),
                    onPressed: () => _launchURL(url!),
                    tooltip: 'View Document',
                  ),
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

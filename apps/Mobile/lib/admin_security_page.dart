import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:intl/intl.dart';

class AdminSecurityPage extends ConsumerStatefulWidget {
  const AdminSecurityPage({super.key});

  @override
  ConsumerState<AdminSecurityPage> createState() => _AdminSecurityPageState();
}

class _AdminSecurityPageState extends ConsumerState<AdminSecurityPage> {
  final _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      showBackground: true,
      appBar: AppBar(
        title: const Text('SECURITY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        backgroundColor: BoostDriveTheme.surfaceDark.withOpacity(0.8),
        elevation: 0,
        centerTitle: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildQuickFreezeBox(),
              const SizedBox(height: 32),
              const Text(
                'SYSTEM AUDIT TRAIL',
                style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              _buildAuditTrail(ref),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFreezeBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: Colors.redAccent, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Quick Freeze Account',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter Phone/Email/ID',
              hintStyle: TextStyle(color: BoostDriveTheme.textDim),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: BoostDriveTheme.textDim),
                onPressed: () {
                  // In a real app we'd search and then freeze.
                  // For the UI placeholder:
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account search triggered.')));
                },
              )
            ),
          ),
          const SizedBox(height: 16),
          // We show a list of flagged accounts with quick unfreeze/freeze access.
          StreamBuilder<List<UserProfile>>(
            stream: ref.watch(userServiceProvider).getAllProfiles(),
            builder: (context, snapshot) {
              final profiles = snapshot.data ?? [];
              final restricted = profiles.where((p) => p.status == 'suspended' || p.status == 'frozen' || p.status == 'banned').toList();
              
              if (restricted.isEmpty) {
                return Text('No restricted accounts found.', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12));
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Currently Restricted:', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...restricted.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('${p.role.toUpperCase()} • ${p.status.toUpperCase()}', style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final adminUid = ref.read(currentUserProvider)?.id ?? '';
                            await ref.read(userServiceProvider).updateUserStatus(
                              uid: p.uid,
                              status: 'active',
                              adminUid: adminUid,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.fullName} restored.')));
                            }
                          },
                          child: const Text('UNFREEZE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        )
                      ],
                    ),
                  )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrail(WidgetRef ref) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ref.watch(userServiceProvider).getRecentAuditLogs(),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('No audit logs available.', style: TextStyle(color: BoostDriveTheme.textDim)),
            ),
          );
        }
        return Column(
          children: logs.map((log) {
            final actionType = log['action_type']?.toString() ?? 'SYSTEM_EVENT';
            final notes = log['notes']?.toString() ?? '';
            final createdAt = log['created_at'] != null ? DateTime.parse(log['created_at'].toString()) : DateTime.now();
            
            // Generate icon based on action type
            IconData icon = Icons.security;
            Color color = BoostDriveTheme.primaryColor;
            
            if (actionType.contains('SUSPEND') || actionType.contains('REJECT')) {
              icon = Icons.block;
              color = Colors.redAccent;
            } else if (actionType.contains('APPROVE') || actionType.contains('UNSUSPEND')) {
              icon = Icons.check_circle_outline;
              color = Colors.green;
            } else if (actionType.contains('DOC_VIEW')) {
              icon = Icons.visibility_outlined;
              color = Colors.blueAccent;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BoostDriveTheme.surfaceDark.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(actionType, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(notes, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MM/dd HH:mm').format(createdAt),
                    style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

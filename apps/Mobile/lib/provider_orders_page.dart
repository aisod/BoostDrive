import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'sos_request_detail_page.dart';

/// Dispatch-style view: SOS matched to profile services, assigned jobs, `service_requests`, history.
class ProviderOrdersPage extends ConsumerStatefulWidget {
  const ProviderOrdersPage({super.key});

  @override
  ConsumerState<ProviderOrdersPage> createState() => _ProviderOrdersPageState();
}

class _ProviderOrdersPageState extends ConsumerState<ProviderOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    // Create 3 tabs: SOS, Requests, and History.
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider ID is required for provider-only order data.
    final uid = ref.watch(currentUserProvider)?.id;
    if (uid == null) {
      return const Center(child: Text('Please log in'));
    }

    final types = ref.watch(userProfileProvider(uid)).valueOrNull?.providerServiceTypes ?? const <String>[];

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: BoostDriveTheme.backgroundDark,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ORDERS',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            TabBar(
              controller: _tabs,
              labelColor: BoostDriveTheme.primaryColor,
              unselectedLabelColor: Colors.white54,
              indicatorColor: BoostDriveTheme.primaryColor,
              tabs: const [
                Tab(text: 'SOS'),
                Tab(text: 'REQUESTS'),
                Tab(text: 'HISTORY'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _SosTab(providerId: uid, providerTypes: types),
                  _RequestsTab(providerId: uid),
                  _HistoryTab(providerId: uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosTab extends ConsumerWidget {
  const _SosTab({required this.providerId, required this.providerTypes});

  final String providerId;
  final List<String> providerTypes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch provider-assigned SOS jobs for focus mode.
    final assignedAsync = ref.watch(providerAssignedRequestsProvider(providerId));
    return RefreshIndicator(
      color: BoostDriveTheme.primaryColor,
      onRefresh: () async {
        // Force refresh assigned SOS data when user pulls down.
        ref.invalidate(providerAssignedRequestsProvider(providerId));
        await ref.read(providerAssignedRequestsProvider(providerId).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'SOS FOCUS',
            style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          assignedAsync.when(
            data: (assignedList) {
              if (assignedList.isNotEmpty) {
                final focused = assignedList.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You already accepted an SOS. Other SOS cards are hidden until this one is completed/cancelled.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    _sosCard(
                      context,
                      ref,
                      focused,
                      providerId,
                      statusLabel: 'Focused job · ${focused.status}',
                      showAccept: false,
                      showCancel: true,
                    ),
                  ],
                );
              }
              if (providerTypes.isEmpty) {
                return Text(
                  'Set service types in your profile to see matching SOS requests.',
                  style: TextStyle(color: BoostDriveTheme.textDim),
                );
              }
              return StreamBuilder<List<SosRequest>>(
                stream: ref.watch(sosServiceProvider).getGlobalActiveRequests(),
                builder: (context, snap) {
                  final all = snap.data ?? [];
                  final pending = all.where((r) => sosRequestMatchesProviderServiceTypes(r, providerTypes)).toList();
                  if (pending.isEmpty) {
                    return Text('No matching pending SOS.', style: TextStyle(color: BoostDriveTheme.textDim));
                  }
                  return Column(
                    children: pending
                        .map(
                          (r) => _sosCard(
                            context,
                            ref,
                            r,
                            providerId,
                            statusLabel: 'Pending · open pool',
                            showAccept: true,
                            showCancel: false,
                          ),
                        )
                        .toList(),
                  );
                },
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (e, _) => Text(_ordersSosErrorMessage(e), style: TextStyle(color: Colors.red.shade200, height: 1.35)),
          ),
        ],
      ),
    );
  }

  Widget _sosCard(
    BuildContext context,
    WidgetRef ref,
    SosRequest r,
    String providerId, {
    required String statusLabel,
    required bool showAccept,
    required bool showCancel,
  }) {
    // Read customer destination used by external map navigation.
    final lat = r.lat;
    final lng = r.lng;
    return Card(
      color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.6),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusLabel, style: TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              r.userNote.isNotEmpty ? r.userNote : 'SOS — ${r.type}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Customer phone: load from profiles / service_requests when wired.')),
                    );
                  },
                  icon: const Icon(Icons.phone, size: 18, color: Colors.white70),
                  label: const Text('Call', style: TextStyle(color: Colors.white70)),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final g = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                    if (await canLaunchUrl(g)) await launchUrl(g, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.navigation, size: 18, color: Colors.white70),
                  label: const Text('Navigate', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: r.id.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(builder: (_) => SosRequestDetailPage(request: r)),
                            );
                          },
                    child: const Text('OPEN'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: showAccept
                      ? FilledButton(
                          onPressed: r.id.isEmpty
                              ? null
                              : () async {
                                  try {
                                    // Accept SOS and refresh related streams.
                                    await ref.read(sosServiceProvider).acceptRequest(r.id, providerId);
                              ref.invalidate(providerAssignedRequestsProvider(providerId));
                              ref.invalidate(globalActiveSosRequestsProvider);
                              ref.invalidate(userActiveSosRequestsProvider(r.userId));
                              ref.invalidate(providerCompletedSosCountProvider(providerId));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Accepted. Focusing on this job.')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                    }
                                  }
                                },
                          child: const Text('ACCEPT'),
                        )
                      : OutlinedButton(
                          onPressed: null,
                          child: const Text('ASSIGNED'),
                        ),
                ),
              ],
            ),
            if (showCancel) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    final reasonCtrl = TextEditingController();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: BoostDriveTheme.surfaceDark,
                        title: const Text('Cancel assignment?', style: TextStyle(color: Colors.white)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'This will release this SOS back to the pending queue.',
                              style: TextStyle(color: BoostDriveTheme.textDim),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: reasonCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Reason (optional)',
                                hintStyle: TextStyle(color: BoostDriveTheme.textDim),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.06),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('KEEP')),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                            child: const Text('CANCEL ASSIGNMENT'),
                          ),
                        ],
                      ),
                    );
                    final reason = reasonCtrl.text.trim();
                    reasonCtrl.dispose();
                    if (confirm != true) return;
                    try {
                      await ref.read(sosServiceProvider).cancelAssignmentByProvider(
                            requestId: r.id,
                            reason: reason.isEmpty ? null : reason,
                          );
                      ref.invalidate(providerAssignedRequestsProvider(providerId));
                      ref.invalidate(globalActiveSosRequestsProvider);
                      ref.invalidate(userActiveSosRequestsProvider(r.userId));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Assignment cancelled. SOS returned to pending queue.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not cancel assignment: $e')),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'CANCEL ASSIGNMENT',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobCardsAsync = ref.watch(_ordersExecutionJobCardsFamily(providerId));
    // Scheduled/pooled service request rows.
    final async = ref.watch(_ordersRequestsFamily(providerId));
    return jobCardsAsync.when(
      data: (jobCards) => async.when(
      data: (rows) {
        if (rows.isEmpty) {
          if (jobCards.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'No active requests right now.',
                  style: TextStyle(color: BoostDriveTheme.textDim, height: 1.4),
                ),
              ],
            );
          }
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (jobCards.isNotEmpty) ...[
              Text(
                'JOB CARD EXECUTION',
                style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              ...jobCards.map((r) => _jobExecutionTile(context, ref, r)).toList(),
              const SizedBox(height: 14),
            ],
            if (rows.isNotEmpty) ...[
              Text(
                'OTHER REQUESTS',
                style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              ...rows.map((r) => ListTile(
                    tileColor: BoostDriveTheme.surfaceDark.withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    title: Text(r['title']?.toString() ?? 'Request', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Status: ${r['status']} · ${r['request_kind']}',
                      style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                    ),
                  )).toList(),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('$e', style: TextStyle(color: Colors.red.shade200)))),
    ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('$e', style: TextStyle(color: Colors.red.shade200)))),
    );
  }

  Widget _jobExecutionTile(BuildContext context, WidgetRef ref, Map<String, dynamic> r) {
    final id = r['id']?.toString() ?? '';
    final status = (r['status']?.toString() ?? 'accepted').toLowerCase();
    final labor = (r['labor_amount'] as num?)?.toDouble() ?? 0;
    final nextStatus = switch (status) {
      'accepted' => 'active',
      'active' => 'in_progress',
      'in_progress' => 'completed',
      _ => null,
    };
    final nextLabel = switch (nextStatus) {
      'active' => 'SET ACTIVE',
      'in_progress' => 'SET IN PROGRESS',
      'completed' => 'MARK COMPLETED',
      _ => null,
    };
    return Card(
      color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.65),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r['vehicle_label']?.toString() ?? 'Job Card',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              r['concern_summary']?.toString() ?? '',
              style: TextStyle(color: BoostDriveTheme.textDim),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${status.toUpperCase()} · Labor: N\$${labor.toStringAsFixed(2)}',
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (nextStatus != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: id.isEmpty
                      ? null
                      : () async {
                          try {
                            await ref.read(jobCardServiceProvider).setExecutionStatus(
                                  jobCardId: id,
                                  providerId: providerId,
                                  status: nextStatus,
                                );
                            ref.invalidate(_ordersExecutionJobCardsFamily(providerId));
                            ref.invalidate(_ordersExecutionHistoryJobCardsFamily(providerId));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Updated to ${nextStatus.toUpperCase()}')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not update status: $e')),
                              );
                            }
                          }
                        },
                  child: Text(nextLabel ?? 'UPDATE'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Completed/cancelled request history.
    final jobCardHistoryAsync = ref.watch(_ordersExecutionHistoryJobCardsFamily(providerId));
    final async = ref.watch(_ordersHistoryFamily(providerId));
    return jobCardHistoryAsync.when(
      data: (jobRows) => async.when(
      data: (rows) {
        if (rows.isEmpty && jobRows.isEmpty) {
          return Center(child: Text('No completed or cancelled history yet.', style: TextStyle(color: BoostDriveTheme.textDim)));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...jobRows.map((r) => ListTile(
                  tileColor: Colors.white.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  title: Text(r['vehicle_label']?.toString() ?? 'Job Card', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'job_card · ${r['status']} · completed: ${r['completed_at'] ?? '—'}',
                    style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                  ),
                )),
            ...rows.map((r) => ListTile(
                  tileColor: Colors.white.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  title: Text(r['title']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${r['status']} · completed: ${r['completed_at'] ?? '—'}',
                    style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                  ),
                )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'History unavailable on current schema. Apply latest Supabase migration.\n$e',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade200),
          ),
        ),
      ),
    ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Job card history unavailable.\n$e',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade200),
          ),
        ),
      ),
    );
  }
}

/// User-facing copy when the SOS tab cannot load assigned jobs (often `ClientException: Failed to fetch` on web).
String _ordersSosErrorMessage(Object e) {
  final s = e.toString();
  if (s.contains('Failed to fetch') || s.contains('Could not reach Supabase')) {
    return '$s\n\nTip: on web, check Wi‑Fi, try another browser, and pause strict privacy or ad blockers for this site. '
        'The Android or iOS build usually avoids this browser fetch issue.';
  }
  return s;
}

final _ordersRequestsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(providerOpsServiceProvider).listServiceRequestsForProvider(uid);
});

final _ordersHistoryFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(providerOpsServiceProvider).listServiceRequestsHistory(uid);
});

final _ordersExecutionJobCardsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(jobCardServiceProvider).listExecutionJobCardsForProvider(uid);
});

final _ordersExecutionHistoryJobCardsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(jobCardServiceProvider).listExecutionJobCardHistoryForProvider(uid);
});

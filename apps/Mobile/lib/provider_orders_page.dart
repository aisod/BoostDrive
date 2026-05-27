import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final palette = DashboardPalette.of(context);
    final uid = ref.watch(currentUserProvider)?.id;
    if (uid == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(child: Text('Please log in', style: DashboardTypography.bodyMd(palette))),
      );
    }

    final profile = ref.watch(userProfileProvider(uid)).valueOrNull;
    final types = profile?.providerServiceTypes ?? const <String>[];

    return Scaffold(
      backgroundColor: palette.background,
      appBar: MobileProviderUi.glassAppBar(
        context: context,
        palette: palette,
        title: 'ORDERS',
        avatar: MobileProviderUi.profileAvatar(
          palette: palette,
          imageUrl: profile?.profileImg,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          MobileProviderUi.segmentTabBar(
            palette: palette,
            controller: _tabs,
            labels: const ['SOS', 'REQUESTS', 'HISTORY'],
          ),
          const SizedBox(height: 12),
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
    );
  }
}

class _SosTab extends ConsumerWidget {
  const _SosTab({required this.providerId, required this.providerTypes});

  final String providerId;
  final List<String> providerTypes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DashboardPalette.of(context);
    final assignedAsync = ref.watch(providerAssignedRequestsProvider(providerId));
    return RefreshIndicator(
      color: palette.primaryContainer,
      onRefresh: () async {
        // Force refresh assigned SOS data when user pulls down.
        ref.invalidate(providerAssignedRequestsProvider(providerId));
        await ref.read(providerAssignedRequestsProvider(providerId).future);
      },
      child: ListView(
        padding: const EdgeInsets.all(MobileProviderUi.marginMobile),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Urgent Assistance',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: palette.title,
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: palette.primaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          assignedAsync.when(
            data: (assignedList) {
              if (assignedList.isNotEmpty) {
                final focused = assignedList.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You already accepted an SOS. Other SOS cards are hidden until this one is completed/cancelled.',
                      style: DashboardTypography.bodySm(palette).copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    _sosCard(
                      context,
                      ref,
                      palette,
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
                  style: DashboardTypography.bodySm(palette),
                );
              }
              return StreamBuilder<List<SosRequest>>(
                stream: ref.watch(sosServiceProvider).getGlobalActiveRequests(),
                builder: (context, snap) {
                  final all = snap.data ?? [];
                  final pending = all.where((r) => sosRequestMatchesProviderServiceTypes(r, providerTypes)).toList();
                  if (pending.isEmpty) {
                    return Text('No matching pending SOS.', style: DashboardTypography.bodySm(palette));
                  }
                  return Column(
                    children: pending
                        .map(
                          (r) => _sosCard(
                            context,
                            ref,
                            palette,
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
    DashboardPalette palette,
    SosRequest r,
    String providerId, {
    required String statusLabel,
    required bool showAccept,
    required bool showCancel,
  }) {
    final lat = r.lat;
    final lng = r.lng;
    final title = r.userNote.isNotEmpty ? r.userNote : 'SOS — ${r.type}';
    return MobileProviderUi.glassOrderCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MobileProviderUi.urgencyBadge(
                      palette: palette,
                      label: r.type.isNotEmpty ? r.type : 'SOS',
                      critical: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: palette.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(statusLabel, style: DashboardTypography.labelMd(palette).copyWith(color: palette.primaryContainer)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MobileProviderUi.metricChip(
                  palette: palette,
                  label: 'Location',
                  value: '${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MobileProviderUi.primaryButton(
                  palette: palette,
                  label: showAccept ? 'ACCEPT' : 'OPEN',
                  onPressed: r.id.isEmpty
                      ? null
                      : showAccept
                          ? () async {
                              try {
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
                            }
                          : () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(builder: (_) => SosRequestDetailPage(request: r)),
                              );
                            },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MobileProviderUi.outlineButton(
                  palette: palette,
                  label: 'NAVIGATE',
                  icon: Icons.near_me,
                  onPressed: () async {
                    final g = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                    if (await canLaunchUrl(g)) await launchUrl(g, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer phone: load from profiles / service_requests when wired.')),
                );
              },
              icon: Icon(Icons.phone, size: 18, color: palette.muted),
              label: Text('Call', style: TextStyle(color: palette.muted)),
            ),
          ),
          if (!showAccept && !showCancel)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: r.id.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => SosRequestDetailPage(request: r)),
                        );
                      },
                child: Text('View details', style: TextStyle(color: palette.primaryContainer)),
              ),
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
                      builder: (ctx) => MobileProviderUi.kineticAlertDialog(
                        palette: palette,
                        title: const Text('Cancel assignment?'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('This will release this SOS back to the pending queue.'),
                            const SizedBox(height: 10),
                            TextField(
                              controller: reasonCtrl,
                              style: TextStyle(color: palette.title),
                              decoration: MobileProviderUi.fieldDecoration(
                                palette,
                                hint: 'Reason (optional)',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('KEEP')),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(backgroundColor: palette.error),
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
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DashboardPalette.of(context);
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
                  style: DashboardTypography.bodySm(palette).copyWith(height: 1.4),
                ),
              ],
            );
          }
        }
        return ListView(
          padding: const EdgeInsets.all(MobileProviderUi.marginMobile),
          children: [
            if (jobCards.isNotEmpty) ...[
              MobileProviderUi.sectionTitle(palette, 'Job card execution'),
              const SizedBox(height: 8),
              ...jobCards.map((r) => _jobExecutionTile(context, ref, palette, r)).toList(),
              const SizedBox(height: 14),
            ],
            if (rows.isNotEmpty) ...[
              MobileProviderUi.sectionTitle(palette, 'Other requests'),
              const SizedBox(height: 8),
              ...rows.map((r) => ListTile(
                    tileColor: MobileProviderUi.cardSurface(palette),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MobileProviderUi.radiusControl),
                    ),
                    title: Text(
                      r['title']?.toString() ?? 'Request',
                      style: GoogleFonts.manrope(
                        color: palette.title,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Status: ${r['status']} · ${r['request_kind']}',
                      style: DashboardTypography.bodySm(palette),
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

  Widget _jobExecutionTile(
    BuildContext context,
    WidgetRef ref,
    DashboardPalette palette,
    Map<String, dynamic> r,
  ) {
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
      color: MobileProviderUi.cardSurface(palette),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MobileProviderUi.radiusCard)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r['vehicle_label']?.toString() ?? 'Job Card',
              style: GoogleFonts.manrope(color: palette.title, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              r['concern_summary']?.toString() ?? '',
              style: DashboardTypography.bodySm(palette),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${status.toUpperCase()} · Labor: N\$${labor.toStringAsFixed(2)}',
              style: DashboardTypography.bodySm(palette),
            ),
            const SizedBox(height: 10),
            if (nextStatus != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: palette.primaryContainer),
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
    final palette = DashboardPalette.of(context);
    // Completed/cancelled request history.
    final jobCardHistoryAsync = ref.watch(_ordersExecutionHistoryJobCardsFamily(providerId));
    final async = ref.watch(_ordersHistoryFamily(providerId));
    return jobCardHistoryAsync.when(
      data: (jobRows) => async.when(
      data: (rows) {
        if (rows.isEmpty && jobRows.isEmpty) {
          return Center(
            child: Text(
              'No completed or cancelled history yet.',
              style: DashboardTypography.bodySm(palette),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(MobileProviderUi.marginMobile),
          children: [
            ...jobRows.map((r) => ListTile(
                  tileColor: MobileProviderUi.cardSurface(palette),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MobileProviderUi.radiusControl),
                  ),
                  title: Text(
                    r['vehicle_label']?.toString() ?? 'Job Card',
                    style: TextStyle(color: palette.title),
                  ),
                  subtitle: Text(
                    'job_card · ${r['status']} · completed: ${r['completed_at'] ?? '—'}',
                    style: DashboardTypography.bodySm(palette),
                  ),
                )),
            ...rows.map((r) => ListTile(
                  tileColor: MobileProviderUi.cardSurface(palette),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MobileProviderUi.radiusControl),
                  ),
                  title: Text(r['title']?.toString() ?? '', style: TextStyle(color: palette.title)),
                  subtitle: Text(
                    '${r['status']} · completed: ${r['completed_at'] ?? '—'}',
                    style: DashboardTypography.bodySm(palette),
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

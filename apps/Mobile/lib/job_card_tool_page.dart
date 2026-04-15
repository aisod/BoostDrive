import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'providers.dart';

class JobCardToolPage extends ConsumerWidget {
  const JobCardToolPage({super.key, this.initialJobCardId});

  final String? initialJobCardId;

  static double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.id;
    if (uid == null) return const Scaffold(body: Center(child: Text('Please log in')));
    final role = ref.watch(mobileShellRoleProvider);
    final isProvider = role == 'service_pro' || role == 'logistics';
    final isRequester = role == 'customer' || role == 'seller';

    final cardsAsync = ref.watch(isProvider ? _incomingJobCardsFamily(uid) : _requesterJobCardsFamily(uid));
    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      appBar: AppBar(
        title: Text(isProvider ? 'Incoming Job Cards' : 'My Job Card Requests'),
        backgroundColor: BoostDriveTheme.backgroundDark,
      ),
      floatingActionButton: isRequester
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateJobCard(context, ref, uid, role),
              backgroundColor: BoostDriveTheme.primaryColor,
              icon: const Icon(Icons.add),
              label: const Text('NEW JOB CARD'),
            )
          : null,
      body: cardsAsync.when(
        data: (rows) {
          final targetId = (initialJobCardId ?? '').trim();
          final focusedRows = rows.isEmpty || targetId.isEmpty
              ? rows
              : _prioritizeTargetRow(rows, targetId);
          final hasTarget = targetId.isNotEmpty &&
              focusedRows.any((r) => (r['id']?.toString() ?? '') == targetId);
          if (focusedRows.isEmpty) {
            return Center(
              child: Text(
                isProvider ? 'No incoming job card requests yet.' : 'No job cards yet. Tap NEW JOB CARD.',
                style: TextStyle(color: BoostDriveTheme.textDim),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              if (hasTarget)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BoostDriveTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Opened from notification: focused job card is shown first.',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ...focusedRows.map((row) {
                final id = row['id']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _JobCardTile(
                    row: row,
                    isProvider: isProvider,
                    isFocused: targetId.isNotEmpty && id == targetId,
                    onOpen: () => _openJobCardDetails(context, ref, uid, row, isProvider),
                    onDelete: () async {
                      if (isProvider) return;
                      if (id.isEmpty) return;
                      await ref.read(jobCardServiceProvider).deleteJobCard(id);
                      ref.invalidate(_requesterJobCardsFamily(uid));
                    },
                    onStatusChanged: (status) async {
                      if (id.isEmpty) return;
                      if (status == 'cancel_request') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: BoostDriveTheme.surfaceDark,
                            title: const Text('Cancel job card request?', style: TextStyle(color: Colors.white)),
                            content: Text(
                              'Are you sure you want to cancel this job card request?',
                              style: TextStyle(color: BoostDriveTheme.textDim),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('YES, CANCEL')),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        await ref.read(jobCardServiceProvider).cancelJobCardRequest(
                              jobCardId: id,
                              requesterId: uid,
                            );
                        ref.invalidate(_requesterJobCardsFamily(uid));
                        ref.invalidate(_incomingJobCardsFamily(uid));
                        return;
                      }
                      if (status == 'accept_quote' || status == 'decline_quote') {
                        await ref.read(jobCardServiceProvider).customerDecideOnQuote(
                              jobCardId: id,
                              requesterId: uid,
                              accept: status == 'accept_quote',
                            );
                        ref.invalidate(_requesterJobCardsFamily(uid));
                        return;
                      }
                      if (!isProvider) return;
                      final amount = await _promptQuoteAmount(context, initial: _num(row['labor_amount']));
                      if (amount == null) return;
                      try {
                        await ref.read(jobCardServiceProvider).providerQuoteJobCard(
                              jobCardId: id,
                              providerId: uid,
                              quotedLaborAmount: amount,
                            );
                        if (!context.mounted) return;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) return;
                          ref.invalidate(_incomingJobCardsFamily(uid));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Quote sent. Awaiting client response.')),
                            );
                          }
                        });
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not send quote: $e')),
                          );
                        }
                      }
                    },
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load job cards: $e', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  List<Map<String, dynamic>> _prioritizeTargetRow(List<Map<String, dynamic>> rows, String targetId) {
    final copy = List<Map<String, dynamic>>.from(rows);
    final idx = copy.indexWhere((r) => (r['id']?.toString() ?? '') == targetId);
    if (idx <= 0) return copy;
    final item = copy.removeAt(idx);
    copy.insert(0, item);
    return copy;
  }

  Future<void> _openCreateJobCard(BuildContext context, WidgetRef ref, String uid, String role) async {
    final vehicle = TextEditingController();
    final concern = TextEditingController();
    final diagnosis = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('New Job Card', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _f(vehicle, 'Vehicle (e.g. Toyota Hilux 2020)'),
              _f(concern, 'Issue / concern'),
              _f(diagnosis, 'Diagnosis notes', maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CREATE')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(jobCardServiceProvider).createJobCardRequest(
            requesterId: uid,
            requesterRole: role == 'seller' ? 'seller' : 'customer',
            vehicleLabel: vehicle.text.trim(),
            concernSummary: concern.text.trim(),
            diagnosisNotes: diagnosis.text.trim(),
          );
      ref.invalidate(_requesterJobCardsFamily(uid));
    }
    vehicle.dispose();
    concern.dispose();
    diagnosis.dispose();
  }

  Future<void> _openJobCardDetails(
    BuildContext context,
    WidgetRef ref,
    String uid,
    Map<String, dynamic> row,
    bool isProvider,
  ) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final status = (row['status']?.toString() ?? 'submitted').toLowerCase();
    if (!isProvider) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Required parts are managed by the service provider after you accept a quote.')),
        );
      }
      return;
    }
    if (status != 'accepted') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add required parts only after customer accepts your quote.')),
        );
      }
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BoostDriveTheme.surfaceDark,
      builder: (ctx) => _JobCardDetailsSheet(jobCardId: id, providerId: uid),
    );
    ref.invalidate(_requesterJobCardsFamily(uid));
    ref.invalidate(_incomingJobCardsFamily(uid));
  }

  Future<double?> _promptQuoteAmount(BuildContext context, {double initial = 0}) async {
    final c = TextEditingController(text: initial.toStringAsFixed(2));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Respond with labor quote', style: TextStyle(color: Colors.white)),
        content: _f(
          c,
          'Labor amount (N\$)',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SEND QUOTE')),
        ],
      ),
    );
    final v = double.tryParse(c.text.trim());
    c.dispose();
    if (ok != true || v == null || v < 0) return null;
    return v;
  }
}

class _JobCardTile extends StatelessWidget {
  const _JobCardTile({
    required this.row,
    required this.isProvider,
    required this.isFocused,
    required this.onOpen,
    required this.onDelete,
    required this.onStatusChanged,
  });

  final Map<String, dynamic> row;
  final bool isProvider;
  final bool isFocused;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final labor = (row['labor_amount'] as num?)?.toDouble() ?? 0;
    final status = (row['status']?.toString() ?? 'submitted').toLowerCase();
    String statusLabel;
    switch (status) {
      case 'quoted':
        statusLabel = 'AWAITING CLIENT RESPONSE';
        break;
      case 'accepted':
        statusLabel = 'ACCEPTED';
        break;
      case 'declined':
        statusLabel = 'DECLINED';
        break;
      case 'cancelled':
        statusLabel = 'CANCELLED';
        break;
      default:
        statusLabel = 'SUBMITTED';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: isFocused ? Border.all(color: BoostDriveTheme.primaryColor.withValues(alpha: 0.9), width: 1.4) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row['vehicle_label']?.toString() ?? 'Vehicle not set',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(row['concern_summary']?.toString() ?? '',
              style: TextStyle(color: BoostDriveTheme.textDim, height: 1.3)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Labor: N\$${labor.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isProvider && status == 'submitted')
                TextButton(
                  onPressed: () => onStatusChanged('quoted'),
                  child: const Text('RESPOND WITH PRICE'),
                ),
              if (!isProvider && status == 'quoted') ...[
                TextButton(
                  onPressed: () => onStatusChanged('decline_quote'),
                  child: const Text('DECLINE'),
                ),
                FilledButton(
                  onPressed: () => onStatusChanged('accept_quote'),
                  child: const Text('ACCEPT'),
                ),
              ],
              if (!isProvider && (status == 'submitted' || status == 'quoted'))
                TextButton(
                  onPressed: () => onStatusChanged('cancel_request'),
                  child: const Text('CANCEL REQUEST'),
                ),
              if (isProvider)
                TextButton(onPressed: onOpen, child: const Text('OPEN')),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobCardDetailsSheet extends ConsumerWidget {
  const _JobCardDetailsSheet({required this.jobCardId, required this.providerId});

  final String jobCardId;
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(_jobCardPartsFamily(jobCardId));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Required Parts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: FilledButton.icon(
              onPressed: () => _addPart(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('ADD PART'),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: partsAsync.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return Center(child: Text('No parts added yet.', style: TextStyle(color: BoostDriveTheme.textDim)));
                }
                final partsTotal = rows.fold<double>(
                  0,
                  (sum, r) => sum + ((r['quantity'] as num?)?.toDouble() ?? 0) * ((r['unit_price'] as num?)?.toDouble() ?? 0),
                );
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white12),
                        itemBuilder: (context, i) {
                          final r = rows[i];
                          final qty = (r['quantity'] as num?)?.toInt() ?? 0;
                          final unit = (r['unit_price'] as num?)?.toDouble() ?? 0;
                          final line = qty * unit;
                          return ListTile(
                            title: Text(r['part_name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Qty $qty × N\$${unit.toStringAsFixed(2)}',
                                style: TextStyle(color: BoostDriveTheme.textDim)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('N\$${line.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                  onPressed: () => _editPart(context, ref, r),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () async {
                                    await ref.read(jobCardServiceProvider).deleteJobCardPart(r['id'].toString());
                                    ref.invalidate(_jobCardPartsFamily(jobCardId));
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Text('Parts total', style: TextStyle(color: BoostDriveTheme.textDim)),
                          const Spacer(),
                          Text('N\$${partsTotal.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.redAccent))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await ref.read(jobCardServiceProvider).pushRequiredPartsToCustomerCart(
                          jobCardId: jobCardId,
                          providerId: providerId,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Parts pushed to customer cart queue.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
                child: const Text('PUSH REQUIRED PARTS TO CUSTOMER CART'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPart(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final qty = TextEditingController(text: '1');
    final price = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Add required part', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _f(name, 'Part name'),
            _f(qty, 'Quantity', keyboard: TextInputType.number),
            _f(price, 'Unit price', keyboard: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ADD')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(jobCardServiceProvider).addJobCardPart(
            jobCardId: jobCardId,
            partName: name.text.trim(),
            quantity: int.tryParse(qty.text.trim()) ?? 1,
            unitPrice: double.tryParse(price.text.trim()) ?? 0,
          );
      ref.invalidate(_jobCardPartsFamily(jobCardId));
    }
    name.dispose();
    qty.dispose();
    price.dispose();
  }

  Future<void> _editPart(BuildContext context, WidgetRef ref, Map<String, dynamic> row) async {
    final name = TextEditingController(text: row['part_name']?.toString() ?? '');
    final qty = TextEditingController(text: ((row['quantity'] as num?)?.toInt() ?? 1).toString());
    final price = TextEditingController(text: ((row['unit_price'] as num?)?.toDouble() ?? 0).toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Edit required part', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _f(name, 'Part name'),
            _f(qty, 'Quantity', keyboard: TextInputType.number),
            _f(price, 'Unit price', keyboard: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(jobCardServiceProvider).updateJobCardPart(
            partId: row['id'].toString(),
            partName: name.text.trim(),
            quantity: int.tryParse(qty.text.trim()) ?? 1,
            unitPrice: double.tryParse(price.text.trim()) ?? 0,
          );
      ref.invalidate(_jobCardPartsFamily(jobCardId));
    }
    name.dispose();
    qty.dispose();
    price.dispose();
  }
}

Widget _f(
  TextEditingController c,
  String hint, {
  int maxLines = 1,
  TextInputType keyboard = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: BoostDriveTheme.textDim),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    ),
  );
}

final _requesterJobCardsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(jobCardServiceProvider).listJobCardsForRequester(uid);
});

final _incomingJobCardsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(jobCardServiceProvider).listIncomingJobCardsForProvider(uid);
});

final _jobCardPartsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, jobCardId) async {
  return ref.read(jobCardServiceProvider).listJobCardParts(jobCardId);
});

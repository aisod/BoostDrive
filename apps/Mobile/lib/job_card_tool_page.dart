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
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }
    final palette = DashboardPalette.of(context);
    final role = ref.watch(mobileShellRoleProvider);
    final isProvider = role == 'service_pro' || role == 'logistics';
    final isRequester = role == 'customer' || role == 'seller';

    final cardsAsync = ref.watch(isProvider ? _incomingJobCardsFamily(uid) : _requesterJobCardsFamily(uid));
    final pageTitle = isProvider ? 'Incoming Job Cards' : 'My Job Card Requests';
    final appBarTitle = isProvider ? pageTitle : 'BOOSTDRIVE';

    return Scaffold(
      backgroundColor: palette.background,
      appBar: MobileJobCardUi.listAppBar(
        context: context,
        title: appBarTitle,
        actions: MobileCustomerUi.appBarActions(onColoredHeader: !palette.isDark),
      ),
      floatingActionButton: isRequester
          ? MobileJobCardUi.newJobCardFab(
              onPressed: () => _openCreateJobCard(context, ref, uid, role),
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  isProvider
                      ? 'No incoming job card requests yet.'
                      : 'No job cards yet. Tap NEW JOB CARD.',
                  style: DashboardTypography.bodyMd(palette),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final submittedCount = focusedRows.where((r) => (r['status']?.toString() ?? '').toLowerCase() == 'submitted').length;
          final quotedCount = focusedRows.where((r) => (r['status']?.toString() ?? '').toLowerCase() == 'quoted').length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              MobileJobCardUi.marginMobile,
              12,
              MobileJobCardUi.marginMobile,
              96,
            ),
            children: [
              if (hasTarget)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MobileJobCardUi.focusBanner(
                    palette: palette,
                    message: 'Opened from notification: focused job card is shown first.',
                  ),
                ),
              if (isProvider) ...[
                MobileJobCardUi.listHeader(
                  palette: palette,
                  title: 'Incoming Jobs',
                  totalCount: focusedRows.length,
                  subtitle: 'Review and respond to service requests from vehicle owners.',
                ),
                const SizedBox(height: 12),
                MobileJobCardUi.providerStatsRow(
                  palette: palette,
                  total: focusedRows.length,
                  submitted: submittedCount,
                  quoted: quotedCount,
                ),
              ]               else
                MobileJobCardUi.listHeader(
                  palette: palette,
                  title: 'My Job Card Requests',
                  totalCount: focusedRows.length,
                ),
              const SizedBox(height: 16),
              ...focusedRows.map((row) {
                final id = row['id']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: isProvider
                      ? MobileJobCardUi.providerTile(
                          palette: palette,
                          row: row,
                          onRespond: (row['status']?.toString() ?? '').toLowerCase() == 'submitted'
                              ? () => _onStatusChanged(context, ref, uid, row, isProvider, 'quoted')
                              : null,
                          onOpen: () => _openJobCardDetails(context, ref, uid, row, isProvider),
                        )
                      : MobileJobCardUi.customerTile(
                          palette: palette,
                          row: row,
                          isFocused: targetId.isNotEmpty && id == targetId,
                          onAccept: (row['status']?.toString() ?? '').toLowerCase() == 'quoted'
                              ? () => _onStatusChanged(context, ref, uid, row, isProvider, 'accept_quote')
                              : null,
                          onDecline: (row['status']?.toString() ?? '').toLowerCase() == 'quoted'
                              ? () => _onStatusChanged(context, ref, uid, row, isProvider, 'decline_quote')
                              : null,
                          onCancel: () => _onStatusChanged(context, ref, uid, row, isProvider, 'cancel_request'),
                        ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Could not load job cards: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
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

  Future<void> _onStatusChanged(
    BuildContext context,
    WidgetRef ref,
    String uid,
    Map<String, dynamic> row,
    bool isProvider,
    String status,
  ) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;

    if (status == 'cancel_request') {
      final palette = DashboardPalette.of(context);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => MobileJobCardUi.dialogShell(
          palette: palette,
          title: 'Cancel job card request?',
          subtitle: 'Are you sure you want to cancel this job card request?',
          children: const [],
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO')),
            MobileJobCardUi.primaryDialogButton(
              label: 'YES, CANCEL',
              onPressed: () => Navigator.pop(ctx, true),
            ),
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
  }

  Future<void> _openCreateJobCard(BuildContext context, WidgetRef ref, String uid, String role) async {
    final palette = DashboardPalette.of(context);
    final vehicle = TextEditingController();
    final concern = TextEditingController();
    final diagnosis = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: palette.isDark ? Colors.black.withValues(alpha: 0.6) : const Color(0xFF0F172A).withValues(alpha: 0.4),
      builder: (ctx) => MobileJobCardUi.dialogShell(
        palette: palette,
        title: 'New Job Card',
        subtitle: 'Fill in the details to initiate a new service entry.',
        children: [
          MobileJobCardUi.themedTextField(
            palette: palette,
            controller: vehicle,
            label: 'Vehicle',
            hint: 'e.g. Toyota Hilux 2020',
            icon: Icons.directions_car_outlined,
          ),
          const SizedBox(height: 12),
          MobileJobCardUi.themedTextField(
            palette: palette,
            controller: concern,
            label: 'Issue / concern',
            hint: 'Brake squeaking, engine light on',
            icon: Icons.report_problem_outlined,
          ),
          const SizedBox(height: 12),
          MobileJobCardUi.themedTextField(
            palette: palette,
            controller: diagnosis,
            label: 'Diagnosis notes',
            hint: 'Initial observations and diagnostic steps taken...',
            maxLines: 3,
          ),
        ],
        actions: [
          MobileJobCardUi.cancelTextButton(
            palette: palette,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          MobileJobCardUi.primaryDialogButton(
            label: 'CREATE',
            onPressed: () => Navigator.pop(ctx, true),
          ),
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
          const SnackBar(
            content: Text(
              'Required parts are managed by the service provider after you accept a quote.',
            ),
          ),
        );
      }
      return;
    }
    if (status != 'accepted') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add required parts only after customer accepts your quote.'),
          ),
        );
      }
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _JobCardDetailsSheet(jobCardId: id, providerId: uid),
    );
    ref.invalidate(_requesterJobCardsFamily(uid));
    ref.invalidate(_incomingJobCardsFamily(uid));
  }

  Future<double?> _promptQuoteAmount(BuildContext context, {double initial = 0}) async {
    final palette = DashboardPalette.of(context);
    final c = TextEditingController(text: initial > 0 ? initial.toStringAsFixed(2) : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => MobileJobCardUi.dialogShell(
        palette: palette,
        title: 'Respond with labor quote',
        subtitle: 'Enter your labor amount for this job card.',
        children: [
          MobileJobCardUi.themedTextField(
            palette: palette,
            controller: c,
            label: 'Labor amount (N\$)',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
        actions: [
          MobileJobCardUi.cancelTextButton(
            palette: palette,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          MobileJobCardUi.primaryDialogButton(
            label: 'SEND QUOTE',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    final v = double.tryParse(c.text.trim());
    c.dispose();
    if (ok != true || v == null || v < 0) return null;
    return v;
  }
}

class _JobCardDetailsSheet extends ConsumerWidget {
  const _JobCardDetailsSheet({required this.jobCardId, required this.providerId});

  final String jobCardId;
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DashboardPalette.of(context);
    final partsAsync = ref.watch(_jobCardPartsFamily(jobCardId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: maxHeight,
        child: Container(
          decoration: BoxDecoration(
            color: palette.isDark ? palette.surfaceContainer : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: palette.isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: palette.isDark ? 0.5 : 0.12),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: partsAsync.when(
            data: (rows) {
              final partsTotal = rows.fold<double>(
                0,
                (sum, r) =>
                    sum + ((r['quantity'] as num?)?.toDouble() ?? 0) * ((r['unit_price'] as num?)?.toDouble() ?? 0),
              );
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: palette.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Required Parts',
                            style: DashboardTypography.headlineLg(palette).copyWith(fontSize: 24),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _addPart(context, ref),
                          style: FilledButton.styleFrom(
                            backgroundColor: MobileJobCardUi.kineticOrange.withValues(alpha: 0.12),
                            foregroundColor: MobileJobCardUi.kineticOrange,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('ADD PART'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: rows.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: palette.onSurfaceVariant.withValues(alpha: 0.25),
                                ),
                                const SizedBox(height: 8),
                                Text('No parts added yet.', style: DashboardTypography.bodyMd(palette)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            itemCount: rows.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _partRow(context, ref, palette, rows[i]),
                          ),
                  ),
                  _partsFooter(context, ref, palette, partsTotal, bottomInset),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('$e', style: TextStyle(color: palette.error))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _partRow(
    BuildContext context,
    WidgetRef ref,
    DashboardPalette palette,
    Map<String, dynamic> r,
  ) {
    final qty = (r['quantity'] as num?)?.toInt() ?? 0;
    final unit = (r['unit_price'] as num?)?.toDouble() ?? 0;
    final line = qty * unit;
    final name = r['part_name']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surfaceContainerHigh : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                ),
                child: Icon(Icons.build_outlined, color: MobileJobCardUi.kineticOrange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: DashboardTypography.headlineMd(palette).copyWith(fontSize: 17)),
                    Text(
                      'Qty $qty × N\$${unit.toStringAsFixed(2)}',
                      style: DashboardTypography.labelMd(palette),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: palette.onSurfaceVariant, size: 20),
                onPressed: () => _editPart(context, ref, r),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: palette.error, size: 20),
                onPressed: () async {
                  await ref.read(jobCardServiceProvider).deleteJobCardPart(r['id'].toString());
                  ref.invalidate(_jobCardPartsFamily(jobCardId));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'N\$${line.toStringAsFixed(2)}',
              style: DashboardTypography.headlineMd(palette).copyWith(
                fontSize: 18,
                color: MobileJobCardUi.kineticOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _partsFooter(
    BuildContext context,
    WidgetRef ref,
    DashboardPalette palette,
    double partsTotal,
    double bottomInset,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surfaceContainerHighest.withValues(alpha: 0.95) : Colors.white,
        border: Border(top: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Parts total', style: DashboardTypography.labelLg(palette)),
              const Spacer(),
              Text(
                'N\$${partsTotal.toStringAsFixed(2)}',
                style: DashboardTypography.headlineLg(palette).copyWith(
                  fontSize: 26,
                  color: MobileJobCardUi.kineticOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
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
              style: FilledButton.styleFrom(
                backgroundColor: MobileJobCardUi.kineticOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.shopping_cart_checkout),
              label: const Text('PUSH REQUIRED PARTS TO CUSTOMER CART'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPart(BuildContext context, WidgetRef ref) async {
    final palette = DashboardPalette.of(context);
    final name = TextEditingController();
    final qty = TextEditingController(text: '1');
    final price = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => MobileJobCardUi.dialogShell(
        palette: palette,
        title: 'Add required part',
        children: [
          MobileJobCardUi.themedTextField(palette: palette, controller: name, label: 'Part name'),
          const SizedBox(height: 12),
          MobileJobCardUi.themedTextField(
            palette: palette,
            controller: qty,
            label: 'Quantity',
            keyboard: TextInputType.number,
          ),
          const SizedBox(height: 12),
          MobileJobCardUi.themedTextField(
            palette: palette,
            controller: price,
            label: 'Unit price',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
        actions: [
          MobileJobCardUi.cancelTextButton(palette: palette, onPressed: () => Navigator.pop(ctx, false)),
          MobileJobCardUi.primaryDialogButton(label: 'ADD', onPressed: () => Navigator.pop(ctx, true)),
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
    final palette = DashboardPalette.of(context);
    final name = TextEditingController(text: row['part_name']?.toString() ?? '');
    final qty = TextEditingController(text: ((row['quantity'] as num?)?.toInt() ?? 1).toString());
    final price = TextEditingController(text: ((row['unit_price'] as num?)?.toDouble() ?? 0).toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => MobileJobCardUi.dialogShell(
        palette: palette,
        title: 'Edit required part',
        children: [
          MobileJobCardUi.themedTextField(palette: palette, controller: name, label: 'Part name'),
          const SizedBox(height: 12),
          MobileJobCardUi.themedTextField(
            palette: palette,
            controller: qty,
            label: 'Quantity',
            keyboard: TextInputType.number,
          ),
          const SizedBox(height: 12),
          MobileJobCardUi.themedTextField(
            palette: palette,
            controller: price,
            label: 'Unit price',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
        actions: [
          MobileJobCardUi.cancelTextButton(palette: palette, onPressed: () => Navigator.pop(ctx, false)),
          MobileJobCardUi.primaryDialogButton(label: 'SAVE', onPressed: () => Navigator.pop(ctx, true)),
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

final _requesterJobCardsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(jobCardServiceProvider).listJobCardsForRequester(uid);
});

final _incomingJobCardsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(jobCardServiceProvider).listIncomingJobCardsForProvider(uid);
});

final _jobCardPartsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, jobCardId) async {
  return ref.read(jobCardServiceProvider).listJobCardParts(jobCardId);
});

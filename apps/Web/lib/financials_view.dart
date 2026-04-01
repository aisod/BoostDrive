import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// State: Date Range Filter
// ---------------------------------------------------------------------------
enum FinancialDateRange { today, week, month, year }

final financialDateRangeProvider = StateProvider<FinancialDateRange>(
  (ref) => FinancialDateRange.month,
);

// ---------------------------------------------------------------------------
// Derived providers
// ---------------------------------------------------------------------------

/// Splits all profiles into customers/sellers vs providers
final userRoleSplitProvider = Provider<Map<String, int>>((ref) {
  final profiles = ref.watch(allProfilesProvider).valueOrNull ?? [];
  int customers = 0;
  int providers = 0;
  int admins = 0;
  int suspended = 0;

  for (final p in profiles) {
    final role = p.role.toLowerCase();
    if (role == 'admin' || p.isAdmin) {
      admins++;
    } else if (role == 'mechanic' ||
        role == 'towing' ||
        role == 'service_provider' ||
        role == 'provider') {
      providers++;
    } else {
      customers++;
    }
    if (p.status == 'suspended' || p.status == 'banned') suspended++;
  }

  return {
    'customers': customers,
    'providers': providers,
    'admins': admins,
    'suspended': suspended,
    'total': profiles.length,
  };
});

/// Service category revenue breakdown from profiles (using standard labor rate proxy)
final serviceCategoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final profiles = ref.watch(allProfilesProvider).valueOrNull ?? [];
  final breakdown = <String, double>{};
  for (final p in profiles) {
    if (p.primaryServiceCategory != null &&
        p.primaryServiceCategory!.isNotEmpty) {
      final cat = p.primaryServiceCategory!;
      final rate = p.standardLaborRate ?? 0.0;
      breakdown[cat] = (breakdown[cat] ?? 0.0) + rate;
    }
  }
  return breakdown;
});

/// Providers who have bank details set (eligible for payout)
final payoutEligibleProvidersProvider = Provider<List<UserProfile>>((ref) {
  final profiles = ref.watch(allProfilesProvider).valueOrNull ?? [];
  return profiles
      .where((p) =>
          (p.role == 'mechanic' ||
              p.role == 'towing' ||
              p.role == 'service_provider' ||
              p.role == 'provider') &&
          p.verificationStatus == 'approved' &&
          p.bankName != null &&
          p.bankName!.isNotEmpty)
      .toList();
});

/// Suspended accounts (potential fraud flag)
final suspendedAccountsProvider = Provider<List<UserProfile>>((ref) {
  final profiles = ref.watch(allProfilesProvider).valueOrNull ?? [];
  return profiles
      .where((p) => p.status == 'suspended' || p.status == 'banned')
      .toList();
});

// ---------------------------------------------------------------------------
// Main View
// ---------------------------------------------------------------------------
class FinancialsView extends ConsumerWidget {
  const FinancialsView({super.key});

  static const double _commissionRate = 0.10; // 10% platform fee

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(financialDateRangeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(context, ref, dateRange),
          const SizedBox(height: 28),
          _buildKPIRow(ref),
          const SizedBox(height: 28),
          _buildSecondaryRow(ref),
          const SizedBox(height: 28),
          _buildBottomRow(ref),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Header + Date Filter
  // -------------------------------------------------------------------------
  Widget _buildPageHeader(
      BuildContext context, WidgetRef ref, FinancialDateRange range) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financials',
              style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Platform economics & operational health',
              style: TextStyle(fontFamily: 'Manrope', fontSize: 14, color: Colors.black45),
            ),
          ],
        ),
        const Spacer(),
        _buildDateFilter(ref, range),
      ],
    );
  }

  Widget _buildDateFilter(WidgetRef ref, FinancialDateRange current) {
    const labels = {
      FinancialDateRange.today: 'Today',
      FinancialDateRange.week: '7D',
      FinancialDateRange.month: '30D',
      FinancialDateRange.year: 'Year',
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: FinancialDateRange.values.map((range) {
          final selected = current == range;
          return GestureDetector(
            onTap: () => ref
                .read(financialDateRangeProvider.notifier)
                .state = range,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? BoostDriveTheme.primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                labels[range]!,
                style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Row 1: 4 Primary KPI Cards
  // -------------------------------------------------------------------------
  Widget _buildKPIRow(WidgetRef ref) {
    final volumeAsync = ref.watch(globalVolumeProvider);
    final pendingAsync = ref.watch(pendingVerificationsProvider);
    final sosAsync = ref.watch(globalActiveSosRequestsProvider);

    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;
      final cards = [
        // Marketplace Volume + Commission
        volumeAsync.when(
          data: (vol) {
            final commission = vol * _commissionRate;
            return _buildPrimaryKPICard(
              label: 'MARKETPLACE VOLUME',
              value: _formatNAD(vol),
              subLabel: 'Commission Earned',
              subValue: _formatNAD(commission),
              subColor: Colors.green,
              icon: Icons.show_chart_rounded,
              color: BoostDriveTheme.primaryColor,
              badge: 'GMV',
            );
          },
          loading: () => _buildPrimaryKPICard(
              label: 'MARKETPLACE VOLUME',
              value: '…',
              subLabel: 'Commission Earned',
              subValue: '…',
              subColor: Colors.green,
              icon: Icons.show_chart_rounded,
              color: BoostDriveTheme.primaryColor,
              badge: 'GMV'),
          error: (_, __) => _buildPrimaryKPICard(
              label: 'MARKETPLACE VOLUME',
              value: 'N/A',
              subLabel: 'Commission Earned',
              subValue: 'N/A',
              subColor: Colors.green,
              icon: Icons.show_chart_rounded,
              color: BoostDriveTheme.primaryColor,
              badge: 'GMV'),
        ),
        // User Base (split)
        Builder(builder: (_) {
          final split = ref.watch(userRoleSplitProvider);
          final total = split['total'] ?? 0;
          final customers = split['customers'] ?? 0;
          final providers = split['providers'] ?? 0;
          return _buildPrimaryKPICard(
            label: 'USER BASE',
            value: total == 0 && ref.watch(allProfilesProvider).isLoading ? '…' : total.toString(),
            subLabel: '$customers Customers · $providers Providers',
            subValue: '',
            subColor: Colors.purpleAccent,
            icon: Icons.people_alt_rounded,
            color: Colors.purpleAccent,
            badge: '',
          );
        }),
        // Pending Verifications (Bottleneck metric)
        pendingAsync.when(
          data: (pending) {
            final count = pending.length;
            final bottleneck = count > 5;
            return _buildPrimaryKPICard(
              label: 'PENDING VERIFICATIONS',
              value: count.toString(),
              subLabel: bottleneck ? '⚠ Revenue Bottleneck' : 'Queue is healthy',
              subValue: '',
              subColor: bottleneck ? Colors.orange : Colors.green,
              icon: Icons.pending_actions_rounded,
              color: Colors.orange,
              badge: bottleneck ? 'URGENT' : '',
            );
          },
          loading: () => _buildPrimaryKPICard(
              label: 'PENDING VERIFICATIONS',
              value: '…',
              subLabel: '…',
              subValue: '',
              subColor: Colors.orange,
              icon: Icons.pending_actions_rounded,
              color: Colors.orange,
              badge: ''),
          error: (_, __) => _buildPrimaryKPICard(
              label: 'PENDING VERIFICATIONS',
              value: 'N/A',
              subLabel: 'Could not load',
              subValue: '',
              subColor: Colors.orange,
              icon: Icons.pending_actions_rounded,
              color: Colors.orange,
              badge: ''),
        ),
        // Active SOS + completion rate proxy
        sosAsync.when(
          data: (requests) {
            final active = requests.length;
            return _buildPrimaryKPICard(
              label: 'ACTIVE SOS',
              value: active.toString(),
              subLabel: 'Live Requests',
              subValue: active > 0 ? 'Monitoring' : 'All Clear',
              subColor: active > 0 ? Colors.redAccent : Colors.green,
              icon: Icons.sos_rounded,
              color: Colors.redAccent,
              badge: active > 10 ? 'HIGH LOAD' : '',
            );
          },
          loading: () => _buildPrimaryKPICard(
              label: 'ACTIVE SOS',
              value: '…',
              subLabel: 'Live Requests',
              subValue: '…',
              subColor: Colors.redAccent,
              icon: Icons.sos_rounded,
              color: Colors.redAccent,
              badge: ''),
          error: (_, __) => _buildPrimaryKPICard(
              label: 'ACTIVE SOS',
              value: 'N/A',
              subLabel: 'Could not load',
              subValue: '',
              subColor: Colors.redAccent,
              icon: Icons.sos_rounded,
              color: Colors.redAccent,
              badge: ''),
        ),
      ];

      if (isNarrow) {
        return Column(
          children: cards
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: c,
                  ))
              .toList(),
        );
      }

      return Row(
        children: cards
            .map((c) => Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: c,
                )))
            .toList(),
      );
    });
  }

  Widget _buildPrimaryKPICard({
    required String label,
    required String value,
    required String subLabel,
    required String subValue,
    required Color subColor,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              if (badge.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge,
                      style: TextStyle(fontFamily: 'Manrope', 
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.redAccent,
                          letterSpacing: 0.5)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(label,
              style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.black45,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.black.withValues(alpha: 0.05)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(subLabel,
                    style: TextStyle(fontFamily: 'Manrope', 
                        fontSize: 11, color: Colors.black54),
                    overflow: TextOverflow.ellipsis),
              ),
              if (subValue.isNotEmpty)
                Text(subValue,
                    style: TextStyle(fontFamily: 'Manrope', 
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: subColor)),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Row 2: Service Category Revenue Chart + Provider Health
  // -------------------------------------------------------------------------
  Widget _buildSecondaryRow(WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;
      return Flex(
        direction: isNarrow ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isNarrow
              ? _buildCategoryRevenueChart(ref)
              : Expanded(flex: 3, child: _buildCategoryRevenueChart(ref)),
          SizedBox(width: isNarrow ? 0 : 24, height: isNarrow ? 24 : 0),
          isNarrow
              ? _buildProviderHealthCard(ref)
              : Expanded(flex: 2, child: _buildProviderHealthCard(ref)),
        ],
      );
    });
  }

  Widget _buildCategoryRevenueChart(WidgetRef ref) {
    final volumeAsync = ref.watch(globalVolumeProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service Revenue Breakdown',
                      style: TextStyle(fontFamily: 'Manrope', 
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('Labor rate by service category',
                      style: TextStyle(fontFamily: 'Manrope', 
                          fontSize: 12, color: Colors.black45)),
                ],
              ),
              const Spacer(),
              volumeAsync.when(
                data: (vol) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Total: ${_formatNAD(vol)}',
                      style: TextStyle(fontFamily: 'Manrope', 
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BoostDriveTheme.primaryColor)),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Builder(builder: (_) {
            final data = ref.watch(serviceCategoryBreakdownProvider);
            if (data.isEmpty) {
              return _buildEmptyState(
                  'No provider service data yet',
                  'As providers register and set their labor rates, revenue categories will appear here.',
                  Icons.bar_chart_rounded);
            }
            final total = data.values.fold(0.0, (a, b) => a + b);
            final sorted = data.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            return Column(
              children: sorted.asMap().entries.map((entry) {
                final idx = entry.key;
                final cat = entry.value.key;
                final val = entry.value.value;
                final pct = total > 0 ? val / total : 0.0;
                final colors = [
                  BoostDriveTheme.primaryColor,
                  Colors.purpleAccent,
                  Colors.blueAccent,
                  Colors.tealAccent.shade700,
                  Colors.deepOrangeAccent,
                ];
                final color = colors[idx % colors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _humanizeCategory(cat),
                            style: TextStyle(fontFamily: 'Manrope', 
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                          ),
                          const Spacer(),
                          Text(
                            _formatNAD(val),
                            style: TextStyle(fontFamily: 'Manrope', 
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontFamily: 'Manrope', 
                                fontSize: 11, color: Colors.black45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor:
                              Colors.black.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProviderHealthCard(WidgetRef ref) {
    final allAsync = ref.watch(allProfilesProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Provider Tier Stats',
              style: TextStyle(fontFamily: 'Manrope', 
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          const SizedBox(height: 4),
          Text('Verified vs Unverified supply',
              style:
                  TextStyle(fontFamily: 'Manrope', fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 24),
          allAsync.when(
            data: (profiles) {
              final providers = profiles.where((p) {
                final r = p.role.toLowerCase();
                return r == 'mechanic' ||
                    r == 'towing' ||
                    r == 'service_provider' ||
                    r == 'provider';
              }).toList();

              final verified =
                  providers.where((p) => p.verificationStatus == 'approved').length;
              final pending =
                  providers.where((p) => p.verificationStatus == 'pending' || p.verificationStatus == 'unverified').length;
              final rejected =
                  providers.where((p) => p.verificationStatus == 'rejected').length;
              final withBanking =
                  providers.where((p) => p.bankName != null && p.bankName!.isNotEmpty).length;
              final withLaborRate =
                  providers.where((p) => (p.standardLaborRate ?? 0) > 0).length;

              if (providers.isEmpty) {
                return _buildEmptyState('No providers yet',
                    'Provider stats will appear once service providers register.',
                    Icons.storefront_rounded);
              }

              return Column(
                children: [
                  _buildStatRow('Verified Providers', verified.toString(),
                      Colors.green, Icons.verified_rounded),
                  const SizedBox(height: 12),
                  _buildStatRow('Pending Verification', pending.toString(),
                      Colors.orange, Icons.access_time_rounded),
                  const SizedBox(height: 12),
                  _buildStatRow('Rejected', rejected.toString(),
                      Colors.redAccent, Icons.cancel_rounded),
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                  const SizedBox(height: 20),
                  _buildStatRow('With Banking Details', withBanking.toString(),
                      Colors.blueAccent, Icons.account_balance_rounded),
                  const SizedBox(height: 12),
                  _buildStatRow('With Labor Rate Set', withLaborRate.toString(),
                      Colors.purpleAccent, Icons.attach_money_rounded),
                  const SizedBox(height: 20),
                  // Payout readiness progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payout Readiness',
                          style: TextStyle(fontFamily: 'Manrope', 
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.black45,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: providers.isNotEmpty
                              ? withBanking / providers.length
                              : 0,
                          minHeight: 10,
                          backgroundColor:
                              Colors.black.withValues(alpha: 0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.blueAccent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                          providers.isNotEmpty
                              ? '${withBanking} of ${providers.length} providers ready for payout'
                              : 'No providers',
                          style: TextStyle(fontFamily: 'Manrope', 
                              fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Row 3: Payout Queue + Suspended Accounts Watchlist
  // -------------------------------------------------------------------------
  Widget _buildBottomRow(WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 900;
      return Flex(
        direction: isNarrow ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isNarrow
              ? _buildPayoutQueue(ref)
              : Expanded(flex: 3, child: _buildPayoutQueue(ref)),
          SizedBox(width: isNarrow ? 0 : 24, height: isNarrow ? 24 : 0),
          isNarrow
              ? _buildFraudWatchlist(ref)
              : Expanded(flex: 2, child: _buildFraudWatchlist(ref)),
        ],
      );
    });
  }

  Widget _buildPayoutQueue(WidgetRef ref) {
    final eligible = ref.watch(payoutEligibleProvidersProvider);
    final allAsync = ref.watch(allProfilesProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payout Queue',
                      style: TextStyle(fontFamily: 'Manrope', 
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('Verified providers ready for settlement',
                      style: TextStyle(fontFamily: 'Manrope', 
                          fontSize: 12, color: Colors.black45)),
                ],
              ),
              const Spacer(),
              if (allAsync.isLoading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${eligible.length} Eligible',
                      style: TextStyle(fontFamily: 'Manrope', 
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.green)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('PROVIDER',
                        style: TextStyle(fontFamily: 'Manrope', 
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black45,
                            letterSpacing: 0.5))),
                Expanded(
                    flex: 2,
                    child: Text('BANK',
                        style: TextStyle(fontFamily: 'Manrope', 
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black45,
                            letterSpacing: 0.5))),
                Expanded(
                    flex: 2,
                    child: Text('EARNINGS',
                        style: TextStyle(fontFamily: 'Manrope', 
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black45,
                            letterSpacing: 0.5))),
                SizedBox(
                    width: 90,
                    child: Text('STATUS',
                        style: TextStyle(fontFamily: 'Manrope', 
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black45,
                            letterSpacing: 0.5),
                        textAlign: TextAlign.right)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Builder(builder: (_) {
            if (allAsync.isLoading) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator()));
            }
            if (eligible.isEmpty) {
              return _buildEmptyState(
                  'No providers ready for payout',
                  'Providers need to be verified and have banking details set.',
                  Icons.account_balance_wallet_rounded);
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: eligible.take(8).length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
              itemBuilder: (context, i) {
                final p = eligible[i];
                final earnings = p.totalEarnings;
                final readyForPayout = earnings >= 1000;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: BoostDriveTheme.primaryColor
                                  .withValues(alpha: 0.1),
                              child: Text(
                                _initials(p.fullName),
                                style: TextStyle(fontFamily: 'Manrope', 
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: BoostDriveTheme.primaryColor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.fullName,
                                      style: TextStyle(fontFamily: 'Manrope', 
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87),
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                      _humanizeCategory(
                                          p.primaryServiceCategory ?? ''),
                                      style: TextStyle(fontFamily: 'Manrope', 
                                          fontSize: 11,
                                          color: Colors.black45)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.bankName ?? '—',
                                style: TextStyle(fontFamily: 'Manrope', 
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                                overflow: TextOverflow.ellipsis),
                            if (p.bankAccountNumber != null &&
                                p.bankAccountNumber!.isNotEmpty)
                              Text(
                                  '****${p.bankAccountNumber!.length > 4 ? p.bankAccountNumber!.substring(p.bankAccountNumber!.length - 4) : p.bankAccountNumber}',
                                  style: TextStyle(fontFamily: 'Manrope', 
                                      fontSize: 10, color: Colors.black38)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatNAD(earnings),
                          style: TextStyle(fontFamily: 'Manrope', 
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: readyForPayout
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              readyForPayout ? 'READY' : 'PENDING',
                              style: TextStyle(fontFamily: 'Manrope', 
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: readyForPayout
                                      ? Colors.green
                                      : Colors.black45,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFraudWatchlist(WidgetRef ref) {
    final suspended = ref.watch(suspendedAccountsProvider);
    final volumeAsync = ref.watch(globalVolumeProvider);

    return Column(
      children: [
        // Net Revenue snapshot
        volumeAsync.when(
          data: (vol) {
            final commission = vol * _commissionRate;
            final opex = 0.0; // Manual add when billing connected
            final netRevenue = commission - opex;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BoostDriveTheme.primaryColor,
                    BoostDriveTheme.primaryColor.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Net Revenue',
                      style: TextStyle(fontFamily: 'Manrope', 
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Text(_formatNAD(netRevenue),
                      style: TextStyle(fontFamily: 'Manrope', 
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPillStat(
                          'GMV', _formatNAD(vol), Colors.white30),
                      const SizedBox(width: 8),
                      _buildPillStat('Commission',
                          _formatNAD(commission), Colors.white30),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text('OpEx not yet connected',
                          style: TextStyle(fontFamily: 'Manrope', 
                              fontSize: 10, color: Colors.white54)),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => Container(
            height: 160,
            decoration: BoxDecoration(
              color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(),
        ),
        const SizedBox(height: 24),
        // Suspended account watchlist
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Text('Fraud Watchlist',
                      style: TextStyle(fontFamily: 'Manrope', 
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Suspended / flagged accounts',
                  style: TextStyle(fontFamily: 'Manrope', 
                      fontSize: 12, color: Colors.black45)),
              const SizedBox(height: 20),
              Builder(builder: (_) {
                if (suspended.isEmpty) {
                  return _buildEmptyState(
                      'No flagged accounts',
                      'Suspended accounts will appear here for monitoring.',
                      Icons.check_circle_outline_rounded);
                }
                return Column(
                  children: suspended.take(6).map((a) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                Colors.redAccent.withValues(alpha: 0.1),
                            child: Text(
                              _initials(a.fullName),
                              style: TextStyle(fontFamily: 'Manrope', 
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.redAccent),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.fullName,
                                    style: TextStyle(fontFamily: 'Manrope', 
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87),
                                    overflow: TextOverflow.ellipsis),
                                if (a.suspensionReason != null &&
                                    a.suspensionReason!.isNotEmpty)
                                  Text(a.suspensionReason!,
                                      style: TextStyle(fontFamily: 'Manrope', 
                                          fontSize: 11,
                                          color: Colors.black45),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)
                                else
                                  Text('No reason provided',
                                      style: TextStyle(fontFamily: 'Manrope', 
                                          fontSize: 11,
                                          color: Colors.black38,
                                          fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              a.status.toUpperCase(),
                              style: TextStyle(fontFamily: 'Manrope', 
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.redAccent,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------
  Widget _buildStatRow(
      String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style:
                  TextStyle(fontFamily: 'Manrope', fontSize: 13, color: Colors.black54)),
        ),
        Text(value,
            style: TextStyle(fontFamily: 'Manrope', 
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
      ],
    );
  }

  Widget _buildPillStat(String label, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text('$label $value',
          style: TextStyle(fontFamily: 'Manrope', 
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }

  Widget _buildEmptyState(String title, String sub, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.black12),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(fontFamily: 'Manrope', 
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black45)),
            const SizedBox(height: 4),
            Text(sub,
                style:
                    TextStyle(fontFamily: 'Manrope', fontSize: 11, color: Colors.black38),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _formatNAD(double v) {
    final fmt = NumberFormat('#,##0', 'en_US');
    return 'N\$${fmt.format(v)}';
  }

  String _humanizeCategory(String cat) {
    if (cat.isEmpty) return 'Unknown';
    return cat
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
        .join(' ');
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:intl/intl.dart';

class AdminSosHubPage extends ConsumerStatefulWidget {
  const AdminSosHubPage({super.key});

  @override
  ConsumerState<AdminSosHubPage> createState() => _AdminSosHubPageState();
}

class _AdminSosHubPageState extends ConsumerState<AdminSosHubPage> {
  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      showBackground: true,
      appBar: AppBar(
        title: const Text('SOS HUB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
              _buildSystemHealthMap(ref),
              const SizedBox(height: 32),
              const Text(
                'LIVE REQUEST FEED',
                style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              _buildSosFeed(ref),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemHealthMap(WidgetRef ref) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        image: const DecorationImage(
          image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBmoIr6BNhyne0XHfn3L2EvhS-V9bsoFgFlGNJMtKLZKjMGTfR_McAS2dcIAl3M3dtfm40uzT2zyyj-H4QD3G2WSNQgcWoFgEcGMzQ-01ad_Quuky5HzJP5bnqbeuhWHVOPwzvgZ8ctG8i779MeULOmRxgGxEbSXs2kzFQA_p2bOnC3fGSka5eI8hBpkZGE1ShSpNasZftXZa21yReRcqOEyKgeHPLx-_JNj-gN_NA8cbhIXTXnQiDox5RT2giEQjYNUg3347VVXO4'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, BoostDriveTheme.backgroundDark.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: StreamBuilder<List<SosRequest>>(
              stream: ref.watch(sosServiceProvider).getGlobalActiveRequests(),
              builder: (context, snapshot) => Row(
                children: [
                  _buildMapBadge('SOS ACTIVE: ${snapshot.data?.length ?? 0}', Colors.red),
                  const SizedBox(width: 8),
                  _buildMapBadge('DRIVERS: ONLINE', BoostDriveTheme.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSosFeed(WidgetRef ref) {
    // Note: getGlobalActiveRequests only returns 'pending' status.
    // If we want all active and assigned we might need a custom stream, but pending is the most urgent.
    return StreamBuilder<List<SosRequest>>(
      stream: ref.watch(sosServiceProvider).getGlobalActiveRequests(),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, color: BoostDriveTheme.textDim, size: 48),
                  const SizedBox(height: 16),
                  Text('All Clear', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16)),
                  Text('No active SOS requests at the moment.', style: TextStyle(color: BoostDriveTheme.textDim.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
          );
        }
        return Column(
          children: requests.map((req) => _buildSosCard(req)).toList(),
        );
      },
    );
  }

  Widget _buildSosCard(SosRequest req) {
    final bool isEmergency = req.type.toLowerCase() == 'emergency';
    final Color tagColor = isEmergency ? Colors.redAccent : Colors.orange;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tagColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('TYPE: ${req.type.toUpperCase()}', style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
              Text(
                DateFormat.Hm().format(req.createdAt),
                style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            req.userNote.isNotEmpty ? req.userNote : 'No details provided.',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'User ID: ${req.userId.substring(0, 8)}',
            style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Admin can cancel request
                    ref.read(sosServiceProvider).cancelRequest(req.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.2),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('CANCEL'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

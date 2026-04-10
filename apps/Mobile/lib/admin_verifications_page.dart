import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:intl/intl.dart';

class AdminVerificationsPage extends ConsumerStatefulWidget {
  const AdminVerificationsPage({super.key});

  @override
  ConsumerState<AdminVerificationsPage> createState() => _AdminVerificationsPageState();
}

class _AdminVerificationsPageState extends ConsumerState<AdminVerificationsPage> {
  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      showBackground: true,
      appBar: AppBar(
        title: const Text('VERIFICATIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
              _buildVerificationList(ref),
              const SizedBox(height: 32),
              _buildPendingListings(ref),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationList(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PENDING PROVIDERS',
          style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<UserProfile>>(
          stream: ref.watch(userServiceProvider).getPendingVerifications(),
          builder: (context, snapshot) {
            final pendings = snapshot.data ?? [];
            if (pendings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Center(child: Text('No pending verifications.', style: TextStyle(color: BoostDriveTheme.textDim))),
              );
            }
            return Column(
              children: pendings.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildVerificationCard(p),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVerificationCard(UserProfile profile) {
    final title = profile.fullName;
    final subtitle = 'Applied: recently • ${profile.role.toUpperCase()}';
    final icon = profile.role == 'service_pro' ? Icons.build : Icons.store;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white24, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final adminUid = ref.read(currentUserProvider)?.id ?? '';
              await ref.read(userServiceProvider).updateVerificationStatus(
                uid: profile.uid,
                status: 'approved',
                adminUid: adminUid,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${profile.fullName} approved.')));
              }
            },
            child: _buildActionButton(Icons.check, Colors.green),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final adminUid = ref.read(currentUserProvider)?.id ?? '';
              await ref.read(userServiceProvider).updateVerificationStatus(
                uid: profile.uid,
                status: 'rejected',
                adminUid: adminUid,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${profile.fullName} rejected.')));
              }
            },
            child: _buildActionButton(Icons.close, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingListings(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PENDING LISTINGS',
          style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Product>>(
          stream: ref.watch(productServiceProvider).streamPendingListings(),
          builder: (context, snapshot) {
            final listings = snapshot.data ?? [];
            if (listings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Center(child: Text('No pending listings.', style: TextStyle(color: BoostDriveTheme.textDim))),
              );
            }
            return Column(
              children: listings.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildListingCard(p),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildListingCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BoostDriveTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  image: product.imageUrls.isNotEmpty 
                    ? DecorationImage(image: NetworkImage(product.imageUrls.first), fit: BoxFit.cover)
                    : null,
                ),
                child: product.imageUrls.isEmpty ? const Icon(Icons.image, color: Colors.white24, size: 24) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('N\$${product.price.toStringAsFixed(2)} • ${product.category.toUpperCase()}', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await ref.read(productServiceProvider).updateListingStatus(product.id, 'available');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing approved.')));
                  }
                },
                child: _buildActionButton(Icons.check, Colors.green),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  await ref.read(productServiceProvider).updateListingStatus(product.id, 'rejected', rejectionReason: 'Admin rejected from mobile app.');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing rejected.')));
                  }
                },
                child: _buildActionButton(Icons.close, Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      height: 32,
      width: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

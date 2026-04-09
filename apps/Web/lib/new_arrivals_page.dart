import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boost_drive_web/product_detail_page.dart';

class NewArrivalsPage extends ConsumerStatefulWidget {
  const NewArrivalsPage({super.key});

  @override
  ConsumerState<NewArrivalsPage> createState() => _NewArrivalsPageState();
}

class _NewArrivalsPageState extends ConsumerState<NewArrivalsPage> {
  late Future<List<Product>> _newArrivalsFuture;

  @override
  void initState() {
    super.initState();
    _newArrivalsFuture = ref.read(productServiceProvider).getNewArrivals();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'New Arrivals',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fresh off the lot.',
              style: TextStyle(
                fontSize: 24,
                color: BoostDriveTheme.textDim,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Listings added in the last 24 hours.',
              style: TextStyle(
                fontSize: 16,
                color: BoostDriveTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            FutureBuilder<List<Product>>(
              future: _newArrivalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading new arrivals: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_off_outlined, size: 80, color: Color(0x22FF6600)),
                        const SizedBox(height: 24),
                        Text(
                          'No new listings yet today.',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white54),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Check back later or browse our full collection.',
                          style: TextStyle(color: BoostDriveTheme.textDim),
                        ),
                      ],
                    ),
                  );
                }

                final products = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 450,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => BoostProductCard(
                    product: products[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailPage(product: products[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

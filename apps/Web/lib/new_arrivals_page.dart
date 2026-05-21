import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boost_drive_web/public_page_frame.dart';
import 'package:boost_drive_web/public_page_widgets.dart';
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
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PublicPageFrame(
      activeRoute: '/new-arrivals',
      child: ColoredBox(
        color: palette.pageBackground,
        child: PublicPageContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: palette.primary, width: 8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Arrivals',
                        style: TextStyle(
                          fontSize: isMobile ? 36 : 48,
                          fontWeight: FontWeight.w800,
                          color: palette.titleColor,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fresh off the lot. Listings added in the last 24 hours.',
                        style: TextStyle(fontSize: 18, color: palette.bodyColor, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                PublicPageSection(
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FilterBar(palette: palette),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _FilterBar(palette: palette)),
                          ],
                        ),
                ),
                const SizedBox(height: 32),
                FutureBuilder<List<Product>>(
                  future: _newArrivalsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return const PublicFeedbackState(
                        icon: Icons.error_outline,
                        title: 'Could not load new arrivals',
                        message: 'Please try again in a moment.',
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const PublicFeedbackState(
                        icon: Icons.timer_off_outlined,
                        title: 'No new listings yet today.',
                        message: 'Check back later or browse our full collection.',
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
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final PublicPagePalette palette;

  const _FilterBar({required this.palette});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'LIVE NOW',
                  style: TextStyle(
                    color: palette.onPrimaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Showing new listings from Namibia',
                style: TextStyle(color: palette.bodyColor, fontSize: 15),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.titleColor,
              side: BorderSide(color: palette.borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            icon: Icon(Icons.filter_list, size: 18, color: palette.titleColor),
            label: const Text('Sort by Recent', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}

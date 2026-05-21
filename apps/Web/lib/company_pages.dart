import 'package:flutter/material.dart';
import 'package:boost_drive_web/public_page_frame.dart';
import 'package:boost_drive_web/public_page_widgets.dart';
import 'package:boost_drive_web/all_listings_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _heroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCcGXedXa3Q-DXy5v4xsA6kah-Vhp3G4kdjVdqddygUZtExGrIEjtUyZ9dl_wBzIle3OUvvLSi-NCyLCoeJyyfksjb0b_m0Xl9fNbFGp1rUjI4XoaDKqoRzWyJiHTsYxlaoY4qdXHbxBgyJJmCEga_CcAxTUepoRxTveq2_tFGgjPL3rqcyN7DHuMWM1obA4kAAz24i24ivXcz0Vz9i3hdh1qFSw10gUJe7RpgKZCSkS6SFB0fERYxPClJzg8POeQA8QEYjZmTSwKc';
  static const _workshopImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDGcRA391ke1G8izZuNyxgCYnlJQtYWsWuJk2r16Qzo_JqO4pOX_PELZsTuvnmpB8qaeL0tiE7t4c06TzfeJ9_Q8Cu-TFxS-EpkOLwISMOEXRB-O-SfUWpa4N45V4lO7bcpK-p0QB8IYRGRDJxuw_OYtGt3EQrmxRBFnnWVqtgBA0Cw3u-1_fntC2w8x9rDrSgj8gDtMVyPO77-3LceQlPOpDEjM4-lW_ItIKH5n1HEnA-rhJ2Gys85SRg3GO6mmJ1IgE8eHOrRwDE';

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PublicPageFrame(
      activeRoute: '/about',
      child: ColoredBox(
        color: palette.pageBackground,
        child: PublicPageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PublicSplitSection(
                imageFirstOnMobile: true,
                leading: PublicPageTitle(
                  title: 'About BoostDrive',
                  subtitle:
                      'BoostDrive is Namibia\'s premium automotive marketplace — connecting buyers, sellers, renters, and service providers in one polished destination.',
                  trailing: PublicPrimaryButton(
                    label: 'Learn More',
                    onPressed: () {},
                  ),
                ),
                trailing: PublicNetworkImage(imageUrl: _heroImage),
              ),
              const SizedBox(height: 36),
              isMobile
                  ? Column(
                      children: const [
                        PublicStatCard(label: 'Active Users', value: '5K+'),
                        SizedBox(height: 12),
                        PublicStatCard(label: 'Vehicles Listed', value: '1.2K'),
                        SizedBox(height: 12),
                        PublicStatCard(label: 'Support', value: '24/7'),
                      ],
                    )
                  : const Row(
                      children: [
                        Expanded(child: PublicStatCard(label: 'Active Users', value: '5K+')),
                        SizedBox(width: 16),
                        Expanded(child: PublicStatCard(label: 'Vehicles Listed', value: '1.2K')),
                        SizedBox(width: 16),
                        Expanded(child: PublicStatCard(label: 'Support', value: '24/7')),
                      ],
                    ),
              const SizedBox(height: 40),
              PublicSplitSection(
                leading: PublicPageSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PublicSectionHeading(
                        title: 'Precision & Performance',
                        subtitle: 'Built for drivers, owners, and providers across Namibia.',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Our mission is to create a platform that fosters growth and momentum for drivers while delivering exceptional service to passengers. With BoostDrive, users can easily discover vehicles, parts, rentals, and verified providers.',
                        style: TextStyle(color: palette.bodyColor, height: 1.7, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                trailing: PublicNetworkImage(imageUrl: _workshopImage, aspectRatio: 16 / 10),
              ),
              const SizedBox(height: 36),
              PublicOrangeBand(
                title: 'Find Your Next Drive',
                body:
                    'Discover how BoostDrive can help you buy, sell, rent, and connect with trusted automotive providers across Namibia.',
                child: PublicPrimaryButton(
                  label: 'View Products',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllListingsPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 36),
              const _TrainingSection(),
              const SizedBox(height: 36),
              const _AboutPageContactSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const _heroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCfH9vS91k2jWUtQHz8ljjEv3Vrfp-R0tFKGejkWKXNFarNIkW9XUAd6CAm3kXCx5woFoJnAFj6x5Sz4AOSEieNzzvXdblK-HDmSinRfMTB9pn26qVtc7JMyGWwwCDI4hQuNnLNbN_KQvasLXizj8fDVBvqSbtDleJ7GsExqabjDZDSgEIQ7aIaoPS76vz9stwyts3TDbuQbByRo1ThbGVAV1R7kBoujrB8Wh-0_cQaJSqpzXGJT2BQQM-62bBIEDmkmVJJ175KJNg';

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);

    return PublicPageFrame(
      activeRoute: '/contact',
      child: ColoredBox(
        color: palette.pageBackground,
        child: Column(
          children: [
            PublicPageContainer(
              child: PublicSplitSection(
                imageFirstOnMobile: false,
                leading: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    PublicPageTitle(
                      title: 'Contact Us',
                      subtitle: 'Get in touch with BoostDrive for support, partnerships, or general enquiries.',
                    ),
                    SizedBox(height: 24),
                    _ContactFormPanel(),
                  ],
                ),
                trailing: PublicNetworkImage(imageUrl: _heroImage, aspectRatio: 3 / 4),
              ),
            ),
            Container(
              width: double.infinity,
              color: palette.primary,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              child: PublicPageContainer(
                maxWidth: 1100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Head Office',
                      style: TextStyle(
                        color: palette.onPrimaryContainer,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'info@boostdrive.shop\n+264 81 645 0665',
                      style: TextStyle(
                        color: palette.onPrimaryContainer.withValues(alpha: 0.92),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Maerua Mall\nCnr of Jan Jonker and Centaurus Road\nWindhoek, Namibia',
                      style: TextStyle(
                        color: palette.onPrimaryContainer.withValues(alpha: 0.92),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.facebook, color: palette.onPrimaryContainer),
                        const SizedBox(width: 16),
                        Icon(Icons.camera_alt_outlined, color: palette.onPrimaryContainer),
                        const SizedBox(width: 16),
                        Icon(Icons.alternate_email, color: palette.onPrimaryContainer),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CareersPage extends StatelessWidget {
  const CareersPage({super.key});

  static const _heroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBuhULECkqn2VpojQRh4Uve238Zs8y6SjtzICxOYrkT2AY9a65rkY5ojva2SZd6S3_YE07fjaV0_wkRMKoQjd0EfAh2mmfVw0_izFos759jN0sIMD7eFMVxt3ELCU0kHWG1wfCjW9oVHct93etNg3u5LRBdOgpbza_oGbG8rEmMsN81z7wMI0M37xBF4O4f6aChcGfQ0ALhiWgyx99RmgDElvz2ah0KO4QPr87h05Ty2qU4ZUB8VfyXZpTuGE5TdGSCwulptLMJnzQ';

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PublicPageFrame(
      activeRoute: '/careers',
      child: ColoredBox(
        color: palette.pageBackground,
        child: PublicPageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PublicHeroBanner(
                eyebrow: 'Careers',
                title: 'Join Our Team',
                subtitle: 'We are always looking for passionate engineers, designers, and automotive enthusiasts to join our remote-first team.',
                imageUrl: _heroImage,
              ),
              const SizedBox(height: 32),
              isMobile
                  ? Column(
                      children: const [
                        PublicFeatureCard(
                          icon: Icons.rocket_launch_outlined,
                          title: 'Build the Future',
                          body: 'Help redefine mobility and marketplace experiences across Namibia.',
                        ),
                        SizedBox(height: 12),
                        PublicFeatureCard(
                          icon: Icons.favorite_outline,
                          title: 'Culture First',
                          body: 'Remote-friendly, collaborative, and driven by automotive excellence.',
                          highlighted: true,
                        ),
                        SizedBox(height: 12),
                        PublicFeatureCard(
                          icon: Icons.groups_outlined,
                          title: 'Community',
                          body: 'Work with a team that cares about drivers, owners, and buyers alike.',
                        ),
                      ],
                    )
                  : Row(
                      children: const [
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.rocket_launch_outlined,
                            title: 'Build the Future',
                            body: 'Help redefine mobility across Namibia.',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.favorite_outline,
                            title: 'Culture First',
                            body: 'Remote-friendly and collaborative.',
                            highlighted: true,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.groups_outlined,
                            title: 'Community',
                            body: 'A team that cares about every user.',
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 28),
              PublicPageSection(
                child: Column(
                  children: [
                    Icon(Icons.work_outline, size: 48, color: palette.mutedColor),
                    const SizedBox(height: 16),
                    Text(
                      'No Current Openings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: palette.titleColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We don\'t have any open positions at the moment. Please check back later or follow us on social media for updates.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.bodyColor, height: 1.55),
                    ),
                    const SizedBox(height: 20),
                    const _CareersNotifyForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PartnerProgramPage extends StatelessWidget {
  const PartnerProgramPage({super.key});

  static const _heroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCK9p6BZQTiXXcvBQCxCK_EAQqFAGeM-DSVG18QCojMIsCSdakgapVeQrU-i9ddKGzZ8jRYRGodYD82A3RuCK2YGh5dulORM56xz6pHn-32dVy3KzCktyJeXJ84EY229fn61MuDXGrIs189PECBbXYKZ8b66tqUPLhB5NYLXv0uZc-xuZx5H321O-VEpVD-fs0uSiBXw1HiXpO0opVJ7v2hrbmF_mSj6fu_0C70I8exW_zMx0i9prQUXoEsF6mr58zJkBzBPoyQbMg';

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PublicPageFrame(
      activeRoute: '/partner-program',
      child: ColoredBox(
        color: palette.pageBackground,
        child: PublicPageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PublicSplitSection(
                leading: PublicPageTitle(
                  eyebrow: 'Partner Program',
                  title: 'Grow with BoostDrive',
                  subtitle:
                      'For dealerships, rental agencies, and parts suppliers. Integrate your inventory directly with our platform and reach thousands of verified customers.',
                ),
                trailing: PublicNetworkImage(imageUrl: _heroImage),
              ),
              const SizedBox(height: 32),
              isMobile
                  ? Column(
                      children: const [
                        PublicFeatureCard(
                          icon: Icons.public,
                          title: 'Unified Market Reach',
                          body: 'Expose your inventory to buyers across Namibia through one premium channel.',
                        ),
                        SizedBox(height: 12),
                        PublicFeatureCard(
                          icon: Icons.verified_outlined,
                          title: 'Certified Quality',
                          body: 'Partner listings benefit from trust signals and marketplace visibility.',
                          highlighted: true,
                        ),
                        SizedBox(height: 12),
                        PublicFeatureCard(
                          icon: Icons.insights_outlined,
                          title: 'Deep Analytics',
                          body: 'Understand performance with listing views and engagement insights.',
                        ),
                      ],
                    )
                  : Row(
                      children: const [
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.public,
                            title: 'Unified Market Reach',
                            body: 'Expose your inventory across Namibia.',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.verified_outlined,
                            title: 'Certified Quality',
                            body: 'Trust signals and premium visibility.',
                            highlighted: true,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.insights_outlined,
                            title: 'Deep Analytics',
                            body: 'Listing views and engagement insights.',
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 28),
              isMobile
                  ? Column(
                      children: const [
                        PublicStatCard(label: 'Active Partners', value: '150+'),
                        SizedBox(height: 12),
                        PublicStatCard(label: 'Parts Listed', value: '12k'),
                        SizedBox(height: 12),
                        PublicStatCard(label: 'Retention', value: '98%'),
                      ],
                    )
                  : const Row(
                      children: [
                        Expanded(child: PublicStatCard(label: 'Active Partners', value: '150+')),
                        SizedBox(width: 12),
                        Expanded(child: PublicStatCard(label: 'Parts Listed', value: '12k')),
                        SizedBox(width: 12),
                        Expanded(child: PublicStatCard(label: 'Retention', value: '98%')),
                      ],
                    ),
              const SizedBox(height: 28),
              Center(
                child: PublicPrimaryButton(
                  label: 'Apply for Partnership',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: palette.cardBackground,
                        title: Text('Coming Soon', style: TextStyle(color: palette.titleColor)),
                        content: Text(
                          'The Partner Portal is currently invitation-only. Please contact support to request early access.',
                          style: TextStyle(color: palette.bodyColor),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactFormPanel extends StatefulWidget {
  const _ContactFormPanel();

  @override
  State<_ContactFormPanel> createState() => _ContactFormPanelState();
}

class _ContactFormPanelState extends State<_ContactFormPanel> {
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDeco(BuildContext context, String placeholder) {
    final palette = PublicPagePalette.of(context);
    return InputDecoration(
      hintText: placeholder,
      filled: true,
      fillColor: palette.fieldBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _label(BuildContext context, String text) {
    final palette = PublicPagePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: palette.titleColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context, 'Name*'),
          TextField(controller: _nameController, decoration: _fieldDeco(context, 'Your name')),
          const SizedBox(height: 14),
          _label(context, 'Last name'),
          TextField(controller: _lastNameController, decoration: _fieldDeco(context, 'Your last name')),
          const SizedBox(height: 14),
          _label(context, 'Your email*'),
          TextField(controller: _emailController, decoration: _fieldDeco(context, 'Your email address')),
          const SizedBox(height: 14),
          _label(context, 'Message*'),
          TextField(
            controller: _messageController,
            minLines: 4,
            maxLines: 5,
            decoration: _fieldDeco(context, 'Enter your message'),
          ),
          const SizedBox(height: 18),
          PublicPrimaryButton(
            label: 'Send Message',
            expanded: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted')));
            },
          ),
        ],
      ),
    );
  }
}

class _CareersNotifyForm extends StatefulWidget {
  const _CareersNotifyForm();

  @override
  State<_CareersNotifyForm> createState() => _CareersNotifyFormState();
}

class _CareersNotifyFormState extends State<_CareersNotifyForm> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Email for job alerts',
              filled: true,
              fillColor: palette.fieldBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        PublicPrimaryButton(
          label: 'Notify Me',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscribed')));
          },
        ),
      ],
    );
  }
}

class _TrainingSection extends StatelessWidget {
  const _TrainingSection();

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    return PublicSplitSection(
      leading: PublicPageSection(
        child: Text(
          'Through BoostDrive, drivers can benefit from fast and convenient follow-up and training services. '
          'Sessions cover customer service, navigation, and passenger safety to help providers deliver a better experience.',
          style: TextStyle(color: palette.bodyColor, height: 1.7, fontSize: 15),
        ),
      ),
      trailing: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset('images/steering_wheel.jpg', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _AboutPageContactSection extends StatelessWidget {
  const _AboutPageContactSection();

  @override
  Widget build(BuildContext context) {
    return PublicSplitSection(
      imageFirstOnMobile: true,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.asset('images/driving_a_car.jpg', fit: BoxFit.cover),
        ),
      ),
      trailing: const _ContactFormPanel(),
    );
  }
}

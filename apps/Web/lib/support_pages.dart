import 'package:flutter/material.dart';
import 'package:boost_drive_web/public_page_frame.dart';
import 'package:boost_drive_web/public_page_widgets.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

class SafetyCenterPage extends StatelessWidget {
  const SafetyCenterPage({super.key});

  static const _heroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBXYXmDh2eMF6ugDVywLrDKuOMRm-1D9eMLVxpKx0UI3p37Zziq1zwq23tteUc_2IuwT1I6JswZUwJag2GcDY-VTmyjkBfjLqcVzgHXmcXGimakopxtqnedjg5ms__KDnSBFAD_TUdKavoYmaTe6-OBnONOhP8a8Heo6xBtVmz-asJDLxE5sflsINvQ8tLdCW1tvpiyTQ6GnESdH8mH8lbmn144rNQeUobVuUlpZR0jLZJuoT7c0zixK9UP0C0K75ikuRBNzCTyIao';

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PublicPageFrame(
      activeRoute: '/safety',
      child: ColoredBox(
        color: palette.pageBackground,
        child: PublicPageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PublicHeroBanner(
                eyebrow: 'Safety Center',
                title: 'Buy and sell with confidence',
                subtitle: 'Practical guidance to help you stay safe across every BoostDrive transaction.',
                imageUrl: _heroImage,
              ),
              const SizedBox(height: 32),
              isMobile
                  ? Column(
                      children: const [
                        PublicFeatureCard(
                          icon: Icons.verified_user_outlined,
                          title: 'Verify Before You Buy',
                          body: 'Always inspect the vehicle or part in person before making any payments. Use our messaging system to ask detailed questions.',
                        ),
                        SizedBox(height: 16),
                        PublicFeatureCard(
                          icon: Icons.chat_bubble_outline,
                          title: 'Keep Chat on BoostDrive',
                          body: 'Never share personal financial information or move conversations to other platforms. Our in-app chat is secure and monitored.',
                          highlighted: true,
                        ),
                        SizedBox(height: 16),
                        PublicFeatureCard(
                          icon: Icons.warning_amber_rounded,
                          title: 'Spotting Scams',
                          body: 'Be wary of sellers asking for deposits without viewing the item, or prices that seem too good to be true.',
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.verified_user_outlined,
                            title: 'Verify Before You Buy',
                            body: 'Always inspect the vehicle or part in person before making any payments.',
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.chat_bubble_outline,
                            title: 'Keep Chat on BoostDrive',
                            body: 'Never share personal financial information or move conversations to other platforms.',
                            highlighted: true,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.warning_amber_rounded,
                            title: 'Spotting Scams',
                            body: 'Be wary of sellers asking for deposits without viewing the item.',
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 28),
              PublicOrangeBand(
                title: 'Emergency Assistance',
                body: 'If you are in immediate danger, please call 112 or local authorities immediately.',
                child: Row(
                  children: [
                    Icon(Icons.local_police_outlined, color: palette.onPrimaryContainer),
                    const SizedBox(width: 10),
                    Text(
                      'Police 10111  •  Ambulance 211 111',
                      style: TextStyle(
                        color: palette.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const _heroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCqRlcd-GKnXKOH9csvsZtHgeUGMp11giD4cx2sRpVGLhl5QZuARAhMXaNjJNk2PNtf4upWxpHKGPup_I2LBJOTUNXa9EyGwsIVYy4XYXAOOhkG1xl6QK9frZm_gkBddnC4_IIix3kd3SWbQPw6i5gzSuwVtPKey1rf7A2myuJ1IT46h6sY87I8AXAZXBD3TAvgnnfLilYtuKPBwqlCJ-j1WsWnwyow08XbU7R64FdvoUsZ2T0tcE4ZnPIhllBpcrAS8gcCOwjoKbI';

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);

    return PublicPageFrame(
      activeRoute: '/terms',
      child: ColoredBox(
        color: palette.pageBackground,
        child: PublicPageContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PublicPageTitle(
                title: 'Terms of Service',
                subtitle: 'Last Updated: February 2026',
              ),
              const SizedBox(height: 28),
              PublicNetworkImage(imageUrl: _heroImage, aspectRatio: 21 / 9),
              const SizedBox(height: 32),
              const PublicLegalSection(
                index: 1,
                title: 'Acceptance of Terms',
                body: 'By accessing and using BoostDrive, you accept and agree to be bound by the terms and provision of this agreement.',
              ),
              const PublicLegalSection(
                index: 2,
                title: 'Use License',
                body: 'Permission is granted to temporarily download one copy of the materials (information or software) on BoostDrive for personal, non-commercial transitory viewing only.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _heroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCFGsfbPiwiG2uZB3JVpAvyvIHYtqsNfsyKVOR9EkpXA5JvAdVsUhh9luSFPb9Z7yh03cfZLHM72KUbwS3v-YxzRyxCfDpGQqVKOG4Qz1YrRtjVQMa38bbckVJcJ-FPhWFXMBN_TR9iaYzkhbDVdDlbc8Vu97sC1hMf4oRj0YzVxageiMTESYjmEni7w6hzb0yaDo-DYh5_Idvlmty2BuzDpWY_BjkZ1EfMSRJAGyzmmZt1Ybn4oE0X24_IsS7-WcVvdV3wHNo2ouk';

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PublicPageFrame(
      activeRoute: '/privacy',
      child: ColoredBox(
        color: palette.pageBackground,
        child: PublicPageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PublicHeroBanner(
                eyebrow: 'Privacy Policy',
                title: 'Your privacy matters to us',
                subtitle: 'How we collect, use, and protect your information on BoostDrive.',
                imageUrl: _heroImage,
              ),
              const SizedBox(height: 32),
              PublicPageSection(
                child: const PublicLegalSection(
                  title: 'Introduction',
                  body: 'BoostDrive is committed to protecting your personal information and being transparent about how we use it across our marketplace and services.',
                ),
              ),
              const SizedBox(height: 20),
              PublicSectionHeading(
                title: 'Information We Collect',
                subtitle: 'Data you provide directly and data collected automatically when you use the platform.',
              ),
              const SizedBox(height: 16),
              isMobile
                  ? Column(
                      children: const [
                        PublicFeatureCard(
                          icon: Icons.person_outline,
                          title: 'Personal Information',
                          body: 'Name, email, phone number, and account details when you register or list items.',
                        ),
                        SizedBox(height: 12),
                        PublicFeatureCard(
                          icon: Icons.payments_outlined,
                          title: 'Transaction Data',
                          body: 'Booking, messaging, and listing activity related to your marketplace use.',
                        ),
                        SizedBox(height: 12),
                        PublicFeatureCard(
                          icon: Icons.devices_outlined,
                          title: 'Digital Footprint',
                          body: 'Device information, usage analytics, and cookies to improve platform performance.',
                        ),
                      ],
                    )
                  : Row(
                      children: const [
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.person_outline,
                            title: 'Personal Information',
                            body: 'Name, email, phone number, and account details.',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.payments_outlined,
                            title: 'Transaction Data',
                            body: 'Booking, messaging, and listing activity.',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: PublicFeatureCard(
                            icon: Icons.devices_outlined,
                            title: 'Digital Footprint',
                            body: 'Device information and usage analytics.',
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 28),
              PublicPageSection(
                child: const PublicLegalSection(
                  title: 'How We Use Your Information',
                  body: 'We use the information we collect to provide, maintain, and improve our services, to facilitate transactions, and to communicate with you about your account and listings.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static const _heroImage =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAAKE5mi7BvLhjS0Hv9MyhXh5NR6VruFBjPkmjL2tcZ3ALRYW3nVlnc1R-ONhmJERBy8rejVOyEgapwNU82qyT493w2--OJ5xvrBrrwNbVgZINXq-vOn7qVcex-h5lYjDmnVY0Ah-wkF7SUwTcYzorkayLCgTj4G8OfTSi1MXCKjipIk_-e3SrM3pMbr1S8oiv81te_tEksXYQr55lTbyqzwrj1x68XjjFcxKp3nFCKLvaC9Y9aJLndh0_XFYK97Pt1wSOEm3LS5I4';

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);

    return PublicPageFrame(
      activeRoute: '/faq',
      child: ColoredBox(
        color: palette.pageBackground,
        child: PublicPageContainer(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PublicHeroBanner(
                eyebrow: 'Support',
                title: 'Frequently Asked Questions',
                subtitle: 'Answers about buying, selling, renting, and using BoostDrive in Namibia.',
                imageUrl: _heroImage,
              ),
              const SizedBox(height: 28),
              const PublicFaqTile(
                question: 'How do I sell my car?',
                answer: 'Simply create an account, click "Sell your car", upload photos, and set your price. It takes less than 5 minutes!',
              ),
              const SizedBox(height: 12),
              const PublicFaqTile(
                question: 'Is it free to list?',
                answer: 'Basic listings are free for all personal users. Dealerships can upgrade to a Premium plan for enhanced visibility and bulk tools.',
              ),
              const SizedBox(height: 12),
              const PublicFaqTile(
                question: 'How does the rental process work?',
                answer: 'Browse available rentals, select your dates, and click "Rent Now". You\'ll need to confirm your booking with a payment to secure the vehicle.',
              ),
              const SizedBox(height: 12),
              const PublicFaqTile(
                question: 'Can I return a spare part?',
                answer: 'Return policies depend on the individual seller. We recommend discussing terms in the chat before purchasing.',
              ),
              const SizedBox(height: 28),
              PublicPageSection(
                child: Column(
                  children: [
                    Text(
                      'Still have questions?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.titleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our support team is ready to help with anything not covered here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.bodyColor, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    PublicPrimaryButton(label: 'Contact Support'),
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

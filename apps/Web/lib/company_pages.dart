import 'package:flutter/material.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'all_listings_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'About BoostDrive',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 900;
                    final aboutText = Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'About BoostDrive',
                            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'BoostDrive is a platform that provides comprehensive e-hailing and transport services. We empower drivers by maximizing their earnings and offer packages for both existing drivers and new individuals entering the e-hailing business.',
                            style: TextStyle(fontSize: 16, color: BoostDriveTheme.textDim, height: 1.7),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Our mission is to create a platform that fosters growth and momentum for drivers while delivering exceptional service to passengers. With BoostDrive, passengers can easily book trips, enjoy privacy, and have the option to book or rent a vehicle with a driver at their disposal.',
                            style: TextStyle(fontSize: 16, color: BoostDriveTheme.textDim, height: 1.7),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Our e-hailing and transport services consultancy is dedicated to empowering drivers and providing exceptional service to car owners. Our objective is to create a strong brand presence and contribute to the growth of the e-hailing ecosystem in Namibia.',
                            style: TextStyle(fontSize: 16, color: BoostDriveTheme.textDim, height: 1.7),
                          ),
                        ],
                      ),
                    );

                    final aboutImage = ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1489824904134-891ab64532f1?auto=format&fit=crop&w=1400&q=80',
                          fit: BoxFit.cover,
                        ),
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          aboutText,
                          const SizedBox(height: 24),
                          aboutImage,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: aboutText),
                        const SizedBox(width: 32),
                        Expanded(child: aboutImage),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                _PromoBanner(
                  onViewProducts: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllListingsPage()),
                    );
                  },
                ),
                const SizedBox(height: 40),
                const _TrainingSection(),
                const SizedBox(height: 40),
                const _ContactSection(),
                const SizedBox(height: 48),
                const Divider(color: Colors.white10),
                const SizedBox(height: 32),
                const _StatRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    const beige = Color(0xFFD9C2A3);
    const darkOrange = Color(0xFFC54A16);

    return PremiumPageLayout(
      title: 'Contact Us',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: beige,
            width: double.infinity,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 900;

                      const left = Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Us',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Get in touch with BoostDrive',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      );

                      const right = _ContactFormPanel();

                      if (isNarrow) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            left,
                            const SizedBox(height: 24),
                            right,
                          ],
                        );
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            flex: 4,
                            child: left,
                          ),
                          const SizedBox(width: 48),
                          const Expanded(
                            flex: 6,
                            child: right,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: darkOrange,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'Contact Address',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'info@boostdrive.shop',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '+264 81 645 0665',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.facebook, color: Colors.white, size: 22),
                              SizedBox(width: 12),
                              Icon(Icons.camera_alt, color: Colors.white, size: 22),
                              SizedBox(width: 12),
                              Icon(Icons.alternate_email, color: Colors.white, size: 22),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Maerua Mall',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cnr of Jan Jonker and Centaurus Road',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Windhoek',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Namibia',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  InputDecoration _fieldDeco(String placeholder) {
    return InputDecoration(
      hintText: placeholder,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Name*'),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.black),
          decoration: _fieldDeco('Your name'),
        ),
        const SizedBox(height: 12),
        _label('Last name'),
        TextField(
          controller: _lastNameController,
          style: const TextStyle(color: Colors.black),
          decoration: _fieldDeco('Your last name'),
        ),
        const SizedBox(height: 12),
        _label('Your email*'),
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.black),
          decoration: _fieldDeco('Your email address'),
        ),
        const SizedBox(height: 12),
        _label('Message*'),
        TextField(
          controller: _messageController,
          style: const TextStyle(color: Colors.black),
          minLines: 4,
          maxLines: 5,
          decoration: _fieldDeco('Enter your message'),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Submitted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB44A1E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            child: const Text('Submit'),
          ),
        ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final VoidCallback onViewProducts;
  const _PromoBanner({required this.onViewProducts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFD7C6A9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'Discover how BoostDrive can help you increase\nyour earnings and achieve financial success in the\ne-hailing business. Our comprehensive packages\nand tailored solutions are designed to empower\ndrivers and car owners in Namibia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onViewProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB44A1E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('View products'),
          ),
        ],
      ),
    );
  }
}

class _TrainingSection extends StatelessWidget {
  const _TrainingSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        final text = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: const Text(
            'Through BoostDrive E-hailing drivers can now benefit from fast and convenient follow-up and training services. This initiative aims to enhance their skills and improve their overall efficiency.\n\n'
            'With the increasing demand and competition in the e-hailing industry, it has become crucial for drivers to stay up-to-date with the latest techniques and regulations. Through this program, drivers can easily access follow-up sessions and training modules tailored specifically to their needs. These sessions cover a wide range of topics such as customer service, navigation, and passenger safety.\n\n'
            'By participating in these trainings, drivers can not only enhance their professionalism but also provide a better experience to their passengers. This initiative ultimately leads to increased customer satisfaction and improved business opportunities for e-hailing drivers.',
            style: TextStyle(fontSize: 16, color: BoostDriveTheme.textDim, height: 1.7),
          ),
        );

        final image = ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              'images/steering_wheel.jpg',
              fit: BoxFit.cover,
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              image,
              const SizedBox(height: 24),
              text,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: text),
            const SizedBox(width: 32),
            Expanded(child: image),
          ],
        );
      },
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    return const _ContactSectionBody();
  }
}

class _ContactSectionBody extends StatefulWidget {
  const _ContactSectionBody();

  @override
  State<_ContactSectionBody> createState() => _ContactSectionBodyState();
}

class _ContactSectionBodyState extends State<_ContactSectionBody> {
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

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFEAE3F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        final leftImage = ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.asset(
              'images/driving_a_car.jpg',
              fit: BoxFit.cover,
            ),
          ),
        );

        final form = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Contact Us', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 24),
              _fieldLabel('Name'),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: _deco('Your name'),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Last name'),
              TextField(
                controller: _lastNameController,
                style: const TextStyle(color: Colors.black),
                decoration: _deco('Your last name'),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Your email*'),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.black),
                decoration: _deco('Your email address'),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Message*'),
              TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.black),
                minLines: 4,
                maxLines: 6,
                decoration: _deco('Enter your message'),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Submitted')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB44A1E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftImage,
              const SizedBox(height: 24),
              form,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leftImage),
            const SizedBox(width: 32),
            Expanded(child: form),
          ],
        );
      },
    );
  }
}

class CareersPage extends StatelessWidget {
  const CareersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'Join Our Team',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.rocket_launch_outlined, size: 80, color: BoostDriveTheme.primaryColor),
                      const SizedBox(height: 32),
                      const Text(
                        'Build the Future of Mobility.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'We are always looking for passionate engineers, designers, and automotive enthusiasts to join our remote-first team.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: BoostDriveTheme.textDim, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(48),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.work_outline, size: 48, color: BoostDriveTheme.textDim),
                      SizedBox(height: 24),
                      Text(
                        'No Current Openings',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'We don\'t have any open positions at the moment. Please check back later or follow us on social media for updates.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: BoostDriveTheme.textDim, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PartnerProgramPage extends StatelessWidget {
  const PartnerProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      title: 'Partner Program',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: BoostDriveTheme.backgroundDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.handshake_outlined, size: 80, color: Colors.blueAccent),
                      const SizedBox(height: 32),
                      const Text(
                        'Grow with BoostDrive.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'For dealerships, rental agencies, and parts suppliers. Integrate your inventory directly with our platform and reach thousands of verified customers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: BoostDriveTheme.textDim, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: BoostDriveTheme.surfaceDark,
                        title: const Text('Coming Soon', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'The Partner Portal is currently invitation-only. Please contact support to request early access.',
                          style: TextStyle(color: BoostDriveTheme.textDim),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  ),
                  child: const Text('Apply for Partnership', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatItem(value: '5K+', label: 'Active Users'),
        _StatItem(value: '1.2K', label: 'Vehicles Listed'),
        _StatItem(value: '24/7', label: 'Support'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: BoostDriveTheme.primaryColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: BoostDriveTheme.textDim),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _JobListing extends StatelessWidget {
  final String title;
  final String location;

  const _JobListing({required this.title, required this.location});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(location, style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 14)),
          ],
        ),
        OutlinedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: BoostDriveTheme.surfaceDark,
                title: const Text('Coming Soon', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Our application portal is currently being updated. Please check back soon to apply for this role.',
                  style: TextStyle(color: BoostDriveTheme.textDim),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: BoostDriveTheme.primaryColor)),
                  ),
                ],
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

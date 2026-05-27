import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_palette.dart';
import 'dashboard_typography.dart';
import 'dashboard_theme_toggle.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  String? _selectedRole;
  bool _isLoading = false;

  Future<void> _saveRoles() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authStateProvider).value;
      final user = authState?.session?.user;
      if (user != null) {
        String roleStr = _selectedRole!.toLowerCase().replaceAll(' ', '_');
        final bool isBuyer = roleStr == 'customer';
        final bool isSeller = roleStr == 'seller';

        await ref.read(userServiceProvider).updateRoles(
          uid: user.id,
          isBuyer: isBuyer,
          isSeller: isSeller,
          role: roleStr,
        );
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving roles: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6600),
        foregroundColor: Colors.white,
        elevation: 2,
        title: Text(
          'BOOSTDRIVE',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          const DashboardThemeToggle(compact: true, onColoredHeader: true),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_pin_circle_outlined, size: 56, color: palette.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Choose Your Role',
                style: DashboardTypography.headlineLg(palette),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Select how you would like to use BoostDrive.',
                textAlign: TextAlign.center,
                style: DashboardTypography.bodyMd(palette).copyWith(color: palette.muted),
              ),
              const SizedBox(height: 40),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  _buildRoleCard(palette, 'Customer', 'Individuals looking to buy', Icons.person),
                  _buildRoleCard(palette, 'Seller', 'Parts sellers & shops', Icons.storefront_outlined),
                  _buildRoleCard(palette, 'Service Provider', 'Registered businesses', Icons.build_outlined),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveRoles,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6600),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'CONTINUE',
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(DashboardPalette palette, String title, String subtitle, IconData icon) {
    final isSelected = _selectedRole == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6600).withValues(alpha: 0.1)
              : palette.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6600) : palette.outlineVariant.withValues(alpha: 0.35),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: palette.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: palette.primary, size: 26),
            ),
            const Spacer(),
            Text(
              title,
              style: DashboardTypography.labelLg(palette).copyWith(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: DashboardTypography.bodySm(palette).copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

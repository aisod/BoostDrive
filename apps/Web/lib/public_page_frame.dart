import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boost_drive_web/dashboard_router.dart';
import 'package:boost_drive_web/public_top_nav_bar.dart';
import 'package:boost_drive_web/public_nav_drawer.dart';

class PublicPageFrame extends ConsumerStatefulWidget {
  final String activeRoute;
  final Widget child;
  final Widget? footer;

  const PublicPageFrame({
    super.key,
    required this.activeRoute,
    required this.child,
    this.footer = const AppFooter(),
  });

  @override
  ConsumerState<PublicPageFrame> createState() => _PublicPageFrameState();
}

class _PublicPageFrameState extends ConsumerState<PublicPageFrame> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openLoginDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _handleLoginSuccess() {
    handleWebLoginSuccess(
      context,
      ref,
      closeDrawer: () => _scaffoldKey.currentState?.closeEndDrawer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PremiumPageLayout(
      scaffoldKey: _scaffoldKey,
      drawer: isMobile
          ? PublicNavDrawer(
              activeRoute: widget.activeRoute,
              onAuthTap: _openLoginDrawer,
            )
          : null,
      appBar: BoostDrivePublicTopNavBar(
        activeRoute: widget.activeRoute,
        onAuthTap: _openLoginDrawer,
        scaffoldKey: _scaffoldKey,
      ),
      endDrawer: Drawer(
        width: isMobile ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.width * 0.46,
        backgroundColor: Colors.white,
        child: BoostLoginPage(
          onLoginSuccess: _handleLoginSuccess,
          onClose: () => _scaffoldKey.currentState?.closeEndDrawer(),
        ),
      ),
      footer: widget.footer,
      child: widget.child,
    );
  }
}

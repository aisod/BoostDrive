import 'package:flutter/material.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boost_drive_web/public_top_nav_bar.dart';

class PublicPageFrame extends StatefulWidget {
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
  State<PublicPageFrame> createState() => _PublicPageFrameState();
}

class _PublicPageFrameState extends State<PublicPageFrame> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openLoginDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PremiumPageLayout(
      scaffoldKey: _scaffoldKey,
      appBar: BoostDrivePublicTopNavBar(
        activeRoute: widget.activeRoute,
        onAuthTap: _openLoginDrawer,
      ),
      endDrawer: Drawer(
        width: isMobile ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.width * 0.46,
        backgroundColor: Colors.white,
        child: BoostLoginPage(
          onLoginSuccess: () => _scaffoldKey.currentState?.closeEndDrawer(),
          onClose: () => _scaffoldKey.currentState?.closeEndDrawer(),
        ),
      ),
      footer: widget.footer,
      child: widget.child,
    );
  }
}

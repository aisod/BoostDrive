import 'package:flutter/material.dart';
import 'theme.dart';

class PremiumPageLayout extends StatelessWidget {
  final Widget? child;
  final List<Widget>? slivers;
  final List<Widget>? headerSlivers;
  final Widget? appBar;
  final Widget? footer;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final bool showBackground;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  // Simplified AppBar properties for Sliver support
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;

  const PremiumPageLayout({
    super.key,
    this.child,
    this.slivers,
    this.headerSlivers,
    this.appBar,
    this.footer,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.showBackground = true,
    this.scaffoldKey,
    this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final bool useSlivers = slivers != null;
    final bool useNested = headerSlivers != null;
    
    // Background decoration is safer than a Stack for hit-testing on Web
    final BoxDecoration decoration = showBackground ? BoxDecoration(
      color: BoostDriveTheme.backgroundDark,
      image: const DecorationImage(
        image: AssetImage(
          BoostDriveTheme.globalBackgroundImage,
          package: 'boostdrive_ui',
        ),
        fit: BoxFit.cover,
      ),
    ) : const BoxDecoration(color: BoostDriveTheme.backgroundDark);

    Widget contentBody;
    
    if (useNested) {
      contentBody = NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            if (title != null || actions != null || leading != null)
              SliverAppBar(
                title: Text(
                  title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: actions,
                leading: leading,
                backgroundColor: BoostDriveTheme.backgroundDark.withValues(alpha: 0.5),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                floating: false,
                pinned: true,
                centerTitle: false,
              )
            else if (appBar != null)
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (appBar as PreferredSizeWidget).preferredSize.height + MediaQuery.of(context).padding.top,
                  ),
                  child: appBar,
                ),
              ),
            ...headerSlivers!,
          ];
        },
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            ...slivers!,
            if (footer != null) SliverToBoxAdapter(child: footer!),
          ],
        ),
      );
    } else if (useSlivers) {
      contentBody = CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (title != null || actions != null || leading != null)
            SliverAppBar(
              title: Text(
                title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: actions,
              leading: leading,
              backgroundColor: BoostDriveTheme.backgroundDark.withValues(alpha: 0.5),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              floating: false,
              pinned: true,
              centerTitle: false,
            )
          else if (appBar != null)
            SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (appBar as PreferredSizeWidget).preferredSize.height + MediaQuery.of(context).padding.top,
                ),
                child: appBar,
              ),
            ),
          ...slivers!,
          if (footer != null) SliverToBoxAdapter(child: footer!),
        ],
      );
    } else {
      contentBody = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (child != null) child!,
            if (footer != null) footer!,
          ],
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: BoostDriveTheme.backgroundDark,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      // Standard AppBar only if not using slivers/nested
      appBar: (!useSlivers && !useNested && appBar != null) ? (appBar as PreferredSizeWidget) : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: decoration,
        child: contentBody,
      ),
    );
  }
}

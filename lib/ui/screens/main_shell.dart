import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/app_background.dart';
import '../components/app_bottom_nav.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = ['/home', '/contracts', '/payments', '/profile'];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final showNav = _tabs.any((p) => location.startsWith(p)) &&
        location.split('/').length <= 2;
    final index = _indexFor(location);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(child: child),
      bottomNavigationBar: showNav
          ? AppBottomNav(
              currentIndex: index,
              onTap: (i) => context.go(_tabs[i]),
            )
          : null,
    );
  }
}

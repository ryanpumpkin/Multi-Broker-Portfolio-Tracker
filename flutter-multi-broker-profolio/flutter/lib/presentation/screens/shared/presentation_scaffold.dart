import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';

class PresentationScaffold extends StatelessWidget {
  const PresentationScaffold({
    required this.selectedRoute,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  final String selectedRoute;
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  static const List<_Destination> _destinations = <_Destination>[
    _Destination(AppRoutes.dashboard, 'Dashboard', Icons.dashboard_outlined),
    _Destination(AppRoutes.positions, 'Positions', Icons.stacked_line_chart),
    _Destination(AppRoutes.charts, 'Charts', Icons.show_chart),
    _Destination(AppRoutes.transactions, 'Transactions', Icons.receipt_long),
    _Destination(AppRoutes.connections, 'Connections', Icons.hub_outlined),
    _Destination(AppRoutes.alerts, 'Alerts', Icons.notifications_outlined),
    _Destination(AppRoutes.settings, 'Settings', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexFor(selectedRoute);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 700;
        return Scaffold(
          appBar: AppBar(title: Text(title), actions: actions),
          drawer: compact ? _NavDrawer(selectedRoute: selectedRoute) : null,
          body: compact
              ? body
              : Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      extended: width >= 1200,
                      onDestinationSelected: (index) {
                        context.go(_destinations[index].route);
                      },
                      destinations: _destinations
                          .map(
                            (d) => NavigationRailDestination(
                              icon: Icon(d.icon),
                              label: Text(d.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                ),
          bottomNavigationBar: compact
              ? BottomNavigationBar(
                  currentIndex: selectedIndex,
                  type: BottomNavigationBarType.fixed,
                  onTap: (index) => context.go(_destinations[index].route),
                  items: _destinations
                      .map(
                        (d) => BottomNavigationBarItem(
                          icon: Icon(d.icon),
                          label: d.label,
                        ),
                      )
                      .toList(growable: false),
                )
              : null,
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }

  static int _selectedIndexFor(String route) {
    final index = _destinations.indexWhere((d) => route.startsWith(d.route));
    return index < 0 ? 0 : index;
  }
}

class _NavDrawer extends StatelessWidget {
  const _NavDrawer({required this.selectedRoute});

  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = PresentationScaffold._selectedIndexFor(selectedRoute);
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(child: Text('Portfolio Tracker')),
          for (var i = 0; i < PresentationScaffold._destinations.length; i++)
            ListTile(
              leading: Icon(PresentationScaffold._destinations[i].icon),
              title: Text(PresentationScaffold._destinations[i].label),
              selected: i == selectedIndex,
              onTap: () {
                Navigator.of(context).pop();
                context.go(PresentationScaffold._destinations[i].route);
              },
            ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}

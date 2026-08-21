import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../activation/activation_records_page.dart';
import '../home/home_page.dart';
import '../settings/settings_page.dart';

/// Root scaffold with the three bottom-nav tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const ActivationRecordsPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.c.surface,
          border: Border(top: BorderSide(color: context.c.border)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: context.c.surface,
              indicatorColor: Colors.transparent,
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: states.contains(WidgetState.selected)
                      ? Theme.of(context).colorScheme.primary
                      : context.c.neutral,
                ),
              ),
            ),
            child: NavigationBar(
              height: 62,
              elevation: 0,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.mail_outline_rounded, color: context.c.neutral),
                  selectedIcon: Icon(Icons.mail_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  label: context.s.navEmails,
                ),
                NavigationDestination(
                  icon: Icon(Icons.access_time_rounded, color: context.c.neutral),
                  selectedIcon: Icon(Icons.access_time_filled_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  label: context.s.navActivation,
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined, color: context.c.neutral),
                  selectedIcon: Icon(Icons.settings_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  label: context.s.navSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

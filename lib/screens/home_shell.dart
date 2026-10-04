import 'package:flutter/material.dart';

import 'check_screen.dart';
import 'history_screen.dart';
import 'report_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final ValueNotifier<int> _historyRefreshTrigger = ValueNotifier<int>(0);

  void _handleHistoryRefresh() {
    _historyRefreshTrigger.value += 1;
  }

  @override
  void dispose() {
    _historyRefreshTrigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ReportScreen(onSavedToHistory: _handleHistoryRefresh),
      const CheckScreen(),
      HistoryScreen(refreshTrigger: _historyRefreshTrigger),
    ];

    final materialTheme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Theme(
        data: materialTheme.copyWith(
          colorScheme: materialTheme.colorScheme.copyWith(
            primary: const Color(0xFF005FB6),
          ),
        ),
        child: NavigationBar(
          indicatorColor: const Color(0xFF005FB6).withValues(alpha: 0.12),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.edit_document),
              label: 'Lapor',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              label: 'Cek',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              label: 'Riwayat',
            ),
          ],
        ),
      ),
    );
  }
}

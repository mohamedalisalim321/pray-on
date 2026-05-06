import 'package:flutter/material.dart';

import 'prayers_page.dart';
import 'qibla_page.dart';
import 'settings_page.dart';

import '../components/my_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            QiblaPage(),
            PrayersPage(),
            SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: MyNavBar(
        currentIndex: _currentIndex,
        onTabChange: _onTabChanged,
      ),
    );
  }
}

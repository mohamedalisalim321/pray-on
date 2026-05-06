import 'package:flutter/material.dart';

import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../themes/app_constants.dart';
import '../themes/theme_extensions.dart';

class MyNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChange;

  const MyNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  static const List<TabData> _tabs = [
    TabData(icon: Icons.compare_arrows_sharp, label: 'Qibla Direction'),
    TabData(icon: Icons.timer_rounded, label: 'Prayers'),
    TabData(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: context.radiusXL,
        color: colorScheme.surface,
      ),
      padding: context.paddingSM,
      child: _buildNav(context, colorScheme),
    );
  }

  Widget _buildNav(BuildContext context, ColorScheme colorScheme) {
    return GNav(
      selectedIndex: currentIndex,
      onTabChange: onTabChange,
      gap: AppConstants.spacingSM,
      iconSize: 20.w,
      duration: AppConstants.durationNormal,
      curve: AppConstants.curveDefault,
      color: colorScheme.onSurface,
      activeColor: colorScheme.primary,
      tabBackgroundColor: colorScheme.surfaceContainer,
      tabBorderRadius: AppConstants.radiusFull,
      rippleColor: Colors.transparent,
      hoverColor: Colors.transparent,
      tabs: List.generate(_tabs.length, (index) {
        final tab = _tabs[index];

        return GButton(
          icon: tab.icon,
          text: tab.label,
        );
      }),
    );
  }
}

class TabData {
  final IconData icon;
  final String label;

  const TabData({
    required this.icon,
    required this.label,
  });
}

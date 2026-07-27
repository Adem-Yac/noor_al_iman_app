import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Coran'),
    (Icons.access_time_rounded, Icons.access_time_filled_rounded, 'Prière'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Qibla'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Paramètres'),
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            6,
            isTablet ? 8 : 6,
            6,
            isTablet ? 8 : 6,
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].$1,
                    selectedIcon: _items[i].$2,
                    label: _items[i].$3,
                    selected: selectedIndex == i,
                    isTablet: isTablet,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.isTablet,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool isTablet;
  final VoidCallback onTap;

  double get _iconSize => isTablet ? 22 : 18;
  double get _labelSize => isTablet ? 12 : 10;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 8 : 6,
            horizontal: 2,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.navSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: _iconSize,
                color: selected ? Colors.white : AppColors.navUnselected,
              ),
              SizedBox(height: isTablet ? 4 : 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _labelSize,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : AppColors.navUnselected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

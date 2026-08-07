import 'package:flutter/material.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../app/theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home_rounded, S.home),
      (Icons.menu_book_outlined, Icons.menu_book_rounded, S.quran),
      (Icons.access_time_rounded, Icons.access_time_filled_rounded, S.prayer),
      (Icons.format_quote_rounded, Icons.format_quote_rounded, S.hadith),
      (Icons.volunteer_activism_outlined, Icons.volunteer_activism, S.duas),
      (Icons.settings_outlined, Icons.settings_rounded, S.settings),
    ];
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 12),
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Barre flottante arrondie
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.cardOf(context),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: AppColors.isDark(context) ? 0.35 : 0.08,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              // Icônes (pastille active qui dépasse en haut)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 64,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavItem(
                          icon: items[i].$1,
                          selectedIcon: items[i].$2,
                          label: items[i].$3,
                          selected: selectedIndex == i,
                          onTap: () => onSelect(i),
                        ),
                      ),
                  ],
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
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: selected ? 52 : 40,
            height: selected ? 52 : 40,
            transform: selected
                ? Matrix4.translationValues(0, -6, 0)
                : Matrix4.identity(),
            decoration: BoxDecoration(
              color: selected
                  ? (AppColors.isDark(context)
                      ? AppColors.darkPrimaryContainer
                      : AppColors.navSelected)
                  : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: (AppColors.isDark(context)
                                ? AppColors.darkPrimary
                                : AppColors.navSelected)
                            .withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              selected ? selectedIcon : icon,
              size: selected ? 24 : 22,
              color: selected
                  ? (AppColors.isDark(context)
                      ? AppColors.darkPrimary
                      : Colors.white)
                  : (AppColors.isDark(context)
                      ? AppColors.darkOnSurfaceVariant
                      : const Color(0xFF2C2C2C)),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'state/providers.dart';
import 'theme/ambient_background.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/grain_overlay.dart';
import 'ui/daily/daily_log_screen.dart';
import 'ui/recipes/recipes_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/training/training_home_screen.dart';

class MacroChefApp extends StatelessWidget {
  const MacroChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MacroChef',
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      home: const RootShell(),
    );
  }
}

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _selectedIndex = 0; // launch on Train (cleaner landing)

  @override
  void initState() {
    super.initState();
    // Fire-and-forget safety-net backup once per launch (throttled internally).
    // Runs after the first frame so it never delays showing the UI.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final finalizer = await ref.read(recoveryFinalizerProvider.future);
      final finalized = await finalizer.run(DateTime.now());
      if (!finalized) {
        await ref.read(autoBackupServiceProvider).runOnLaunch(DateTime.now());
      }
    });
  }

  // Bumped after logging food via the nav "+" so the Today tab remounts and
  // reflects the new entry immediately.
  int _todayTick = 0;

  /// Global "+" action: jump to Today and open the Add-food sheet.
  void _logFood() {
    setState(() => _selectedIndex = 2);
    showAddFoodSheet(
      context,
      onAdded: () {
        if (mounted) setState(() => _todayTick++);
      },
    );
  }

  Widget _navItem(int i) => _NavItem(
    config: _tabs[i],
    selected: _selectedIndex == i,
    onTap: () => setState(() => _selectedIndex = i),
  );

  static final _tabs = [
    _TabConfig(label: 'Train', icon: PhosphorIconsDuotone.barbell),
    _TabConfig(label: 'Recipes', icon: PhosphorIconsDuotone.bookOpen),
    _TabConfig(label: 'Today', icon: PhosphorIconsDuotone.chartDonut),
    _TabConfig(label: 'Settings', icon: PhosphorIconsDuotone.gearSix),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AmbientBackground(
        child: GrainOverlay(
          child: IndexedStack(
            index: _selectedIndex,
            // `isActive` lets data-driven tabs refresh when they become visible
            // (the IndexedStack keeps them alive, so they don't rebuild on their
            // own). Rebuilt on every setState, so didUpdateWidget fires per tab.
            children: [
              TrainingHomeScreen(isActive: _selectedIndex == 0),
              const RecipesScreen(), // Task 16
              DailyLogScreen(
                key: ValueKey('today-$_todayTick'),
                isActive: _selectedIndex == 2,
              ),
              const SettingsScreen(), // Task 15
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // The bar — top padding leaves room for the raised FAB.
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.line, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Center(child: _navItem(0))),
                      Expanded(child: Center(child: _navItem(1))),
                      const SizedBox(width: 60), // gap under the FAB
                      Expanded(child: Center(child: _navItem(2))),
                      Expanded(child: Center(child: _navItem(3))),
                    ],
                  ),
                ),
              ),
              // Raised center "+" for logging food.
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: _logFood,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.ember,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.canvas, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ember.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      PhosphorIconsBold.plus,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabConfig {
  final String label;
  final IconData icon;
  const _TabConfig({required this.label, required this.icon});
}

class _NavItem extends StatelessWidget {
  final _TabConfig config;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.config,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.ember.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config.icon,
              size: 24,
              color: selected ? AppColors.ember : AppColors.textMid,
            ),
            const SizedBox(height: 4),
            Text(
              config.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.ember : AppColors.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

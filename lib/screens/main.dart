import 'package:eigen_flutter/models/profile.dart';
import 'package:eigen_flutter/screens/contests_screen.dart';
import 'package:eigen_flutter/screens/daily_challenges_screen.dart';
import 'package:eigen_flutter/screens/duels_screen.dart';
import 'package:eigen_flutter/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Main Shell ---

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _animController;
  late Animation<double> _scaleAnim;

  static const _brandColor = Color(0xFF36093D);

  final List<Widget> _screens = const [
    ContestsScreen(),
    DailyChallengesScreen(),
    DuelsScreen(),
    ProfileScreen(),
  ];

  final List<({IconData icon, IconData activeIcon, String label})> _tabs = const [
    (icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Contests'),
    (icon: Icons.bolt_outlined,         activeIcon: Icons.bolt,          label: 'Daily'),
    (icon: Icons.security_outlined,       activeIcon: Icons.security,        label: 'Duels'),
    (icon: Icons.person_outline,        activeIcon: Icons.person,        label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _animController.forward(from: 0).then((_) => _animController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: _brandColor.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == _currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final scale = isActive
                            ? _scaleAnim.value
                            : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Icon(
                                isActive ? tab.activeIcon : tab.icon,
                                key: ValueKey(isActive),
                                color: isActive
                                    ? _brandColor
                                    : Colors.grey.shade400,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isActive
                                    ? _brandColor
                                    : Colors.grey.shade400,
                              ),
                              child: Text(tab.label),
                            ),
                            const SizedBox(height: 2),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              height: 3,
                              width: isActive ? 24 : 0,
                              decoration: BoxDecoration(
                                color: _brandColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          ),
      ),
    );
  }
}
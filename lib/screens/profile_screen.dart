import 'dart:async';

import 'package:eigen_flutter/providers/auth_provider.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/profile_repository.dart';
import 'package:eigen_flutter/widgets/edit_school.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _streakProvider = FutureProvider<int>((ref) async {
  final token = ref.read(authProvider).value?.accessToken;

  if (token == null) return 0;

  final result = await ProfileRepository().getStreak(token: token);

  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure() => 0,
  };
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _brand = Color(0xFF36093D);

  bool _showBadgeDescription = false;

  Timer? _badgeTimer;

  void _toggleBadgeDescription() {
    _badgeTimer?.cancel();

    setState(() {
      _showBadgeDescription = true;
    });

    _badgeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showBadgeDescription = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).value;
    final profile = authState?.profile;
    final streakAsync = ref.watch(_streakProvider);

    if (profile == null) {
      return Scaffold(
        appBar: _appBar(),
        body: const Center(
          child: CircularProgressIndicator(
            color: _brand,
          ),
        ),
      );
    }

    final int rating = profile.rating;

    final badge = _badge(rating);

    final memberSince = _formatDate(profile.createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F8),
      appBar: _appBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero ──────────────────────────────────────────────────

            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF36093D),
                    Color(0xFF6B1A7A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                24,
                28,
                24,
                36,
              ),
              child: Column(
                children: [
                  // Avatar

                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 3,
                      ),
                      color: Colors.white.withOpacity(0.12),
                    ),
                    child: profile.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              profile.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _DefaultAvatar(),
                            ),
                          )
                        : const _DefaultAvatar(),
                  ),

                  const SizedBox(height: 16),

                  // Username

                  Text(
                    profile.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Email

                  Text(
                    profile.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Badge

                  GestureDetector(
                    onTap: _toggleBadgeDescription,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: badge.color.withOpacity(0.95),
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: badge.color.withOpacity(0.22),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _showBadgeDescription
                            ? Column(
                                key: const ValueKey('description'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    badge.description,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey('label'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    badge.label.toUpperCase(),
                                    style: TextStyle(
                                      color: badge.color,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                  
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Stats ────────────────────────────────────────────────

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFFFD700),
                      value: '$rating',
                      label: 'Rating',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: streakAsync.when(
                      loading: () => const _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: Color(0xFFFF6B35),
                        value: '—',
                        label: 'Day Streak',
                      ),
                      error: (_, __) => const _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: Color(0xFFFF6B35),
                        value: '0',
                        label: 'Day Streak',
                      ),
                      data: (streak) => _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFFF6B35),
                        value: '$streak',
                        label: 'Day Streak',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Info Card ────────────────────────────────────────────

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (_) => EditSchoolDialog(
                            currentSchool: profile.school,
                          ),
                        );
                      },
                      child: _InfoRow(
                        icon: Icons.school_rounded,
                        label: 'School',
                        value: profile.school ?? 'Rogue',
                        faded: profile.school == null,
                        tappable: true,
                      ),
                    ),

                    const _Divider(),

                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Member since',
                      value: memberSince,
                    ),

                    const _Divider(),

                    _InfoRow(
                      icon: Icons.fingerprint_rounded,
                      label: 'User ID',
                      value: profile.id.substring(0, 8).toUpperCase(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Logout ───────────────────────────────────────────────

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE74C3C),
                    side: const BorderSide(
                      color: Color(0xFFE74C3C),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────

  AppBar _appBar() {
    return AppBar(
      title: const Text(
        'Profile',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      backgroundColor: _brand,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'You\'ll need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    }
  }

  // ── Badge Logic ────────────────────────────────────────────────────

  ({
    String label,
    String description,
    Color color,
  }) _badge(int rating) {
    if (rating < 800) {
      return (
        label: 'NPC',
        description: 'still downloading skill pack',
        color: const Color(0xFFB0B0B0),
      );
    } else if (rating < 1100) {
      return (
        label: 'Hustler',
        description: 'grind now, flex later',
        color: const Color(0xFF00E5FF),
      );
    } else if (rating < 1500) {
      return (
        label: 'Try Hard',
        description: 'locked in 24/7',
        color: const Color(0xFF4D7CFE),
      );
    } else if (rating < 1900) {
      return (
        label: 'Gladiator',
        description: 'victory loves pressure',
        color: const Color(0xFF2ECC71),
      );
    } else if (rating < 2300) {
      return (
        label: 'Warlord',
        description: 'fear follows your queue',
        color: const Color(0xFFBB6BFF),
      );
    } else if (rating < 2500) {
      return (
        label: 'Titan',
        description: 'world beneath my feet',
        color: const Color(0xFFFFA726),
      );
    } else {
      return (
        label: 'GOATED',
        description: 'built different fr',
        color: const Color(0xFFFF4D4F),
      );
    }
  }

  // ── Date ───────────────────────────────────────────────────────────

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      color: Colors.white.withOpacity(0.7),
      size: 46,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                  height: 1,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool faded;
  final bool tappable;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.faded = false,
    this.tappable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF36093D),
          ),

          const SizedBox(width: 12),

          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Spacer(),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: faded
                    ? Colors.grey.shade400
                    : const Color(0xFF1A1A1A),
                fontStyle:
                    faded ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),

          if (tappable) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Colors.grey.shade100,
    );
  }
}
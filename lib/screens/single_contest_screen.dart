import 'package:eigen_flutter/models/contest.dart';
import 'package:eigen_flutter/providers/auth_provider.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/contests_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _repo = ContestsRepository();

final _contestDetailProvider =
    FutureProvider.family<Contest, ({int id, String token})>((ref, args) async {
  final result = await _repo.getContest(token: args.token, id: args.id);
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure(:final exception) => throw exception,
  };
});

final _canEnterProvider =
    FutureProvider.family<String, ({int id, String token})>((ref, args) async {
  final result = await _repo.canEnterContest(token: args.token, id: args.id);
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure(:final exception) => throw exception,
  };
});

// ── Screen ────────────────────────────────────────────────────────────────────

class SingleContestScreen extends ConsumerWidget {
  final int contestId;
  const SingleContestScreen({super.key, required this.contestId});

  static const _brand = Color(0xFF36093D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authProvider).value?.accessToken;

    if (token == null) {
      // Should not reach here due to auth guard in ContestsScreen,
      // but just in case
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/auth');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final args = (id: contestId, token: token);
    final contestAsync = ref.watch(_contestDetailProvider(args));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F8),
      appBar: AppBar(
        title: contestAsync.maybeWhen(
          data: (c) => Text(c.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          orElse: () => const Text('Contest',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: contestAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _brand)),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (contest) => _ContestDetail(
          contest: contest,
          token: token,
          contestId: contestId,
        ),
      ),
    );
  }
}

// ── Detail Body ───────────────────────────────────────────────────────────────

class _ContestDetail extends ConsumerWidget {
  final Contest contest;
  final String token;
  final int contestId;

  const _ContestDetail({
    required this.contest,
    required this.token,
    required this.contestId,
  });

  static const _brand = Color(0xFF36093D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = contest.status == ContestStatus.live;
    final args = (id: contestId, token: token);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info card ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        contest.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: contest.status),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Time details
                _InfoRow(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Start',
                  value: _formatDateTime(contest.startTime),
                  color: const Color(0xFF2ECC71),
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.stop_circle_outlined,
                  label: 'End',
                  value: _formatDateTime(contest.endTime),
                  color: const Color(0xFFE74C3C),
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.hourglass_bottom_rounded,
                  label: 'Duration',
                  value: _formatDuration(contest.duration),
                  color: _brand,
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        icon: Icons.quiz_rounded,
                        value: '${contest.questionsCount}',
                        label: 'Questions',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        icon: Icons.people_rounded,
                        value: '${contest.participantsCount}',
                        label: 'Participants',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── CTA section ────────────────────────────────────────────
          if (!isLive)
            _NotLiveBanner(contest: contest)
          else
            ref.watch(_canEnterProvider(args)).when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _brand),
              ),
              error: (e, _) => _ErrorView(message: e.toString()),
              data: (status) => _CTAButton(
                status: status,
                token: token,
                contestId: contestId,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final l = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = l.hour.toString().padLeft(2, '0');
    final m = l.minute.toString().padLeft(2, '0');
    return '${l.day} ${months[l.month - 1]} ${l.year}, $h:$m';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes minutes';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hour${h > 1 ? 's' : ''}' : '$h h $m min';
  }
}

// ── CTA Button ────────────────────────────────────────────────────────────────

class _CTAButton extends ConsumerStatefulWidget {
  final String status;
  final String token;
  final int contestId;

  const _CTAButton({
    required this.status,
    required this.token,
    required this.contestId,
  });

  @override
  ConsumerState<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends ConsumerState<_CTAButton> {
  static const _brand = Color(0xFF36093D);
  bool _loading = false;

  Future<void> _handlePress() async {
    setState(() => _loading = true);

    try {
      if (widget.status == 'not_entered') {
        final result = await _repo.beginContest(
          token: widget.token,
          id: widget.contestId,
        );
        if (result is ApiFailure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text((result as ApiFailure).exception.message),
                backgroundColor: const Color(0xFFE74C3C),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        // TODO: navigate to /contest/:id/questions
        Navigator.pushNamed(
          context,
          '/contest-questions',
          arguments: widget.contestId,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = switch (widget.status) {
      'not_entered' => 'Enter Contest',
      'ongoing'     => 'Resume Contest',
      _             => '',
    };

    if (widget.status == 'is_submitted') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2ECC71).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF2ECC71).withOpacity(0.4), width: 1.5),
        ),
        child: const Column(
          children: [
            Icon(Icons.emoji_events_rounded,
                color: Color(0xFF2ECC71), size: 36),
            SizedBox(height: 10),
            Text(
              '🎉 Already submitted!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2ECC71),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your rating will be updated shortly. Thanks!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF2ECC71),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _brand.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

// ── Not Live Banner ───────────────────────────────────────────────────────────

class _NotLiveBanner extends StatelessWidget {
  final Contest contest;
  const _NotLiveBanner({required this.contest});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = contest.status == ContestStatus.upcoming;
    final color = isUpcoming ? const Color(0xFFF39C12) : Colors.grey;
    final icon = isUpcoming
        ? Icons.schedule_rounded
        : Icons.check_circle_outline_rounded;
    final message = isUpcoming
        ? 'Contest hasn\'t started yet. Check back at ${_fmt(contest.startTime)}.'
        : 'This contest has ended.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${l.day} ${months[l.month - 1]}, ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

// ── Small widgets ──────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatBox(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF36093D)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A))),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ContestStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ContestStatus.live     => ('● LIVE', const Color(0xFF2ECC71)),
      ContestStatus.upcoming => ('UPCOMING', const Color(0xFFF39C12)),
      ContestStatus.past     => ('ENDED', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message,
                    style:
                        TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
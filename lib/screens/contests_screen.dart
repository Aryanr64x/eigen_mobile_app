import 'package:eigen_flutter/models/contest.dart';
import 'package:eigen_flutter/providers/auth_provider.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/contests_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _contestsProvider = FutureProvider<List<Contest>>((ref) async {
  final result = await ContestsRepository().getContests();
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure(:final exception) => throw exception,
  };
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ContestsScreen extends ConsumerWidget {
  const ContestsScreen({super.key});

  static const _brand = Color(0xFF36093D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(_contestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F8),
      appBar: AppBar(
        title: const Text(
          'Contests',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: _brand,
        onRefresh: () async => ref.invalidate(_contestsProvider),
        child: contestsAsync.when(
          loading: () => _buildSkeletons(),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (contests) => _buildList(contests),
        ),
      ),
    );
  }

  Widget _buildList(List<Contest> all) {
    final live = all.where((c) => c.status == ContestStatus.live).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final upcoming = all.where((c) => c.status == ContestStatus.upcoming).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final past = all.where((c) => c.status == ContestStatus.past).toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime)); // most recent first

    if (all.isEmpty) {
      return const Center(
        child: Text(
          'No contests yet.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (live.isNotEmpty) ...[
          _SectionHeader(label: 'LIVE NOW', color: const Color(0xFF2ECC71)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: EdgeInsets.fromLTRB(
                    16, i == 0 ? 8 : 0, 16, i == live.length - 1 ? 0 : 10),
                child: _ContestCard(contest: live[i]),
              ),
              childCount: live.length,
            ),
          ),
          const _SectionSpacer(),
        ],
        if (upcoming.isNotEmpty) ...[
          _SectionHeader(label: 'UPCOMING', color: const Color(0xFFF39C12)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: EdgeInsets.fromLTRB(
                    16, i == 0 ? 8 : 0, 16, i == upcoming.length - 1 ? 0 : 10),
                child: _ContestCard(contest: upcoming[i]),
              ),
              childCount: upcoming.length,
            ),
          ),
          const _SectionSpacer(),
        ],
        if (past.isNotEmpty) ...[
          _SectionHeader(label: 'PAST', color: Colors.grey),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: EdgeInsets.fromLTRB(
                    16, i == 0 ? 8 : 0, 16, i == past.length - 1 ? 0 : 10),
                child: _ContestCard(contest: past[i]),
              ),
              childCount: past.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildSkeletons() {
    return CustomScrollView(
      slivers: [
        _SectionHeader(label: 'LIVE NOW', color: const Color(0xFF2ECC71)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _ContestCardSkeleton(),
            ),
            childCount: 2,
          ),
        ),
        _SectionHeader(label: 'UPCOMING', color: const Color(0xFFF39C12)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _ContestCardSkeleton(),
            ),
            childCount: 3,
          ),
        ),
      ],
    );
  }
}

// ── Contest Card ──────────────────────────────────────────────────────────────

class _ContestCard extends ConsumerWidget  {
  final Contest contest;
  const _ContestCard({required this.contest});

  static const _brand = Color(0xFF36093D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = contest.status == ContestStatus.live;
    final isPast = contest.status == ContestStatus.past;

    return GestureDetector(
      onTap: () {
        final token = ref.read(authProvider).value?.accessToken;
        if (token == null) {
          Navigator.pushNamed(context, '/auth');
          return;
  }
  Navigator.pushNamed(context, '/contest', arguments: contest.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isLive
              ? Border.all(color: const Color(0xFF2ECC71), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? const Color(0xFF2ECC71).withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    contest.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isPast
                          ? Colors.grey.shade500
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: contest.status),
              ],
            ),

            const SizedBox(height: 12),

            // ── Time info ──────────────────────────────────────────
            if (isLive) ...[
              _TimeRow(
                icon: Icons.timer_rounded,
                label: 'Ends',
                value: _formatTime(contest.endTime),
                color: const Color(0xFF2ECC71),
              ),
            ] else if (!isPast) ...[
              _TimeRow(
                icon: Icons.schedule_rounded,
                label: 'Starts',
                value: _formatDateTime(contest.startTime),
                color: const Color(0xFFF39C12),
              ),
            ] else ...[
              _TimeRow(
                icon: Icons.event_rounded,
                label: 'Held on',
                value: _formatDateTime(contest.startTime),
                color: Colors.grey.shade400,
              ),
            ],

            const SizedBox(height: 10),

            // ── Stats row ──────────────────────────────────────────
            Row(
              children: [
                _StatChip(
                  icon: Icons.quiz_outlined,
                  label: '${contest.questionsCount} questions',
                  faded: isPast,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.people_outline_rounded,
                  label: '${contest.participantsCount} joined',
                  faded: isPast,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.hourglass_bottom_rounded,
                  label: _formatDuration(contest.duration),
                  faded: isPast,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${local.day} ${months[local.month - 1]}, ${_formatTime(local)}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

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
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Time Row ──────────────────────────────────────────────────────────────────

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _TimeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool faded;
  const _StatChip({required this.icon, required this.label, this.faded = false});

  @override
  Widget build(BuildContext context) {
    final color = faded ? Colors.grey.shade400 : const Color(0xFF6B1A7A);
    final bg = faded ? Colors.grey.shade100 : const Color(0xFFF0E6F2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionSpacer extends StatelessWidget {
  const _SectionSpacer();

  @override
  Widget build(BuildContext context) =>
      const SliverToBoxAdapter(child: SizedBox(height: 8));
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _ContestCardSkeleton extends StatelessWidget {
  const _ContestCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

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
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:eigen_flutter/models/question.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/dailyquestions_repository.dart';
import 'package:eigen_flutter/widgets/calender_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _repo = QuestionsRepository();

final dailyQuestionProvider = FutureProvider<Question>((ref) async {
  final result = await _repo.getDailyQuestion();
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure(:final exception) => throw exception,
  };
});

final allQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  final result = await _repo.getAllQuestions();
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure(:final exception) => throw exception,
  };
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class DailyChallengesScreen extends ConsumerWidget {
  const DailyChallengesScreen({super.key});

  static const _brand = Color(0xFF36093D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyQuestionProvider);
    final allAsync = ref.watch(allQuestionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F8),
      appBar: AppBar(
        title: const Text(
          'Daily Challenges',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: _brand,
        onRefresh: () async {
          ref.invalidate(dailyQuestionProvider);
          ref.invalidate(allQuestionsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Question of the Day ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'QUESTION OF THE DAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: _brand.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: dailyAsync.when(
                  loading: () => _DailyCardSkeleton(),
                  error: (e, _) => _ErrorCard(message: e.toString()),
                  data: (q) => _DailyQuestionCard(question: q),
                ),
              ),
            ),

            // ── All Questions Header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'ALL QUESTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: _brand.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    allAsync.when(
                      data: (list) => _Pill(label: '${list.length}'),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Question List ────────────────────────────────────────────────
            allAsync.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _QuestionCardSkeleton(),
                  ),
                  childCount: 5,
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _ErrorCard(message: e.toString()),
                ),
              ),
              data: (questions) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: EdgeInsets.fromLTRB(
                        16, 0, 16, i == questions.length - 1 ? 24 : 10),
                    child: _QuestionCard(
                      question: questions[i],
                      index: i,
                    ),
                  ),
                  childCount: questions.length,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
      onPressed: () => showCalendarDialog(context, ref),
      backgroundColor: const Color(0xFF36093D),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.calendar_month_rounded),
    ),
    );
  }
}

// ── Daily Question Card ────────────────────────────────────────────────────────

class _DailyQuestionCard extends StatelessWidget {
  final Question question;
  const _DailyQuestionCard({required this.question});

  static const _brand = Color(0xFF36093D);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/question',
        arguments: question.id,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF36093D), Color(0xFF6B1A7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _brand.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_sunny_rounded,
                          color: Color(0xFFFFD700), size: 13),
                      const SizedBox(width: 5),
                      Text(
                        'TODAY\'S PICK',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _DifficultyBadge(
                  difficulty: question.difficulty,
                  light: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              question.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _TopicChip(topic: question.topics, light: true),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Solve',
                        style: TextStyle(
                          color: Color(0xFF36093D),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: Color(0xFF36093D)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Regular Question Card ──────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final Question question;
  final int index;
  const _QuestionCard({required this.question, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/question',
        arguments: question.id,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Index badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0E6F2),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF36093D),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _TopicChip(topic: question.topics),
                      if (question.blanksCount > 0) ...[
                        const SizedBox(width: 6),
                        _Pill(
                          label: '${question.blanksCount} blanks',
                          icon: Icons.edit_outlined,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Numeric difficulty badge on the right
            _DifficultyBadge(difficulty: question.difficulty),
          ],
        ),
      ),
    );
  }
}

// ── Small reusable widgets ─────────────────────────────────────────────────────

class _DifficultyBadge extends StatelessWidget {
  final int difficulty;
  final bool light;
  const _DifficultyBadge({required this.difficulty, this.light = false});

  Color get _color {
    if (difficulty <= 1000) return const Color(0xFF2ECC71);  // green  500–1000
    if (difficulty <= 2000) return const Color(0xFFF39C12);  // yellow 1000–2000
    if (difficulty <= 3000) return const Color(0xFFE74C3C);  // red    2000–3000
    return const Color(0xFF8E44AD);                           // purple 3000+
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: light ? Colors.white.withOpacity(0.15) : _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: light ? Colors.white.withOpacity(0.3) : _color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        '$difficulty',
        style: TextStyle(
          color: light ? Colors.white : _color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String topic;
  final bool light;
  const _TopicChip({required this.topic, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withOpacity(0.15)
            : const Color(0xFFF0E6F2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        topic,
        style: TextStyle(
          color: light
              ? Colors.white.withOpacity(0.9)
              : const Color(0xFF6B1A7A),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _Pill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: Colors.grey.shade500),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeletons ──────────────────────────────────────────────────────────────────

class _DailyCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFEAD9EE),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _QuestionCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
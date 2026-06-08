import 'package:eigen_flutter/models/question.dart';
import 'package:eigen_flutter/models/submission_result.dart';
import 'package:eigen_flutter/providers/auth_provider.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/dailyquestions_repository.dart';
import 'package:eigen_flutter/widgets/math_body_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _repo = QuestionsRepository();

final questionByIdProvider = FutureProvider.family<Question, String>((
  ref,
  id,
) async {
  final result = await _repo.getQuestion(id: id);
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure(:final exception) => throw exception,
  };
});

// ── Screen ────────────────────────────────────────────────────────────────────

class QuestionScreen extends ConsumerWidget {
  final String questionId;
  const QuestionScreen({super.key, required this.questionId});

  static const _brand = Color(0xFF36093D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync = ref.watch(questionByIdProvider(questionId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F8),
      appBar: AppBar(
        title: const Text(
          'Question',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: questionAsync.when(
        loading: () => const _LoadingView(),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (question) => _QuestionBody(question: question),
      ),
    );
  }
}

// ── Main Body ─────────────────────────────────────────────────────────────────

class _QuestionBody extends ConsumerStatefulWidget {
  final Question question;
  const _QuestionBody({required this.question});

  @override
  ConsumerState<_QuestionBody> createState() => _QuestionBodyState();
}

class _QuestionBodyState extends ConsumerState<_QuestionBody> {
  static const _brand = Color(0xFF36093D);
  static const _green = Color(0xFF2ECC71);
  static const _red = Color(0xFFE74C3C);

  late final List<TextEditingController> _blankControllers;

  bool _isSubmitting = false;
  SubmissionResult? _result;

  @override
  void initState() {
    super.initState();
    _blankControllers = List.generate(
      widget.question.blanksCount,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _blankControllers) c.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final token = ref.read(authProvider).value?.accessToken;
    if (token == null) {
      Navigator.pushNamed(context, '/auth');
      return;
    }

    final List<double?> answers = [];
    for (int i = 0; i < _blankControllers.length; i++) {
      final text = _blankControllers[i].text.trim();
      if (text.isEmpty) {
        answers.add(null);
      } else {
        final parsed = double.tryParse(text);
        if (parsed == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Blank ${i + 1} must be a number.'),
              backgroundColor: _brand,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
        answers.add(parsed);
      }
    }

    setState(() {
      _isSubmitting = true;
      _result = null;
    });

    final result = await _repo.submitAnswer(
      token: token,
      questionId: widget.question.id,
      answers: answers,
    );

    if (!mounted) return;

    switch (result) {
      case ApiSuccess(:final data):
        setState(() {
          _result = data;
          _isSubmitting = false;
        });
      case ApiFailure(:final exception):
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exception.message),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    }
  }

  BlankResult? _resultFor(int index) {
    if (_result == null) return null;
    return _result!.results.firstWhere(
      (r) => r.blankOrder == index + 1,
      orElse: () => _result!.results[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final submitted = _result != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (question.topics.isNotEmpty) ...[
                      _Chip(
                        label: question.topics,
                        bg: const Color(0xFFF0E6F2),
                        fg: const Color(0xFF6B1A7A),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _DifficultyChip(difficulty: question.difficulty),
                    if (question.blanksCount > 0) ...[
                      const SizedBox(width: 6),
                      _Chip(
                        label: '${question.blanksCount} blanks',
                        bg: Colors.grey.shade100,
                        fg: Colors.grey.shade600,
                        icon: Icons.edit_outlined,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Body MathView ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: MathBodyView(htmlBody: widget.question.body),
          ),

          // ── Blanks ────────────────────────────────────────────────
          if (question.blanksCount > 0) ...[
            const SizedBox(height: 20),
            const Text(
              'YOUR ANSWER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: _brand,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(question.blanksCount, (i) {
              final blankResult = _resultFor(i);
              final isCorrect = blankResult?.isCorrect;

              Color borderColor;
              Color fillColor;
              if (isCorrect == null) {
                borderColor = _brand.withOpacity(0.2);
                fillColor = Colors.white;
              } else if (isCorrect) {
                borderColor = _green;
                fillColor = _green.withOpacity(0.06);
              } else {
                borderColor = _red;
                fillColor = _red.withOpacity(0.06);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _blankControllers[i],
                  enabled: !submitted,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: i == question.blanksCount - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isCorrect == null
                        ? const Color(0xFF1A1A1A)
                        : isCorrect
                            ? _green
                            : _red,
                  ),
                  decoration: InputDecoration(
                    labelText: question.blanksCount == 1
                        ? 'Your answer'
                        : 'Blank ${i + 1}',
                    labelStyle: TextStyle(
                      color: _brand.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: fillColor,
                    suffixIcon: isCorrect == null
                        ? null
                        : Icon(
                            isCorrect
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: isCorrect ? _green : _red,
                            size: 20,
                          ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _brand, width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor, width: 1.5),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // ── Result summary card ───────────────────────────────
            if (_result != null) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _result!.allCorrect
                      ? _green.withOpacity(0.08)
                      : _red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _result!.allCorrect
                        ? _green.withOpacity(0.4)
                        : _red.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _result!.allCorrect
                          ? Icons.emoji_events_rounded
                          : Icons.close_rounded,
                      color: _result!.allCorrect ? _green : _red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _result!.allCorrect
                                ? 'All correct!'
                                : 'Not quite right',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _result!.allCorrect ? _green : _red,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _result!.allCorrect
                                ? 'Great work — streak updated if this was today\'s question.'
                                : '${_result!.results.where((r) => r.isCorrect).length} of ${_result!.results.length} blanks correct.',
                            style: TextStyle(
                              fontSize: 12,
                              color: (_result!.allCorrect ? _green : _red)
                                  .withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (!_result!.allCorrect)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _result = null;
                        for (final c in _blankControllers) c.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brand,
                      side: const BorderSide(color: _brand, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],

            // ── Submit button ─────────────────────────────────────
            if (!submitted) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _brand.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Answer',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Small widgets ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  const _Chip({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final int difficulty;
  const _DifficultyChip({required this.difficulty});

  Color get _color {
    if (difficulty <= 1000) return const Color(0xFF2ECC71);
    if (difficulty <= 2000) return const Color(0xFFF39C12);
    if (difficulty <= 3000) return const Color(0xFFE74C3C);
    return const Color(0xFF8E44AD);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        '$difficulty',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _color,
        ),
      ),
    );
  }
}

// ── Loading / Error ────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF36093D)),
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
                child: Text(
                  message,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
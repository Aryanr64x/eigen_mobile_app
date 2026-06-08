import 'package:eigen_flutter/models/question.dart';
import 'package:eigen_flutter/providers/auth_provider.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/contests_repository.dart';
import 'package:eigen_flutter/screens/contest_submitted_screen.dart';
import 'package:eigen_flutter/widgets/math_body_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _contestQuestionsProvider =
    FutureProvider.family<List<Question>, ({int id, String token})>(
        (ref, args) async {
  final result = await ContestsRepository()
      .getContestQuestions(token: args.token, id: args.id);
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure(:final exception) => throw exception,
  };
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ContestQuestionsScreen extends ConsumerStatefulWidget {
  final int contestId;
  const ContestQuestionsScreen({super.key, required this.contestId});

  @override
  ConsumerState<ContestQuestionsScreen> createState() =>
      _ContestQuestionsScreenState();
}

class _ContestQuestionsScreenState
    extends ConsumerState<ContestQuestionsScreen> {
  static const _brand = Color(0xFF36093D);

  int _currentIndex = 0;
  bool _submitting = false;

  final Map<int, List<TextEditingController>> _controllers = {};

  void _initControllers(List<Question> questions) {
    for (final q in questions) {
      if (!_controllers.containsKey(int.parse(q.id))) {
        _controllers[int.parse(q.id)] = List.generate(
          q.blanksCount,
          (_) => TextEditingController(),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final list in _controllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _handleSubmit(List<Question> questions, String token) async {
    final Map<String, List<double>> payload = {};
    for (final q in questions) {
      final qid = int.parse(q.id);
      final controllers = _controllers[qid] ?? [];
      payload[qid.toString()] = controllers.map((c) {
        final text = c.text.trim();
        if (text.isEmpty) return -10000.0;
        return double.tryParse(text) ?? -10000.0;
      }).toList();
    }

    setState(() => _submitting = true);

    final result = await ContestsRepository().submitContest(
      token: token,
      id: widget.contestId,
      answers: payload,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case ApiSuccess(:final data):
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ContestSubmittedScreen(
              contestId: widget.contestId,
              score: data,
            ),
          ),
        );
      case ApiFailure(:final exception):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exception.message),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authProvider).value?.accessToken;
    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Navigator.pushReplacementNamed(context, '/auth'));
      return const Scaffold(body: SizedBox.shrink());
    }

    final args = (id: widget.contestId, token: token);
    final questionsAsync = ref.watch(_contestQuestionsProvider(args));

    return Scaffold(
      backgroundColor: Colors.white,
      body: questionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _brand)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e.toString(),
                style: const TextStyle(color: Colors.red, fontSize: 14)),
          ),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Text('No questions found.',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            );
          }
          _initControllers(questions);
          final q = questions[_currentIndex];
          return _buildBody(context, questions, q, token);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Question> questions,
    Question current,
    String token,
  ) {
    final qid = int.parse(current.id);
    final controllers = _controllers[qid] ?? [];

    return SafeArea(
      child: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────────
          Container(
            color: _brand,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Question ${_currentIndex + 1} of ${questions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    current.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Body MathView ──────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: MathBodyView(
                      key: ValueKey(current.id),
                      htmlBody: current.body,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Blanks
                  if (current.blanksCount > 0) ...[
                    Text(
                      'Your Answer${current.blanksCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(current.blanksCount, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              current.blanksCount == 1
                                  ? 'Your answer'
                                  : 'Blank ${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: controllers[i],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textInputAction: i == current.blanksCount - 1
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              enabled: !_submitting,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A1A1A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your answer',
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: _brand.withOpacity(0.2),
                                      width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: _brand, width: 1.5),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom nav ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(questions.length, (i) {
                    final isSelected = i == _currentIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _currentIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _brand
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () => _handleSubmit(questions, token),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _brand.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Submit Contest',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
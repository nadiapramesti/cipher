import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/exam.dart';
import '../../core/models.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import '../../widgets/scene3d.dart';
import '../quiz/quiz_screen.dart';

/// Kartu "Ujian Akhir" di bawah daftar modul level.
class ExamCard extends StatelessWidget {
  const ExamCard({super.key, required this.level});
  final Level level;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ready = s.isLevelDone(level);
    final best = s.examScore(level.index);
    final passed = s.isExamPassed(level.index);
    final color = passed ? C.ok : (ready ? C.accent : C.muted);

    return Panel(
      onTap: () {
        if (!ready) {
          showInfo(context, tr('ex_locked'));
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExamIntroScreen(level: level)));
      },
      color: ready ? C.accent.withValues(alpha: passed ? 0.04 : 0.09) : C.bg,
      borderColor: color.withValues(alpha: ready ? 0.7 : 0.35),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Icon(
              passed ? Icons.verified_rounded : (ready ? Icons.quiz_rounded : Icons.lock_outline_rounded),
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('ex_title'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ready ? C.text : C.muted)),
                const SizedBox(height: 3),
                Text(
                  passed
                      ? tr('ex_card_passed', {'n': best ?? 0})
                      : ready
                          ? tr('ex_card_ready', {'q': examQuestionCount, 'p': examPassPercent})
                          : tr('ex_card_locked'),
                  style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.35),
                ),
              ],
            ),
          ),
          if (ready) Icon(Icons.chevron_right_rounded, color: color),
        ],
      ),
    );
  }
}

class ExamIntroScreen extends StatelessWidget {
  const ExamIntroScreen({super.key, required this.level});
  final Level level;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final best = s.examScore(level.index);

    return Scaffold(
      appBar: AppBar(title: Text('${level.code}  ${tr('ex_title')}')),
      body: GridBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            const SizedBox(height: 8),
            const Center(child: SizedBox(height: 170, child: VaultScene())),
            const SizedBox(height: 18),
            Text(level.title, textAlign: TextAlign.center, style: display(size: 26)),
            const SizedBox(height: 8),
            Text(tr('ex_intro'), textAlign: TextAlign.center, style: TextStyle(color: C.muted, height: 1.5)),
            const SizedBox(height: 22),
            Panel(
              child: Column(
                children: [
                  _Rule(Icons.format_list_numbered_rounded, tr('ex_rule_q', {'q': examQuestionCount})),
                  _Rule(Icons.shuffle_rounded, tr('ex_rule_mix')),
                  _Rule(Icons.flag_rounded, tr('ex_rule_pass', {'p': examPassPercent})),
                  _Rule(Icons.workspace_premium_outlined, tr('ex_rule_cert')),
                ],
              ),
            ),
            if (best != null) ...[
              const SizedBox(height: 14),
              Center(child: MonoTag(tr('ex_best', {'n': best}), color: s.isExamPassed(level.index) ? C.ok : C.orange, filled: true)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        ChunkyButton(
          onPressed: () {
            final set = buildExam(s.content, level, '${level.code} ${tr('ex_title')}');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => QuizScreen(module: set.module, exam: set)),
            );
          },
          child: Text(tr('ex_start')),
        ),
      ]),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, size: 20, color: C.accent),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
      ]),
    );
  }
}

class ExamResultScreen extends StatelessWidget {
  const ExamResultScreen({
    super.key,
    required this.level,
    required this.percent,
    required this.correct,
    required this.total,
    required this.xpGained,
  });

  final Level level;
  final int percent;
  final int correct;
  final int total;
  final int xpGained;

  @override
  Widget build(BuildContext context) {
    final passed = percent >= examPassPercent;
    final color = passed ? C.ok : C.orange;

    return Scaffold(
      appBar: AppBar(title: Text('${level.code}  ${tr('ex_title')}'), automaticallyImplyLeading: false),
      body: GridBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(color: color, width: 3),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 30)],
                ),
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$percent%', style: display(size: 40, color: color)),
                  Text('$correct/$total', style: mono(size: 12)),
                ]),
              ),
            ),
            const SizedBox(height: 22),
            Text(tr(passed ? 'ex_pass_title' : 'ex_fail_title'), textAlign: TextAlign.center, style: display(size: 26)),
            const SizedBox(height: 8),
            Text(
              tr(passed ? 'ex_pass_body' : 'ex_fail_body', {'l': level.code, 'p': examPassPercent}),
              textAlign: TextAlign.center,
              style: TextStyle(color: C.muted, height: 1.5),
            ),
            if (xpGained > 0) ...[
              const SizedBox(height: 16),
              Center(child: MonoTag('+$xpGained XP', color: C.yellow, filled: true)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        if (!passed)
          ChunkyButton.outline(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ExamIntroScreen(level: level)),
            ),
            child: Text(tr('ex_retry')),
          ),
        ChunkyButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr(passed ? 'ex_done' : 'ex_back')),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gympad/blocs/questionnaire/questionnaire_bloc.dart';
import 'package:gympad/constants/app_styles.dart';
import 'package:go_router/go_router.dart';

part 'begin_view.dart';
part 'single_choice_question.dart';
part 'multi_choice_question.dart';

class QuestionnaireScreen extends StatelessWidget {
  final bool force;
  const QuestionnaireScreen({super.key, this.force = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              QuestionnaireBloc()
                ..add(QuestionnaireStarted(forceRefresh: force)),
      child: _QuestionnaireManager(force: force),
    );
  }
}

class _QuestionnaireManager extends StatefulWidget {
  final bool force;
  const _QuestionnaireManager({this.force = false});

  @override
  State<_QuestionnaireManager> createState() => _QuestionnaireManagerState();
}

class _QuestionnaireManagerState extends State<_QuestionnaireManager> {
  final PageController _pageController = PageController();
  bool _begun = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<QuestionnaireBloc, QuestionnaireState>(
          listener: (context, state) {
            // If user pressed "Do it later", always navigate away.
            if (state.skipped && mounted) {
              context.go('/main');
              return;
            }
            // If completed navigate away.
            if (state.completed && mounted) {
              context.go('/main');
            }
          },
          builder: (context, state) {
            if (!_begun) {
              return _BeginView(
                onStart: () {
                  setState(() => _begun = true);
                },
                onSkip: () {
                  context.read<QuestionnaireBloc>().add(QuestionnaireSkipped());
                },
              );
            }

            final pages = _buildQuestionPages(context, state);
            return Column(
              children: [
                _ProgressBar(
                  current: state.currentIndex + 1,
                  total: pages.length,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged:
                        (i) => context.read<QuestionnaireBloc>().add(
                          QuestionnaireProgressChanged(i),
                        ),
                    children: pages,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildQuestionPages(
    BuildContext context,
    QuestionnaireState state,
  ) {
    final bloc = context.read<QuestionnaireBloc>();
    final pages = <Widget>[
      _SingleChoiceQuestion(
        questionId: 'goal',
        title: 'What is your primary fitness goal?',
        options: const [
          'Increase muscle size (Hypertrophy)',
          'Increase strength (Lifting heavier weights)',
          'Improve cardiovascular endurance',
          'Lose weight / Fat loss',
          'Improve overall health and fitness',
          'Recover from an injury (Rehabilitation)',
        ],
        selected: state.answers['goal']?.first,
        onChanged:
            (v) => bloc.add(
              QuestionnaireAnswerUpdated(
                questionId: 'goal',
                selectedOptions: [if (v != null) v],
              ),
            ),
      ),
      _SingleChoiceQuestion(
        questionId: 'experience',
        title: 'What is your current level of workout experience?',
        options: const [
          'Beginner (Little to no experience)',
          'Intermediate (I have been working out consistently for at least 6 months.)',
          'Advanced (I have been consistently training for over 2 years.)',
        ],
        selected: state.answers['experience']?.first,
        onChanged:
            (v) => bloc.add(
              QuestionnaireAnswerUpdated(
                questionId: 'experience',
                selectedOptions: [if (v != null) v],
              ),
            ),
      ),
      _MultiChoiceQuestion(
        questionId: 'health_conditions',
        title:
            'Have you been diagnosed with any of the following health conditions? (Select all that apply)',
        options: const [
          'Heart disease',
          'High blood pressure',
          'Diabetes',
          'Joint conditions (e.g., arthritis)',
          'Respiratory issues (e.g., asthma)',
          'Prefer not to say',
          'I have none of the above',
        ],
        selected: state.answers['health_conditions'] ?? const [],
        onChanged:
            (list) => bloc.add(
              QuestionnaireAnswerUpdated(
                questionId: 'health_conditions',
                selectedOptions: list,
              ),
            ),
      ),
      _MultiChoiceQuestion(
        questionId: 'injuries',
        title:
            'Do you have any current or past injuries that affect your ability to exercise?',
        options: const [
          'Shoulder',
          'Lower back',
          'Knee',
          'Ankle',
          'Wrist',
          'Prefer not to say',
          'I have no injuries',
        ],
        selected: state.answers['injuries'] ?? const [],
        onChanged:
            (list) => bloc.add(
              QuestionnaireAnswerUpdated(
                questionId: 'injuries',
                selectedOptions: list,
              ),
            ),
      ),
      _SingleChoiceQuestion(
        questionId: 'days_per_week',
        title: 'How many days per week can you commit to working out?',
        options: const ['1-2 days', '3-4 days', '5-7 days'],
        selected: state.answers['days_per_week']?.first,
        onChanged:
            (v) => bloc.add(
              QuestionnaireAnswerUpdated(
                questionId: 'days_per_week',
                selectedOptions: [if (v != null) v],
              ),
            ),
      ),
      _SingleChoiceQuestion(
        questionId: 'session_length',
        title: 'How long are your typical workout sessions?',
        options: const [
          'Less than 30 minutes',
          '30-60 minutes',
          '60-90 minutes',
          'More than 90 minutes',
        ],
        selected: state.answers['session_length']?.first,
        onChanged:
            (v) => bloc.add(
              QuestionnaireAnswerUpdated(
                questionId: 'session_length',
                selectedOptions: [if (v != null) v],
              ),
            ),
      ),
      _MultiChoiceQuestion(
        questionId: 'enjoy_types',
        title: 'Which types of exercise do you enjoy?',
        options: const [
          'Weightlifting / Strength training',
          'Bodyweight exercises',
          'Running / Jogging',
          'Swimming',
          'Cycling',
          'Yoga / Pilates',
          'Team sports',
        ],
        selected: state.answers['enjoy_types'] ?? const [],
        onChanged:
            (list) => bloc.add(
              QuestionnaireAnswerUpdated(
                questionId: 'enjoy_types',
                selectedOptions: list,
              ),
            ),
      ),
      _SingleChoiceQuestion(
        questionId: 'equipment_access',
        title: 'Do you have access to a gym or workout equipment?',
        options: const [
          'Yes, I have access to a fully equipped gym',
          'Yes, I have some basic equipment at home (e.g., dumbbells, resistance bands)',
          'No, I prefer bodyweight exercises or outdoor activities',
        ],
        selected: state.answers['equipment_access']?.first,
        onChanged:
            (v) => bloc.add(
              QuestionnaireAnswerUpdated(
                questionId: 'equipment_access',
                selectedOptions: [if (v != null) v],
              ),
            ),
      ),
    ];

    // Controls underneath
    const multiIds = {'health_conditions', 'injuries', 'enjoy_types'};
    final pageIds = <String>[
      'goal',
      'experience',
      'health_conditions',
      'injuries',
      'days_per_week',
      'session_length',
      'enjoy_types',
      'equipment_access',
    ];

    return List.generate(pages.length, (index) {
      final item = pages[index];
      final isLast = index == pages.length - 1;
      final qid = pageIds[index];
      final selected = state.answers[qid] ?? const <String>[];
      final canProceed =
          multiIds.contains(qid) ? selected.isNotEmpty : selected.length == 1;
      return _QuestionWrapper(
        onBack: () async {
          if (index == 0) {
            // Go back to begin view
            setState(() => _begun = false);
            return;
          }
          final pg = _pageController.page?.round() ?? 0;
          if (pg > 0) {
            await _pageController.previousPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        },
        onNext: () async {
          final pg = _pageController.page?.round() ?? 0;
          if (pg < pages.length - 1) {
            await _pageController.nextPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          } else {
            // Submit
            context.read<QuestionnaireBloc>().add(QuestionnaireSubmitted());
          }
        },
        isLast: isLast,
        enabled: canProceed,
        child: item,
      );
    });
  }
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = (current / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text('$current of $total', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _QuestionWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isLast;
  final bool enabled;
  const _QuestionWrapper({
    required this.child,
    required this.onBack,
    required this.onNext,
    required this.isLast,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: enabled ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(isLast ? 'Submit' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

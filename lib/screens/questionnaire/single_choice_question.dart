part of 'questionnaire_screen.dart';

class _SingleChoiceQuestion extends StatelessWidget {
  final String questionId;
  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _SingleChoiceQuestion({
    required this.questionId,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          ...options.map(
            (o) => RadioListTile<String>(
              value: o,
              groupValue: selected,
              onChanged: onChanged,
              title: Text(o),
            ),
          ),
        ],
      ),
    );
  }
}

part of 'questionnaire_screen.dart';

class _MultiChoiceQuestion extends StatefulWidget {
  final String questionId;
  final String title;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  const _MultiChoiceQuestion({
    required this.questionId,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_MultiChoiceQuestion> createState() => _MultiChoiceQuestionState();
}

class _MultiChoiceQuestionState extends State<_MultiChoiceQuestion> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selected);
  }

  @override
  void didUpdateWidget(covariant _MultiChoiceQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _selected = List<String>.from(widget.selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          ...widget.options.map((o) {
            final checked = _selected.contains(o);
            return CheckboxListTile(
              value: checked,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selected.add(o);
                  } else {
                    _selected.remove(o);
                  }
                });
                widget.onChanged(_selected);
              },
              title: Text(o),
            );
          }).toList(),
        ],
      ),
    );
  }
}

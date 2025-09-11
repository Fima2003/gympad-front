part of 'save_workout_screen.dart';

class SaveWorkoutInfoView extends StatefulWidget {
  final void Function(String) onNameChanged;
  final void Function(String) onDescriptionChanged;
  final String initialName;
  final String initialDescription;
  final String? nameError;
  final String? descriptionError;
  const SaveWorkoutInfoView({
    super.key,
    required this.onNameChanged,
    required this.onDescriptionChanged,
    required this.initialName,
    required this.initialDescription,
    this.nameError,
    this.descriptionError,
  });

  @override
  State<SaveWorkoutInfoView> createState() => _SaveWorkoutInfoViewState();
}

class _SaveWorkoutInfoViewState extends State<SaveWorkoutInfoView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _descCtrl = TextEditingController(text: widget.initialDescription);
  }

  @override
  void didUpdateWidget(covariant SaveWorkoutInfoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialName != widget.initialName &&
        _nameCtrl.text != widget.initialName) {
      _nameCtrl.text = widget.initialName;
    }
    if (oldWidget.initialDescription != widget.initialDescription &&
        _descCtrl.text != widget.initialDescription) {
      _descCtrl.text = widget.initialDescription;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameCtrl,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Workout Name',
            border: const OutlineInputBorder(),
            errorText: widget.nameError,
          ),
          onChanged: widget.onNameChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          maxLines: 4,
          minLines: 2,
          decoration: InputDecoration(
            labelText: 'Workout Description',
            border: const OutlineInputBorder(),
            errorText: widget.descriptionError,
          ),
          onChanged: widget.onDescriptionChanged,
        ),
      ],
    );
  }
}

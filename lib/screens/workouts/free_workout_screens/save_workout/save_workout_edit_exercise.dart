part of 'save_workout_screen.dart';

class SaveWorkoutEditExerciseWidget extends StatefulWidget {
  final List<WorkoutSet> sets;
  final String exerciseName;
  final void Function(List<WorkoutSet>) onDone;
  const SaveWorkoutEditExerciseWidget({
    super.key,
    required this.sets,
    required this.exerciseName,
    required this.onDone,
  });

  @override
  State<SaveWorkoutEditExerciseWidget> createState() =>
      _SaveWorkoutEditExerciseWidgetState();
}

class _SaveWorkoutEditExerciseWidgetState
    extends State<SaveWorkoutEditExerciseWidget> {
  late List<WorkoutSet> _sets; // mutable working copy
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _timeControllers = {};

  @override
  void initState() {
    super.initState();
    _sets = widget.sets.map((s) => s).toList();
    _initControllers();
  }

  void _initControllers() {
    for (var i = 0; i < _sets.length; i++) {
      _repsControllers[i] = TextEditingController(
        text: _sets[i].reps.toString(),
      );
      _weightControllers[i] = TextEditingController(
        text: _weightToStr(_sets[i].weight),
      );
      _timeControllers[i] = TextEditingController(
        text: _sets[i].time.inSeconds.toString(),
      );
    }
  }

  String _weightToStr(double w) {
    if (w == w.roundToDouble()) return w.toInt().toString();
    // ensure .5 formatting only
    if ((w * 10).round() % 5 == 0) {
      // keep one decimal
      return w.toStringAsFixed(1);
    }
    return w.toString();
  }

  void _addSet() {
    setState(() {
      // Seed with the latest visible (edited) values from the last row, if any
      WorkoutSet base;
      if (_sets.isNotEmpty) {
        final lastIdx = _sets.length - 1;
        final reps =
            int.tryParse(_repsControllers[lastIdx]?.text.trim() ?? '') ??
            _sets[lastIdx].reps;
        final timeSec =
            int.tryParse(_timeControllers[lastIdx]?.text.trim() ?? '') ??
            _sets[lastIdx].time.inSeconds;
        final weightParsed = _parseWeight(
          _weightControllers[lastIdx]?.text.trim() ?? '',
        );
        final weight = weightParsed ?? _sets[lastIdx].weight;
        base = _sets[lastIdx].copyWith(
          reps: reps,
          time: Duration(seconds: timeSec),
          weight: weight,
        );
      } else {
        base = const WorkoutSet(
          setNumber: 0,
          reps: 10,
          weight: 0,
          time: Duration(seconds: 60),
        );
      }

      final newSet = WorkoutSet(
        setNumber: _sets.length + 1,
        reps: base.reps,
        weight: base.weight,
        time: base.time,
      );
      _sets.add(newSet);
      final idx = _sets.length - 1;
      _repsControllers[idx] = TextEditingController(
        text: newSet.reps.toString(),
      );
      _weightControllers[idx] = TextEditingController(
        text: _weightToStr(newSet.weight),
      );
      _timeControllers[idx] = TextEditingController(
        text: newSet.time.inSeconds.toString(),
      );
    });
  }

  void _removeSet(int index) {
    if (_sets.length == 1) return;
    setState(() {
      _sets.removeAt(index);
      _repsControllers.remove(index)?.dispose();
      _weightControllers.remove(index)?.dispose();
      _timeControllers.remove(index)?.dispose();
      // Re-index controllers & sets
      final newSets = <WorkoutSet>[];
      final newReps = <int, TextEditingController>{};
      final newWeight = <int, TextEditingController>{};
      final newTime = <int, TextEditingController>{};
      for (var i = 0; i < _sets.length; i++) {
        final updated = _sets[i].copyWith(setNumber: i + 1);
        newSets.add(updated);
        newReps[i] =
            _repsControllers[i >= index ? i + 1 : i] ??
            TextEditingController(text: updated.reps.toString());
        newWeight[i] =
            _weightControllers[i >= index ? i + 1 : i] ??
            TextEditingController(text: _weightToStr(updated.weight));
        newTime[i] =
            _timeControllers[i >= index ? i + 1 : i] ??
            TextEditingController(text: updated.time.inSeconds.toString());
      }
      _sets = newSets;
      _repsControllers
        ..clear()
        ..addAll(newReps);
      _weightControllers
        ..clear()
        ..addAll(newWeight);
      _timeControllers
        ..clear()
        ..addAll(newTime);
    });
  }

  void _commitField(int index) {
    final repsStr = _repsControllers[index]?.text.trim() ?? '';
    var weightStr = _weightControllers[index]?.text.trim() ?? '';
    final timeStr = _timeControllers[index]?.text.trim() ?? '';

    // Normalize weight: allow trailing '.' while typing, but drop it on commit
    if (weightStr.endsWith('.')) {
      weightStr = weightStr.substring(0, weightStr.length - 1);
      final ctrl = _weightControllers[index]!;
      final selection = TextSelection.collapsed(offset: weightStr.length);
      ctrl.value = TextEditingValue(text: weightStr, selection: selection);
    }

    final reps = int.tryParse(repsStr);
    final time = int.tryParse(timeStr);
    final weight = _parseWeight(weightStr);

    if (reps != null && time != null && weight != null) {
      setState(() {
        _sets[index] = _sets[index].copyWith(
          reps: reps,
          weight: weight,
          time: Duration(seconds: time),
        );
      });
    }
  }

  double? _parseWeight(String v) {
    if (v.isEmpty) return 0;
    // Accept integers or X.5
    final normalized = v.replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.5)?$').hasMatch(normalized)) return null;
    return double.tryParse(normalized);
  }

  bool get _hasInvalidInput {
    for (var i = 0; i < _sets.length; i++) {
      final reps = int.tryParse(_repsControllers[i]?.text ?? '');
      final time = int.tryParse(_timeControllers[i]?.text ?? '');
      final weightOk = _parseWeight(_weightControllers[i]?.text ?? '') != null;
      if (reps == null || reps <= 0) return true;
      if (time == null || time < 0) return true;
      if (!weightOk) return true;
    }
    return false;
  }

  void _onDone() {
    // Final commit for all
    for (var i = 0; i < _sets.length; i++) {
      _commitField(i);
    }
    if (_hasInvalidInput) return; // silently block; could show snackbar
    // Ensure sequential numbering
    final result = <WorkoutSet>[];
    for (var i = 0; i < _sets.length; i++) {
      result.add(_sets[i].copyWith(setNumber: i + 1));
    }
    widget.onDone(result);
  }

  @override
  void dispose() {
    for (final c in _repsControllers.values) c.dispose();
    for (final c in _weightControllers.values) c.dispose();
    for (final c in _timeControllers.values) c.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {bool error = false}) =>
      InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        errorText: error ? '' : null,
        counterText: '',
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.exerciseName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var i = 0; i < _sets.length; i++) _buildSetRow(i),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _addSet,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Set'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _hasInvalidInput ? null : _onDone,
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetRow(int index) {
    final repsCtrl = _repsControllers[index]!;
    final weightCtrl = _weightControllers[index]!;
    final timeCtrl = _timeControllers[index]!;
    final invalidReps =
        int.tryParse(repsCtrl.text) == null ||
        int.tryParse(repsCtrl.text)! <= 0;
    final invalidTime = int.tryParse(timeCtrl.text) == null;
    final invalidWeight = _parseWeight(weightCtrl.text) == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '#${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          if (!hasFocus) _commitField(index);
                        },
                        child: TextField(
                          controller: repsCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          decoration: _decoration('Reps', error: invalidReps),
                          onChanged: (_) => setState(() {}),
                          onEditingComplete: () => _commitField(index),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          if (!hasFocus) _commitField(index);
                        },
                        child: TextField(
                          controller: weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          maxLength: 6,
                          inputFormatters: [_WeightHalfStepsFormatter()],
                          decoration: _decoration(
                            'Weight',
                            error: invalidWeight,
                          ),
                          onChanged: (_) => setState(() {}),
                          onEditingComplete: () => _commitField(index),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          if (!hasFocus) _commitField(index);
                        },
                        child: TextField(
                          controller: timeCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          decoration: _decoration('Time s', error: invalidTime),
                          onChanged: (_) => setState(() {}),
                          onEditingComplete: () => _commitField(index),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip:
                        _sets.length == 1
                            ? 'Cannot remove last set'
                            : 'Remove set',
                    icon: Icon(
                      Icons.delete,
                      color: _sets.length == 1 ? Colors.grey : Colors.red,
                    ),
                    onPressed:
                        _sets.length == 1 ? null : () => _removeSet(index),
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

class _WeightHalfStepsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '.');
    if (text.isEmpty) return newValue;
    // Allow pure integers
    if (RegExp(r'^\d+$').hasMatch(text)) return newValue;
    // Allow a trailing dot during typing
    if (RegExp(r'^\d+\.$').hasMatch(text)) return newValue.copyWith(text: text);
    // Allow X.5 only
    if (RegExp(r'^\d+\.5$').hasMatch(text))
      return newValue.copyWith(text: text);
    return oldValue; // reject other changes
  }
}

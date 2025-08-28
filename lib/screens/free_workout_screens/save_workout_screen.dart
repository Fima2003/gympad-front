import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../blocs/personal_workouts/personal_workout_bloc.dart';
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/workout_set.dart';
import '../../services/api/workout_api_service.dart';
import '../../services/api/models/workout_models.dart';
import '../../constants/app_styles.dart';

class SaveWorkoutScreen extends StatefulWidget {
  final Workout workout;
  const SaveWorkoutScreen({super.key, required this.workout});

  @override
  State<SaveWorkoutScreen> createState() => _SaveWorkoutScreenState();
}

class _SaveWorkoutScreenState extends State<SaveWorkoutScreen> {
  late List<WorkoutExercise> _exercises;
  int? _editingIndex;
  bool _showForm = false;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _nameError;
  String? _descError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _exercises = List<WorkoutExercise>.from(widget.workout.exercises);
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
      if (_editingIndex == index) _editingIndex = null;
    });
  }

  void _openEditPanel(int index) {
    setState(() {
      _editingIndex = index;
    });
  }

  void _closeEditPanel() {
    setState(() {
      _editingIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Save Workout',
          style: AppTextStyles.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _showForm ? 'NAME YOUR WORKOUT' : 'REVIEW & ADJUST',
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child:
                      _showForm
                          ? _buildFormCard()
                          : Stack(
                            children: [
                              _buildListCard(),
                              if (_editingIndex != null)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: _closeEditPanel,
                                    child: Container(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      child: Center(
                                        child: _EditExercisePanel(
                                          exercise: _exercises[_editingIndex!],
                                          onClose: _closeEditPanel,
                                          onUpdate: (updated) {
                                            setState(() {
                                              _exercises[_editingIndex!] =
                                                  updated;
                                              _editingIndex = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed:
                            _showForm
                                ? () => setState(() => _showForm = false)
                                : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'BACK',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            !_showForm
                                ? () => setState(() => _showForm = true)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1a1a1a),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'CONTINUE',
                          style: AppTextStyles.button.copyWith(
                            color: const Color(0xFF1a1a1a),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _showForm && !_isSaving ? _saveWorkout : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isSaving
                          ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            'SAVE',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORKOUT NAME',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
            ],
            decoration: InputDecoration(
              hintText: 'e.g. Upper Body Blast',
              hintStyle: const TextStyle(color: Colors.white54),
              errorText: _nameError,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
            maxLength: 100,
          ),
          const SizedBox(height: 12),
          Text(
            'DESCRIPTION (OPTIONAL)',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descController,
            style: const TextStyle(color: Colors.white),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z \n]')),
            ],
            decoration: InputDecoration(
              hintText: 'Add a brief description...',
              hintStyle: const TextStyle(color: Colors.white54),
              errorText: _descError,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
            maxLength: 200,
            minLines: 3,
            maxLines: 6,
          ),
        ],
      ),
    );
  }

  // Form UI is rendered inline via _buildFormArea usage in the tree

  Widget _buildListCard() {
    return Container(
      key: const ValueKey('list'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListView.separated(
        itemCount: _exercises.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final ex = _exercises[index];
          final avgWeight = ex.averageWeight.toStringAsFixed(1);
          final reps =
              ex.sets.isNotEmpty
                  ? ex.sets.map((s) => s.reps).reduce((a, b) => a + b) ~/
                      ex.sets.length
                  : 0;
          final breakTime = ex.sets.length > 1 ? _estimateRestTime(ex.sets) : 0;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openEditPanel(index),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.name.toUpperCase(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            _StatChip(
                              label: 'SETS',
                              value: ex.sets.length.toString(),
                            ),
                            _StatChip(
                              label: 'AVG REPS',
                              value: reps.toString(),
                            ),
                            _StatChip(label: 'REST', value: '${breakTime}s'),
                            _StatChip(label: 'AVG W', value: '$avgWeight kg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _removeExercise(index),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveWorkout() async {
    // Validate
    setState(() {
      _nameError = null;
      _descError = null;
    });
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final nameValid = RegExp(r'^[A-Za-z .,!]{6,100}$').hasMatch(name);
    final descValid =
        desc.isEmpty || RegExp(r'^[A-Za-z .,!\n]{10,200}$').hasMatch(desc);
    if (!nameValid) {
      setState(
        () =>
            _nameError =
                'Name must be 6-100 English letters and punctuation(. , !)',
      );
      return;
    }
    if (!descValid) {
      setState(
        () =>
            _descError =
                'Description must be 10-200 English letters and punctuation(. , !)',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final exercisesDto =
          _exercises.map((ex) {
            final reps =
                ex.sets.isNotEmpty
                    ? ex.sets.map((s) => s.reps).reduce((a, b) => a + b) ~/
                        ex.sets.length
                    : 0;
            final avgWeight =
                ex.sets.isNotEmpty
                    ? ex.sets.map((s) => s.weight).reduce((a, b) => a + b) /
                        ex.sets.length
                    : 0.0;
            final restTime =
                ex.sets.length > 1 ? _estimateRestTime(ex.sets) : 0;
            return PersonalWorkoutExerciseDto(
              exerciseId: ex.exerciseId,
              name: ex.name,
              sets: ex.sets.length,
              reps: reps,
              weight: avgWeight,
              restTime: restTime,
            );
          }).toList();

      var finalName = name;

      final req = CreatePersonalWorkoutRequest(
        name: finalName,
        description: desc.isNotEmpty ? desc : null,
        exercises: exercisesDto,
      );

      final resp = await WorkoutApiService().createPersonalWorkout(req);
      if (resp.success) {
        // Refresh personal workouts via BLoC
        if (mounted) {
          context.read<PersonalWorkoutBloc>().add(RequestSync());
        }
        _showToast('Created a custom workout', goHome: true);
      } else {
        _showToast('Something went wrong. Try again later', goHome: false);
      }
    } catch (e) {
      _showToast('Something went wrong. Try again later', goHome: false);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showToast(String msg, {bool goHome = false}) {
    final snackBar = SnackBar(
      content: Text(msg),
      action:
          goHome
              ? SnackBarAction(
                label: 'Go Home',
                onPressed:
                    () => Navigator.of(context).popUntil((r) => r.isFirst),
              )
              : null,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    if (goHome) {
      Future.delayed(
        const Duration(seconds: 3),
        () => Navigator.of(context).popUntil((r) => r.isFirst),
      );
    }
  }

  int _estimateRestTime(List sets) {
    // Dummy: returns 60 for now, can be improved with real rest tracking
    return 60;
  }
}

class _EditExercisePanel extends StatefulWidget {
  final WorkoutExercise exercise;
  final VoidCallback onClose;
  final ValueChanged<WorkoutExercise> onUpdate;
  const _EditExercisePanel({
    required this.exercise,
    required this.onClose,
    required this.onUpdate,
  });

  @override
  State<_EditExercisePanel> createState() => _EditExercisePanelState();
}

class _EditExercisePanelState extends State<_EditExercisePanel> {
  late List<WorkoutSet> sets;

  @override
  void initState() {
    super.initState();
    sets = List.from(widget.exercise.sets);
  }

  void _updateSet(int i, int reps, double weight) {
    setState(() {
      sets[i] = sets[i].copyWith(reps: reps, weight: weight);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exercise.name.toUpperCase(),
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(sets.length, (i) {
              final s = sets[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SET ${i + 1}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: s.reps.toString(),
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Reps',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final reps = int.tryParse(val) ?? s.reps;
                          _updateSet(i, reps, s.weight);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: s.weight.toString(),
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (val) {
                          final weight = double.tryParse(val) ?? s.weight;
                          _updateSet(i, s.reps, weight);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: widget.onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'CANCEL',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    widget.onUpdate(
                      widget.exercise.copyWith(
                        sets: List<WorkoutSet>.from(sets),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'SAVE',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

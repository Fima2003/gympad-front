import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../constants/app_styles.dart';
import '../../../../../blocs/data/data_bloc.dart';
import '../../../../../models/exercise.dart';

/// Stateless-ish (internally stateful for filters) selection view for free workout.
/// Extracted from the legacy `SelectExerciseScreen` to be embedded directly
/// inside the upcoming `FreeWorkoutRunScreen` without navigation pushes.
class FreeWorkoutSelectionView extends StatefulWidget {
  final String? initialMuscleGroup;
  final void Function(Exercise exercise) onExerciseChosen;
  final VoidCallback? onExit; // optional (e.g., to pop selection mode)

  const FreeWorkoutSelectionView({
    super.key,
    this.initialMuscleGroup,
    required this.onExerciseChosen,
    this.onExit,
  });

  @override
  State<FreeWorkoutSelectionView> createState() => _FreeWorkoutSelectionViewState();
}

class _FreeWorkoutSelectionViewState extends State<FreeWorkoutSelectionView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedGroup;
  String _searchQuery = '';
  List<Exercise> _filtered = [];

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.initialMuscleGroup;
    _recompute();
  }

  void _recompute() {
    final dataState = context.read<DataBloc>().state;
    if (dataState is! DataReady) {
      setState(() => _filtered = []);
      return;
    }
    final all = dataState.exercises.values.toList();
    if (_searchQuery.isNotEmpty) {
      _filtered = all.where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()) || e.muscleGroup.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    } else if (_selectedGroup != null) {
      _filtered = all.where((e) => e.muscleGroup == _selectedGroup).toList();
    } else {
      _filtered = [];
    }
    setState(() {});
  }

  void _onSearchChanged(String q) {
    _searchQuery = q;
    _recompute();
  }

  void _selectGroup(String group) {
    _selectedGroup = group;
    _searchQuery = '';
    _searchController.clear();
    _recompute();
  }

  void _clearGroupSelection() {
    if (_selectedGroup == null) return;
    _selectedGroup = null;
    _searchQuery = '';
    _searchController.clear();
    _recompute();
  }

  @override
  Widget build(BuildContext context) {
    final dataState = context.watch<DataBloc>().state;
    Set<String> muscleGroups = {};
    if (dataState is DataReady) {
      muscleGroups = dataState.exercises.values.map((e) => e.muscleGroup).toSet();
    }

    return Column(
      children: [
        if (_selectedGroup != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _clearGroupSelection,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: Icon(Icons.arrow_back, color: AppColors.primary, size: 18),
                label: Text(
                  'Back to Muscle Groups',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search exercises or muscle groups...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
          ),
        ),
        Expanded(child: _buildContent(muscleGroups, dataState)),
      ],
    );
  }

  Widget _buildContent(Set<String> muscleGroups, DataState dataState) {
    if (_searchQuery.isNotEmpty) {
      return _buildExerciseGrid(_filtered);
    } else if (_selectedGroup != null) {
      return _buildExerciseGrid(_filtered);
    } else {
      return _buildGroupGrid(muscleGroups, dataState);
    }
  }

  Widget _buildGroupGrid(Set<String> groups, DataState dataState) {
    List<Exercise> all = [];
    if (dataState is DataReady) all = dataState.exercises.values.toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: groups.length,
        itemBuilder: (ctx, i) {
          final g = groups.elementAt(i);
          final count = all.where((e) => e.muscleGroup == g).length;
          return _groupCard(g, count);
        },
      ),
    );
  }

  Widget _groupCard(String group, int exerciseCount) {
    return GestureDetector(
      onTap: () => _selectGroup(group),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.category,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                group.toUpperCase(),
                style: AppTextStyles.titleSmall.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$exerciseCount exercises',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseGrid(List<Exercise> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No exercises found',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: list.length,
        itemBuilder: (ctx, i) => _exerciseCard(list[i]),
      ),
    );
  }

  Widget _exerciseCard(Exercise e) {
    return GestureDetector(
      onTap: () => widget.onExerciseChosen(e),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.fitness_center, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                e.name,
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  e.muscleGroup.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

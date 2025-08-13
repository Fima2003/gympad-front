import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_styles.dart';
import '../models/exercise.dart';
import '../services/data_service.dart';
import '../blocs/workout_bloc.dart';
import 'free_workout_screens/exercise_screen.dart';

class MultiPurposeEquipmentScreen extends StatefulWidget {
  const MultiPurposeEquipmentScreen({super.key});

  @override
  State<MultiPurposeEquipmentScreen> createState() => _MultiPurposeEquipmentScreenState();
}

class _MultiPurposeEquipmentScreenState extends State<MultiPurposeEquipmentScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _searchController = TextEditingController();
  
  String? _selectedGroup;
  List<Exercise> _filteredExercises = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _updateFilteredExercises();
  }

  void _updateFilteredExercises() {
    final ropeExercises = _dataService.getRopeExercises();
    
    if (_searchQuery.isNotEmpty) {
      _filteredExercises = ropeExercises.where((exercise) {
        return exercise.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               exercise.muscleGroup.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    } else if (_selectedGroup != null) {
      _filteredExercises = ropeExercises.where((exercise) {
        return exercise.muscleGroup == _selectedGroup;
      }).toList();
    } else {
      _filteredExercises = [];
    }
    
    setState(() {});
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _updateFilteredExercises();
  }

  void _selectMuscleGroup(String group) {
    setState(() {
      _selectedGroup = group;
      _searchQuery = '';
      _searchController.clear();
    });
    _updateFilteredExercises();
  }

  void _goBack() {
    if (_selectedGroup != null) {
      setState(() {
        _selectedGroup = null;
        _searchQuery = '';
        _searchController.clear();
      });
      _updateFilteredExercises();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _selectExercise(Exercise exercise) {
    // Add exercise to workout
    context.read<WorkoutBloc>().add(ExerciseAdded(
      exerciseId: exercise.id,
      name: exercise.name,
      muscleGroup: exercise.muscleGroup,
      equipmentId: '40938', // Ropes equipment ID
    ));
    
    // Navigate to exercise screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseScreen(
          exercise: exercise,
          isPartOfWorkout: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ropeMuscleGroups = _dataService.getRopeMuscleGroups();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: _goBack,
        ),
        title: Text(
          _selectedGroup != null ? _selectedGroup!.toUpperCase() : 'ROPE EXERCISES',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search rope exercises...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
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
          
          Expanded(
            child: _buildContent(ropeMuscleGroups),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<String> muscleGroups) {
    if (_searchQuery.isNotEmpty) {
      return _buildExerciseGrid(_filteredExercises);
    } else if (_selectedGroup != null) {
      return _buildExerciseGrid(_filteredExercises);
    } else {
      return _buildMuscleGroupGrid(muscleGroups);
    }
  }

  Widget _buildMuscleGroupGrid(List<String> muscleGroups) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: muscleGroups.length,
        itemBuilder: (context, index) {
          final group = muscleGroups[index];
          final ropeExercises = _dataService.getRopeExercises();
          final exerciseCount = ropeExercises.where((e) => e.muscleGroup == group).length;
          
          return _buildMuscleGroupCard(group, exerciseCount);
        },
      ),
    );
  }

  Widget _buildMuscleGroupCard(String group, int exerciseCount) {
    return GestureDetector(
      onTap: () => _selectMuscleGroup(group),
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
          padding: const EdgeInsets.all(16.0),
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
                  Icons.fitness_center,
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
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseGrid(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No rope exercises found',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return _buildExerciseCard(exercise);
        },
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return GestureDetector(
      onTap: () => _selectExercise(exercise),
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
          padding: const EdgeInsets.all(12.0),
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
                child: Icon(
                  Icons.accessibility,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                exercise.name,
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
                  'ROPES',
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
}

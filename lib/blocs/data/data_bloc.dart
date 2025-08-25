import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/equipment.dart';
import '../../models/exercise.dart';
import '../../services/data_service.dart';
import '../../services/logger_service.dart';

part 'data_event.dart';
part 'data_state.dart';

class DataBloc extends Bloc<DataEvent, DataState> {
  final DataService _dataService;
  final AppLogger _logger;
  DataBloc({DataService? dataService, AppLogger? logger})
    : _dataService = dataService ?? DataService(),
      _logger = logger ?? AppLogger(),
      super(const DataInitial()) {
    on<DataLoadRequested>(_onLoadRequested);
    on<DataRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    DataLoadRequested event,
    Emitter<DataState> emit,
  ) async {
    if (state is DataReady) return;
    emit(const DataLoading());
    try {
      await _dataService.loadData();
      emit(
        DataReady(
          exercises: _dataService.exercisesMap,
          equipment: _dataService.equipmentMap,
        ),
      );
    } catch (e, st) {
      _logger.error('Data load failed', e, st);
      emit(DataError('Failed to load data', error: e));
    }
  }

  Future<void> _onRefreshRequested(
    DataRefreshRequested event,
    Emitter<DataState> emit,
  ) async {
    emit(const DataLoading());
    try {
      await _dataService.forceReload();
      emit(
        DataReady(
          exercises: _dataService.exercisesMap,
          equipment: _dataService.equipmentMap,
        ),
      );
    } catch (e, st) {
      _logger.error('Data refresh failed', e, st);
      emit(DataError('Failed to refresh data', error: e));
    }
  }
}

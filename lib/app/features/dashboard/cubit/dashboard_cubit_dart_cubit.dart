import 'package:bloc/bloc.dart';
import 'package:score_board/app/features/dashboard/cubit/dashboard_cubit_dart_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());

  Future<void> loadDashboardData() async {
    emit(state.copyWith(status: DashboardStatus.loading));
    // Simulate network request
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, fetch data here
    // For now, just transition to success
    emit(state.copyWith(status: DashboardStatus.success));
    // Or handle failure:
    // emit(state.copyWith(status: DashboardStatus.failure, error: "Failed to load data"));
  }
}
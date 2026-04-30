import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/utils/app_errors.dart';
import 'package:liquid_soap_tracker/features/admin_logs/models/activity_log_entry.dart';
import 'package:liquid_soap_tracker/features/admin_logs/repository/admin_logs_repository.dart';

class AdminLogsState {
  const AdminLogsState({
    this.logs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 0,
    this.hasMore = true,
    this.eventTypeFilter,
  });

  final List<ActivityLogEntry> logs;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final bool hasMore;
  final String? eventTypeFilter;

  AdminLogsState copyWith({
    List<ActivityLogEntry>? logs,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    String? eventTypeFilter,
  }) {
    return AdminLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      eventTypeFilter: eventTypeFilter ?? this.eventTypeFilter,
    );
  }
}

class AdminLogsController extends StateNotifier<AdminLogsState> {
  AdminLogsController(this._repo) : super(const AdminLogsState()) {
    load();
  }

  final AdminLogsRepository _repo;

  Future<void> load({String? eventTypeFilter}) async {
    state = AdminLogsState(isLoading: true, eventTypeFilter: eventTypeFilter);
    try {
      final logs = await _repo.fetchLogs(page: 0, eventTypeFilter: eventTypeFilter);
      state = state.copyWith(
        isLoading: false,
        logs: logs,
        currentPage: 0,
        hasMore: logs.length == AdminLogsRepository.pageSize,
        eventTypeFilter: eventTypeFilter,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: AppErrors.humanize(e));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    try {
      final more = await _repo.fetchLogs(
        page: nextPage,
        eventTypeFilter: state.eventTypeFilter,
      );
      state = state.copyWith(
        isLoadingMore: false,
        logs: [...state.logs, ...more],
        currentPage: nextPage,
        hasMore: more.length == AdminLogsRepository.pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: AppErrors.humanize(e));
    }
  }
}

final adminLogsControllerProvider =
    StateNotifierProvider.autoDispose<AdminLogsController, AdminLogsState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final repo = AdminLogsRepository(client);
  return AdminLogsController(repo);
});

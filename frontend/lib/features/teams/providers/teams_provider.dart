import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/team_repository.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/application_model.dart';
import '../../auth/providers/auth_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final teamRepositoryProvider =
    Provider<TeamRepository>((ref) => TeamRepository());

// ── Live stream of all open teams ─────────────────────────────────────────────

final teamsStreamProvider = StreamProvider<List<TeamModel>>((ref) {
  return ref.watch(teamRepositoryProvider).watchAll();
});

// ── Search query ──────────────────────────────────────────────────────────────

final teamSearchProvider = StateProvider<String>((ref) => '');

// ── Filtered teams ────────────────────────────────────────────────────────────

final filteredTeamsProvider = Provider<AsyncValue<List<TeamModel>>>((ref) {
  final query = ref.watch(teamSearchProvider).toLowerCase();
  return ref.watch(teamsStreamProvider).when(
    data: (teams) {
      if (query.isEmpty) return AsyncData(teams);
      return AsyncData(teams.where((t) =>
        t.name.toLowerCase().contains(query) ||
        t.shortDescription.toLowerCase().contains(query) ||
        t.skillsNeeded.any((s) => s.toLowerCase().contains(query))
      ).toList());
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

// ── Single team by ID ─────────────────────────────────────────────────────────

final teamByIdProvider =
    FutureProvider.family<TeamModel?, String>((ref, id) async {
  return ref.read(teamRepositoryProvider).getById(id);
});

// ── Applications for a specific project ───────────────────────────────────────

final projectApplicationsProvider =
    StreamProvider.family<List<ApplicationModel>, String>((ref, projectId) {
  return ref.watch(teamRepositoryProvider).watchApplications(projectId);
});

// ── Has current user applied to a project ─────────────────────────────────────

final hasAppliedProvider =
    FutureProvider.family<bool, String>((ref, projectId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return ref.read(teamRepositoryProvider).hasApplied(
        projectId: projectId,
        userId: user.id,
      );
});

// ── Team actions notifier ─────────────────────────────────────────────────────

class TeamActionsNotifier extends StateNotifier<AsyncValue<void>> {
  TeamActionsNotifier(this._repo) : super(const AsyncData(null));
  final TeamRepository _repo;

  Future<void> apply({
    required String projectId,
    required String applicantId,
    required String applicantName,
    required String selectedRole,
    required String message,
  }) async {
    state = const AsyncLoading();
    try {
      final app = ApplicationModel(
        id: '${projectId}_$applicantId',
        projectId: projectId,
        applicantId: applicantId,
        applicantName: applicantName,
        selectedRole: selectedRole,
        message: message,
        status: ApplicationStatus.pending,
        createdAt: DateTime.now(),
      );
      await _repo.apply(app);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> approve(ApplicationModel app) async {
    state = const AsyncLoading();
    try {
      await _repo.approveApplication(app);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reject(String applicationId) async {
    state = const AsyncLoading();
    try {
      await _repo.rejectApplication(applicationId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final teamActionsProvider =
    StateNotifierProvider<TeamActionsNotifier, AsyncValue<void>>(
  (ref) => TeamActionsNotifier(ref.read(teamRepositoryProvider)),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/opportunity_repository.dart';
import '../../../shared/models/opportunity_model.dart';
import '../../auth/providers/auth_provider.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final opportunityRepositoryProvider =
    Provider<OpportunityRepository>((ref) => OpportunityRepository());

// ── Live stream of all opportunities ─────────────────────────────────────────

final opportunitiesStreamProvider = StreamProvider<List<OpportunityModel>>((ref) {
  return ref.watch(opportunityRepositoryProvider).watchAll();
});

// ── Set of opportunity IDs the current user has registered for ───────────────

final userRegisteredIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value({});
  return ref
      .watch(opportunityRepositoryProvider)
      .watchUserRegisteredIds(user.id)
      .map((ids) => ids.toSet());
});

// ── Selected filter (All / Hackathon / Peer Study / Club Project) ─────────────

final feedFilterProvider = StateProvider<String>((ref) => 'All');

// ── Filtered list used by FeedScreen ─────────────────────────────────────────

final filteredOpportunitiesProvider = Provider<AsyncValue<List<OpportunityModel>>>((ref) {
  final filter = ref.watch(feedFilterProvider);
  return ref.watch(opportunitiesStreamProvider).when(
    data: (opps) {
      if (filter == 'All') return AsyncData(opps);
      return AsyncData(opps.where((o) => o.type == filter).toList());
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

// ── Actions ───────────────────────────────────────────────────────────────────

class FeedActions {
  FeedActions(this._repo, this._userId);
  final OpportunityRepository _repo;
  final String _userId;

  Future<void> rsvp(String opportunityId) =>
      _repo.rsvp(opportunityId: opportunityId, userId: _userId);

  Future<void> cancelRsvp(String opportunityId) =>
      _repo.cancelRsvp(opportunityId: opportunityId, userId: _userId);

  Future<void> createOpportunity(OpportunityModel opp) => _repo.create(opp);
}

final feedActionsProvider = Provider<FeedActions?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return FeedActions(ref.read(opportunityRepositoryProvider), user.id);
});

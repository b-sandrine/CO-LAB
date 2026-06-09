import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/opportunity_model.dart';
import '../../../shared/models/mock_data.dart';

class FeedState {
  final List<OpportunityModel> opportunities;
  final String selectedFilter;
  final bool isLoading;

  const FeedState({
    this.opportunities = const [],
    this.selectedFilter = 'All',
    this.isLoading = false,
  });

  FeedState copyWith({List<OpportunityModel>? opportunities, String? selectedFilter, bool? isLoading}) {
    return FeedState(
      opportunities: opportunities ?? this.opportunities,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<OpportunityModel> get filtered {
    if (selectedFilter == 'All') return opportunities;
    return opportunities.where((o) => o.type == selectedFilter).toList();
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(const FeedState()) {
    _load();
  }

  void _load() {
    state = state.copyWith(opportunities: MockData.opportunities);
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void toggleSave(String id) {
    final updated = state.opportunities.map((o) {
      if (o.id == id) return o.copyWith(isSaved: !o.isSaved);
      return o;
    }).toList();
    state = state.copyWith(opportunities: updated);
  }

  void requestJoin(String id) {
    final updated = state.opportunities.map((o) {
      if (o.id == id) return o.copyWith(hasRequested: true);
      return o;
    }).toList();
    state = state.copyWith(opportunities: updated);
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) => FeedNotifier());

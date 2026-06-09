import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/mock_data.dart';

class TeamsState {
  final List<TeamModel> teams;
  final String searchQuery;
  final bool isLoading;

  const TeamsState({this.teams = const [], this.searchQuery = '', this.isLoading = false});

  TeamsState copyWith({List<TeamModel>? teams, String? searchQuery, bool? isLoading}) {
    return TeamsState(
      teams: teams ?? this.teams,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<TeamModel> get filtered {
    if (searchQuery.isEmpty) return teams;
    final q = searchQuery.toLowerCase();
    return teams.where((t) =>
      t.name.toLowerCase().contains(q) ||
      t.shortDescription.toLowerCase().contains(q) ||
      t.skillsNeeded.any((s) => s.toLowerCase().contains(q))
    ).toList();
  }
}

class TeamsNotifier extends StateNotifier<TeamsState> {
  TeamsNotifier() : super(const TeamsState()) {
    state = state.copyWith(teams: MockData.teams);
  }

  void setSearch(String query) => state = state.copyWith(searchQuery: query);
}

final teamsProvider = StateNotifierProvider<TeamsNotifier, TeamsState>((ref) => TeamsNotifier());

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/teams_provider.dart';
import '../../../shared/models/team_model.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    const skillFilters = [
      'Flutter', 'Python', 'UI Design', 'React', 'Data Analysis',
      'Business', 'Marketing', 'Research', 'Finance',
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Filter by skill',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(teamSearchProvider.notifier).state = '';
                    Navigator.pop(context);
                  },
                  child: const Text('Clear',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skillFilters.map((skill) {
                return GestureDetector(
                  onTap: () {
                    ref.read(teamSearchProvider.notifier).state = skill;
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.3)),
                    ),
                    child: Text(skill,
                        style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredTeamsProvider);
    final searchQuery = ref.watch(teamSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Open Teams'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.tune,
                color: searchQuery.isNotEmpty
                    ? AppColors.primary
                    : AppColors.textPrimary),
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearch(ref),
          Expanded(
            child: filteredAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Text('Failed to load teams: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (teams) => teams.isEmpty
                  ? const Center(
                      child: Text('No teams found',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: teams.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _TeamCard(team: teams[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: (v) => ref.read(teamSearchProvider.notifier).state = v,
        decoration: const InputDecoration(
          hintText: 'Search teams or skills...',
          prefixIcon: Icon(Icons.search, size: 20),
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/teams/${team.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(team.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(team.shortDescription,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _MemberAvatars(
              initials: team.memberInitials,
              extra: team.memberCount > 3 ? team.memberCount - 3 : 0,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: team.openRoles
                  .take(2)
                  .map((r) => _NeedChip(label: 'Need: ${r.title}'))
                  .toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/teams/${team.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('View Team',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatars extends StatelessWidget {
  final List<String> initials;
  final int extra;
  const _MemberAvatars({required this.initials, required this.extra});

  @override
  Widget build(BuildContext context) {
    final shown = initials.take(3).toList();
    return SizedBox(
      height: 28,
      width: shown.length * 20.0 + 28 + (extra > 0 ? 28.0 : 0),
      child: Stack(
        children: [
          ...List.generate(
            shown.length,
            (i) => Positioned(
              left: i * 20.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFE0E0E0),
                child: Text(shown[i],
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
            ),
          ),
          if (extra > 0)
            Positioned(
              left: shown.length * 20.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.chipBackground,
                child: Text('+$extra',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ),
            ),
        ],
      ),
    );
  }
}

class _NeedChip extends StatelessWidget {
  final String label;
  const _NeedChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w500)),
    );
  }
}

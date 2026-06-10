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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
                          color: AppColors.teal.withValues(alpha: 0.4)),
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Open Teams',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: searchQuery.isNotEmpty
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      size: 22,
                    ),
                    onPressed: () => _showFilterSheet(context, ref),
                  ),
                ],
              ),
            ),

            // ── Search ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (v) =>
                      ref.read(teamSearchProvider.notifier).state = v,
                  decoration: const InputDecoration(
                    hintText: 'Search teams or skills...',
                    hintStyle: TextStyle(
                        color: AppColors.textHint, fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search, size: 20, color: AppColors.textHint),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),

            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: filteredAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Text('Failed to load teams: $e',
                      style: const TextStyle(color: AppColors.error)),
                ),
                data: (teams) => teams.isEmpty
                    ? const Center(
                        child: Text('No teams found',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15)))
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: teams.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (_, i) =>
                            _TeamCard(team: teams[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Team card ──────────────────────────────────────────────────────────────────

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + description
            Text(team.name,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(team.shortDescription,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 14),

            // Member avatars
            _MemberRow(
              initials: team.memberInitials,
              extra: team.memberCount > 3 ? team.memberCount - 3 : 0,
            ),
            const SizedBox(height: 12),

            // Need chips
            if (team.openRoles.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: team.openRoles
                    .take(2)
                    .map((r) => _NeedChip(label: 'Need: ${r.title}'))
                    .toList(),
              ),
            const SizedBox(height: 14),

            // View Team button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => context.push('/teams/${team.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Team',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member row (avatars + "+N more" text) ─────────────────────────────────────

class _MemberRow extends StatelessWidget {
  final List<String> initials;
  final int extra;
  const _MemberRow({required this.initials, required this.extra});

  @override
  Widget build(BuildContext context) {
    final shown = initials.take(3).toList();
    return Row(
      children: [
        ...shown.map((init) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFFE8E8E8),
                child: Text(init,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
            )),
        if (extra > 0) ...[
          const SizedBox(width: 2),
          Text('+$extra more',
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

// ── Need chip ─────────────────────────────────────────────────────────────────

class _NeedChip extends StatelessWidget {
  final String label;
  const _NeedChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal, width: 1.2),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.teal,
              fontWeight: FontWeight.w500)),
    );
  }
}

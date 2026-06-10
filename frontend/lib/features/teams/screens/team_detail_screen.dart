import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/teams_provider.dart';
import '../../../shared/models/team_model.dart';
import '../../auth/providers/auth_provider.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamByIdProvider(teamId));
    final hasAppliedAsync = ref.watch(hasAppliedProvider(teamId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(
            color: AppColors.textPrimary,
            onPressed: () => context.pop()),
        title: teamAsync.when(
          data: (t) => Text(t?.name ?? '',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const Text('Team'),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined,
                color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: teamAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (team) {
          if (team == null) {
            return const Center(child: Text('Team not found'));
          }
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Short description
                    Text(team.shortDescription,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 16),

                    // Member avatars with names
                    _MemberAvatarsWithNames(members: team.members),
                    const Divider(height: 32, color: AppColors.border),

                    // Project Brief
                    _sectionTitle('Project Brief'),
                    const SizedBox(height: 10),
                    Text(team.projectBrief,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.65,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 28),

                    // Open Roles
                    _sectionTitle('Open Roles'),
                    const SizedBox(height: 12),
                    if (team.openRoles.isEmpty)
                      const Text('No open roles at this time.',
                          style: TextStyle(color: AppColors.textSecondary))
                    else
                      ...team.openRoles.map((r) => _RoleCard(
                            role: r,
                            onApply: () => _showApplyModal(
                                context, team, ref,
                                preselectedRole: r.title),
                          )),
                    const SizedBox(height: 12),

                    // Skills needed
                    if (team.skillsNeeded.isNotEmpty) ...[
                      _sectionTitle('Skills needed'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: team.skillsNeeded
                            .map((s) => _SkillChip(label: s))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Sticky Apply to Join button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: hasAppliedAsync.when(
                    loading: () => const SizedBox(
                      height: 52,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    ),
                    error: (_, __) => _applyButton(
                        context, false, team, ref),
                    data: (hasApplied) =>
                        _applyButton(context, hasApplied, team, ref),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _applyButton(BuildContext context, bool hasApplied,
      TeamModel team, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: hasApplied
            ? null
            : () => _showApplyModal(context, team, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasApplied
              ? AppColors.chipBackground
              : AppColors.primary,
          foregroundColor:
              hasApplied ? AppColors.textSecondary : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          hasApplied ? 'Application Submitted ✓' : 'Apply to Join',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: hasApplied ? AppColors.textSecondary : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800));
  }

  void _showApplyModal(BuildContext context, TeamModel team, WidgetRef ref,
      {String? preselectedRole}) {
    if (team.openRoles.isEmpty) return;
    String selectedRole =
        preselectedRole ?? team.openRoles.first.title;
    final msgCtrl = TextEditingController();
    final user = ref.read(currentUserProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (_, set) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title row
                Row(
                  children: [
                    const Text('Apply to Join',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF2F3F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 17, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Role selector
                const Text('Select your role',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                    ),
                    items: team.openRoles
                        .map((r) => DropdownMenuItem(
                            value: r.title,
                            child: Text(r.title)))
                        .toList(),
                    onChanged: (v) =>
                        set(() => selectedRole = v ?? selectedRole),
                  ),
                ),
                const SizedBox(height: 18),

                // Message field
                const Text('What do you bring?',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: msgCtrl,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText:
                          'Share your relevant skills and experience...',
                      hintStyle: TextStyle(
                          color: AppColors.textHint, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Apply button
                Consumer(builder: (_, ref, __) {
                  final actionState = ref.watch(teamActionsProvider);
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: actionState.isLoading
                          ? null
                          : () async {
                              if (user == null) return;
                              await ref
                                  .read(teamActionsProvider.notifier)
                                  .apply(
                                    projectId: team.id,
                                    applicantId: user.id,
                                    applicantName: user.name,
                                    selectedRole: selectedRole,
                                    message: msgCtrl.text,
                                  );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ref.invalidate(
                                    hasAppliedProvider(team.id));
                                _showSuccessSheet(context, team.name);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: actionState.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Apply',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessSheet(BuildContext context, String teamName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 44, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            const Text(
              'Application Submitted!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Your application to $teamName has been sent. The team leader will review it shortly.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/teams');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Teams',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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

// ── Member avatars with names ──────────────────────────────────────────────────

class _MemberAvatarsWithNames extends StatelessWidget {
  final List<TeamMember> members;
  const _MemberAvatarsWithNames({required this.members});

  @override
  Widget build(BuildContext context) {
    final shown = members.take(4).toList();
    return Row(
      children: shown.map((m) => Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.chipBackground,
              child: Text(
                m.initial,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              m.name.split(' ').first,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

// ── Role card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final OpenRole role;
  final VoidCallback onApply;
  const _RoleCard({required this.role, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role.title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(role.description,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Apply for this role',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Skill chip ────────────────────────────────────────────────────────────────

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.tealLight,
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.teal,
              fontWeight: FontWeight.w500)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/teams_provider.dart';
import '../../../shared/models/team_model.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamsProvider).teams;
    final team = teams.firstWhere((t) => t.id == teamId, orElse: () => teams.first);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(team.name),
        backgroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {})],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(team.shortDescription, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                _buildMemberRow(team),
                const Divider(height: 28),
                _buildSection('Project Brief', child: Text(team.projectBrief, style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary))),
                const SizedBox(height: 24),
                _buildSection('Open Roles', child: _buildRoles(team, context)),
                const SizedBox(height: 24),
                _buildSection('Current Members', child: _buildMembers(team)),
                const SizedBox(height: 24),
                _buildSection('Skills this team needs', child: _buildSkills(team)),
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: ElevatedButton(
                onPressed: () => _showApplyModal(context, team),
                child: const Text('Apply to Join'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(TeamModel team) {
    return Row(
      children: [
        ...team.members.take(3).map((m) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            children: [
              CircleAvatar(radius: 20, backgroundColor: AppColors.chipBackground, child: Text(m.initial, style: const TextStyle(fontWeight: FontWeight.w700))),
              const SizedBox(height: 4),
              Text(m.name.split(' ').first, style: const TextStyle(fontSize: 11)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSection(String title, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildRoles(TeamModel team, BuildContext context) {
    return Column(
      children: team.openRoles.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(r.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            SizedBox(
              child: ElevatedButton(
                onPressed: () => _showApplyModal(context, team, preselectedRole: r.title),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  minimumSize: const Size(160, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Apply for this role', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildMembers(TeamModel team) {
    return Column(
      children: team.members.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(m.initial, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(m.degreeProgram, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Text(m.role, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSkills(TeamModel team) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: team.skillsNeeded.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(20)),
        child: Text(s, style: const TextStyle(fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }

  void _showApplyModal(BuildContext context, TeamModel team, {String? preselectedRole}) {
    String selectedRole = preselectedRole ?? team.openRoles.first.title;
    final msgCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (_, set) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Apply to Join', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Select your role', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(),
                  items: team.openRoles.map((r) => DropdownMenuItem(value: r.title, child: Text(r.title))).toList(),
                  onChanged: (v) => set(() => selectedRole = v ?? selectedRole),
                ),
                const SizedBox(height: 16),
                const Text('What do you bring?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: msgCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(hintText: 'Share your relevant skills and experience...'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted!')));
                  },
                  child: const Text('Apply'),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text('Your request will be reviewed by the team leader.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

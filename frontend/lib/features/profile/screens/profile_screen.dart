import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../clans/providers/clans_provider.dart';
import '../../../shared/models/mock_data.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user ?? MockData.currentUser;
    final clans = ref.watch(clansProvider);
    final userClans = clans.where((c) => user.joinedClanIds.contains(c.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildAvatar(user.initials),
            const SizedBox(height: 12),
            Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: Text('BSc ${user.degreeProgram}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 38),
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildLeadershipCard(user.leadershipPoints, user.eventsHosted, user.eventsAttended),
            const SizedBox(height: 16),
            _buildSection('My Skills', child: _buildSkillChips(user.skills)),
            const SizedBox(height: 16),
            _buildSection('My Clans', child: _buildClansList(context, userClans)),
            const SizedBox(height: 16),
            _buildSection('Upcoming RSVPs', child: _buildRsvps()),
            const SizedBox(height: 16),
            _buildSignOutButton(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String initials) {
    return CircleAvatar(
      radius: 44,
      backgroundColor: AppColors.chipBackground,
      child: Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    );
  }

  Widget _buildLeadershipCard(int points, int hosted, int attended) {
    const max = 500;
    final progress = points / max;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: AppColors.amber, size: 20),
              SizedBox(width: 6),
              Text('Leadership Points', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$points', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const TextSpan(text: ' / $max pts', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(label: 'Events Hosted: $hosted', color: AppColors.successLight, textColor: AppColors.success),
              const SizedBox(width: 8),
              _StatChip(label: 'Events Attended: $attended', color: AppColors.chipBackground, textColor: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildSkillChips(List<String> skills) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(20)),
        child: Text(s, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }

  Widget _buildClansList(BuildContext context, List clans) {
    if (clans.isEmpty) {
      return Text('No clans joined yet.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13));
    }
    return Column(
      children: clans.map((c) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Expanded(child: Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
            Text('${c.memberCount} members', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => context.push('/clans/${c.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(16)),
                child: const Text('Chat', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildRsvps() {
    final rsvps = [
      {'title': 'Tech Society Hackathon', 'date': 'Sat 14 Jun'},
      {'title': 'Peer Study Session', 'date': 'Today · 4:00 PM'},
    ];
    return Column(
      children: rsvps.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(r['date']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: const Text('Attending', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () async {
        await ref.read(authProvider.notifier).signOut();
      },
      icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
      label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _StatChip({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
    );
  }
}

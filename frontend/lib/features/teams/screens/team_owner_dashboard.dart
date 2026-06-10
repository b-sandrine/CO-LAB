import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/teams_provider.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/application_model.dart';

class TeamOwnerDashboard extends ConsumerWidget {
  const TeamOwnerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(myOwnedTeamsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Teams'),
        backgroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: teamsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (teams) {
          if (teams.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_work_outlined,
                      size: 56, color: Color(0xFFBDBDBD)),
                  SizedBox(height: 12),
                  Text('No teams created yet',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Create a team from the Teams tab',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: teams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _TeamOwnerCard(team: teams[i]),
          );
        },
      ),
    );
  }
}

class _TeamOwnerCard extends ConsumerWidget {
  final TeamModel team;
  const _TeamOwnerCard({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(projectApplicationsProvider(team.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(team.shortDescription,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${team.memberCount} members',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          appsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading applications: $e',
                  style: const TextStyle(color: AppColors.error)),
            ),
            data: (apps) {
              final pending =
                  apps.where((a) => a.status == ApplicationStatus.pending).toList();
              if (pending.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No pending applications',
                      style: TextStyle(color: AppColors.textHint)),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Text('Applications (${pending.length})',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                  ...pending.map((app) => _ApplicationRow(app: app)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ApplicationRow extends ConsumerWidget {
  final ApplicationModel app;
  const _ApplicationRow({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(teamActionsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              app.applicantName.isNotEmpty ? app.applicantName[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.applicantName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text('Role: ${app.selectedRole}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                if (app.message.isNotEmpty)
                  Text(
                    '"${app.message}"',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 28),
                tooltip: 'Approve',
                onPressed: actionState.isLoading
                    ? null
                    : () async {
                        await ref
                            .read(teamActionsProvider.notifier)
                            .approve(app);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${app.applicantName} approved!'),
                            ),
                          );
                        }
                      },
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined,
                    color: AppColors.error, size: 28),
                tooltip: 'Reject',
                onPressed: actionState.isLoading
                    ? null
                    : () async {
                        await ref
                            .read(teamActionsProvider.notifier)
                            .reject(app.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Application rejected')),
                          );
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

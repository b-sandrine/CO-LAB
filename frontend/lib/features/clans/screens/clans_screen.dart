import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../providers/clans_provider.dart';
import '../../../shared/models/clan_model.dart';

class ClansScreen extends ConsumerWidget {
  const ClansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clans = ref.watch(clansProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Clans'),
        backgroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {})],
      ),
      body: Column(
        children: [
          _buildSearch(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
              children: [
                ...clans.map((c) => _ClanTile(clan: c)),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Join a team or RSVP to unlock more Clans',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search clans...',
          prefixIcon: Icon(Icons.search, size: 20),
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _ClanTile extends StatelessWidget {
  final ClanModel clan;
  const _ClanTile({required this.clan});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/clans/${clan.id}'),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _ClanAvatar(initials: clan.initials, color: Color(clan.color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clan.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(clan.lastMessage, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeago.format(clan.lastMessageTime, allowFromNow: true), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                const SizedBox(height: 4),
                if (clan.unreadCount > 0)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Center(child: Text('${clan.unreadCount}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClanAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  const _ClanAvatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: color,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

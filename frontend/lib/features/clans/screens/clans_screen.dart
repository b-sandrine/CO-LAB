import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../providers/clans_provider.dart';
import '../../../shared/models/clan_model.dart';
import '../../auth/providers/auth_provider.dart';

class ClansScreen extends ConsumerStatefulWidget {
  const ClansScreen({super.key});

  @override
  ConsumerState<ClansScreen> createState() => _ClansScreenState();
}

class _ClansScreenState extends ConsumerState<ClansScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clansAsync = ref.watch(userClansProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Clans',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.textPrimary, size: 22),
                    onPressed: () => _showBrowseSheet(context),
                    tooltip: 'Browse & Manage Clans',
                  ),
                ],
              ),
            ),

            // ── Search bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search clans...',
                    hintStyle: const TextStyle(
                        color: AppColors.textHint, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        size: 20, color: AppColors.textHint),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: AppColors.textHint),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            })
                        : null,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // ── Clan list ───────────────────────────────────────────────────
            Expanded(
              child: clansAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) => Center(
                    child: Text('Error: $e',
                        style:
                            const TextStyle(color: AppColors.error))),
                data: (clans) {
                  final filtered = _query.isEmpty
                      ? clans
                      : clans
                          .where((c) =>
                              c.name.toLowerCase().contains(_query))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_outlined,
                                size: 52,
                                color: Colors.grey.shade200),
                            const SizedBox(height: 14),
                            const Text('No clans yet',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(
                              'Join a team or RSVP to unlock clans',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length + 1,
                    itemBuilder: (_, i) {
                      if (i == filtered.length) {
                        return _buildFooter();
                      }
                      return _ClanTile(clan: filtered[i]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Center(
        child: Text(
          'Join a team or RSVP to unlock more Clans',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.teal,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ── Browse bottom sheet ─────────────────────────────────────────────────────

  void _showBrowseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) =>
            _BrowseSheet(scrollCtrl: scrollCtrl),
      ),
    );
  }
}

// ── Clan list tile (WhatsApp style) ───────────────────────────────────────────

class _ClanTile extends StatelessWidget {
  final ClanModel clan;
  const _ClanTile({required this.clan});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => context.push('/clans/${clan.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Clan avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(clan.color),
                  child: Text(
                    clan.initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              clan.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(clan.lastMessageTime,
                                allowFromNow: true),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              clan.lastMessage.isEmpty
                                  ? 'No messages yet'
                                  : clan.lastMessage,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (clan.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            _UnreadBadge(count: clan.unreadCount),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(
            height: 1, indent: 76, color: AppColors.border),
      ],
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, maxWidth: 34),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(11)),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Browse sheet ──────────────────────────────────────────────────────────────

class _BrowseSheet extends ConsumerWidget {
  final ScrollController scrollCtrl;
  const _BrowseSheet({required this.scrollCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allClansProvider);
    final userClans =
        ref.watch(userClansProvider).valueOrNull ?? [];
    final joinedIds = userClans.map((c) => c.id).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle + header
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              const Text('Discover Clans',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    _showCreateDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: allAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary)),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (clans) => ListView.separated(
              controller: scrollCtrl,
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 40),
              itemCount: clans.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (_, i) => _BrowseClanCard(
                clan: clans[i],
                isMember: joinedIds.contains(clans[i].id),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'Technology';

    const categories = [
      'Technology', 'Design', 'Business', 'Data Science',
      'Research', 'Arts & Culture', 'Sports', 'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (_, set) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Create Clan',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Clan Name',
                    hintText: 'e.g. AI Builders',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What is this clan about?',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      set(() => selectedCategory = v ?? selectedCategory),
                ),
                const SizedBox(height: 20),
                Consumer(builder: (_, ref, __) {
                  final state = ref.watch(clanActionsProvider);
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) return;
                              final user =
                                  ref.read(currentUserProvider);
                              if (user == null) return;
                              await ref
                                  .read(clanActionsProvider.notifier)
                                  .createClan(
                                    name: name,
                                    description:
                                        descCtrl.text.trim(),
                                    category: selectedCategory,
                                    ownerId: user.id,
                                  );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                          : const Text('Create Clan',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowseClanCard extends ConsumerWidget {
  final ClanModel clan;
  final bool isMember;
  const _BrowseClanCard(
      {required this.clan, required this.isMember});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clanActionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Color(clan.color),
            child: Text(clan.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clan.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                if (clan.description != null &&
                    clan.description!.isNotEmpty)
                  Text(clan.description!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                Text('${clan.memberCount} members',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: isMember
                ? OutlinedButton(
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            final user =
                                ref.read(currentUserProvider);
                            if (user == null) return;
                            await ref
                                .read(clanActionsProvider.notifier)
                                .leaveClan(
                                    clanId: clan.id,
                                    userId: user.id);
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(
                          color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Leave',
                        style: TextStyle(fontSize: 12)),
                  )
                : ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            final user =
                                ref.read(currentUserProvider);
                            if (user == null) return;
                            await ref
                                .read(clanActionsProvider.notifier)
                                .joinClan(
                                    clanId: clan.id,
                                    userId: user.id);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Join',
                        style: TextStyle(fontSize: 12)),
                  ),
          ),
        ],
      ),
    );
  }
}

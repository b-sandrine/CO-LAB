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

class _ClansScreenState extends ConsumerState<ClansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clans'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Clan',
            onPressed: () => _showCreateClanDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'My Clans'),
            Tab(text: 'Browse'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearch(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MyClansTab(query: _query),
                _BrowseClansTab(query: _query),
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
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search clans...',
          prefixIcon: const Icon(Icons.search, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  })
              : null,
        ),
      ),
    );
  }

  void _showCreateClanDialog(BuildContext context) {
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    const Text('Create Clan',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
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
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => set(() => selectedCategory = v ?? selectedCategory),
                ),
                const SizedBox(height: 20),
                Consumer(builder: (_, ref, __) {
                  final state = ref.watch(clanActionsProvider);
                  return ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            final user = ref.read(currentUserProvider);
                            if (user == null) return;
                            await ref
                                .read(clanActionsProvider.notifier)
                                .createClan(
                                  name: name,
                                  description: descCtrl.text.trim(),
                                  category: selectedCategory,
                                  ownerId: user.id,
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Create Clan'),
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

// ── My Clans tab ──────────────────────────────────────────────────────────────

class _MyClansTab extends ConsumerWidget {
  final String query;
  const _MyClansTab({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clansAsync = ref.watch(userClansProvider);

    return clansAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      data: (clans) {
        final filtered = query.isEmpty
            ? clans
            : clans
                .where((c) => c.name.toLowerCase().contains(query))
                .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  query.isEmpty ? 'No clans joined yet' : 'No results',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  query.isEmpty
                      ? 'Browse the Browse tab to find and join clans'
                      : 'Try a different search',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
          children: filtered.map((c) => _ClanTile(clan: c)).toList(),
        );
      },
    );
  }
}

// ── Browse Clans tab ──────────────────────────────────────────────────────────

class _BrowseClansTab extends ConsumerWidget {
  final String query;
  const _BrowseClansTab({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allClansProvider);
    final userClans = ref.watch(userClansProvider).valueOrNull ?? [];
    final joinedIds = userClans.map((c) => c.id).toSet();

    return allAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      data: (clans) {
        final filtered = query.isEmpty
            ? clans
            : clans
                .where((c) =>
                    c.name.toLowerCase().contains(query) ||
                    (c.category?.toLowerCase().contains(query) ?? false))
                .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              query.isEmpty ? 'No clans available' : 'No results',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _BrowseClanCard(
            clan: filtered[i],
            isMember: joinedIds.contains(filtered[i].id),
          ),
        );
      },
    );
  }
}

class _BrowseClanCard extends ConsumerWidget {
  final ClanModel clan;
  final bool isMember;
  const _BrowseClanCard({required this.clan, required this.isMember});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clanActionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Color(clan.color),
            child: Text(clan.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clan.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                if (clan.description != null && clan.description!.isNotEmpty)
                  Text(clan.description!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (clan.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.chipBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(clan.category!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text('${clan.memberCount} members',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          isMember
              ? OutlinedButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final user = ref.read(currentUserProvider);
                          if (user == null) return;
                          await ref
                              .read(clanActionsProvider.notifier)
                              .leaveClan(
                                  clanId: clan.id, userId: user.id);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Leave',
                      style: TextStyle(fontSize: 13)),
                )
              : ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final user = ref.read(currentUserProvider);
                          if (user == null) return;
                          await ref
                              .read(clanActionsProvider.notifier)
                              .joinClan(
                                  clanId: clan.id, userId: user.id);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Join', style: TextStyle(fontSize: 13)),
                ),
        ],
      ),
    );
  }
}

// ── My Clans list tile ────────────────────────────────────────────────────────

class _ClanTile extends StatelessWidget {
  final ClanModel clan;
  const _ClanTile({required this.clan});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/clans/${clan.id}'),
      child: Container(
        color: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Color(clan.color),
              child: Text(clan.initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clan.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    clan.lastMessage.isEmpty
                        ? 'No messages yet'
                        : clan.lastMessage,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeago.format(clan.lastMessageTime, allowFromNow: true),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
                const SizedBox(height: 4),
                if (clan.unreadCount > 0)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '${clan.unreadCount}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

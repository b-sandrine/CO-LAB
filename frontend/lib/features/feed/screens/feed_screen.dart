import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/opportunity_model.dart';
import '../providers/feed_provider.dart';
import '../../auth/providers/auth_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    final user = ref.watch(authProvider).user;
    final filters = ['All', 'Hackathon', 'Peer Study', 'Club Project'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(user?.firstName ?? 'there')),
            SliverToBoxAdapter(child: _buildFilterRow(ref, feed.selectedFilter, filters)),
            if (feed.filtered.isEmpty)
              SliverFillRemaining(child: _buildEmpty(context))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OpportunityCard(opportunity: feed.filtered[i]),
                    ),
                    childCount: feed.filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${_greeting()}, $firstName 👋', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 26, color: AppColors.textPrimary),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(WidgetRef ref, String selected, List<String> filters) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final isSelected = f == selected;
          return GestureDetector(
            onTap: () => ref.read(feedProvider.notifier).setFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Text(f, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.textPrimary)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No sessions found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Be an Entrepreneurial Leader — start one!', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)), child: const Text('Create Session')),
        ],
      ),
    );
  }
}

class _OpportunityCard extends ConsumerWidget {
  final OpportunityModel opportunity;
  const _OpportunityCard({required this.opportunity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _typeColor(opportunity.type), width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(initial: opportunity.postedByInitial),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opportunity.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(opportunity.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Posted by ${opportunity.postedBy}${opportunity.yearLabel != null ? " · ${opportunity.yearLabel}" : ""}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            _buildDateRow(),
            if (opportunity.skillTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: opportunity.skillTags.map((s) => _SkillTag(s)).toList()),
            ],
            const SizedBox(height: 12),
            _buildJoinButton(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    if (opportunity.isDateRolling) {
      return _DateChip(label: 'Rolling');
    }
    if (opportunity.eventDate == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final isToday = opportunity.eventDate!.day == now.day && opportunity.eventDate!.month == now.month;
    final label = isToday
        ? 'Today · ${DateFormat.jm().format(opportunity.eventDate!)}'
        : DateFormat('EEE d MMM').format(opportunity.eventDate!);
    return _DateChip(label: label);
  }

  Widget _buildJoinButton(WidgetRef ref) {
    final isRequested = opportunity.hasRequested;
    if (isRequested) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(color: AppColors.chipBackground, borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Text(opportunity.joinLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
        ),
      );
    }
    final isTeal = opportunity.joinLabel == 'RSVP';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => ref.read(feedProvider.notifier).requestJoin(opportunity.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: isTeal ? AppColors.teal : AppColors.primary,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(opportunity.joinLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Hackathon': return AppColors.primary;
      case 'Peer Study': return AppColors.teal;
      case 'Club Project': return AppColors.amber;
      default: return AppColors.primary;
    }
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  const _Avatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.chipBackground,
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    );
  }
}

class _SkillTag extends StatelessWidget {
  final String label;
  const _SkillTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.teal)),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

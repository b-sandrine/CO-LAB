import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/clans_provider.dart';
import '../../../shared/models/clan_model.dart';
import '../../auth/providers/auth_provider.dart';

class ClanChatScreen extends ConsumerStatefulWidget {
  final String clanId;
  const ClanChatScreen({super.key, required this.clanId});

  @override
  ConsumerState<ClanChatScreen> createState() => _ClanChatScreenState();
}

class _ClanChatScreenState extends ConsumerState<ClanChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    ref.read(clanActionsProvider.notifier).send(
          clanId: widget.clanId,
          senderId: user.id,
          senderName: user.firstName,
          content: text,
        );
    _msgCtrl.clear();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clan = ref.watch(selectedClanProvider(widget.clanId));
    final isMemberAsync = ref.watch(isMemberOfClanProvider(widget.clanId));
    final currentUser = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(clanMessagesProvider(widget.clanId));

    // Access control: non-members see a join prompt instead of the chat
    final isMember = isMemberAsync.valueOrNull ?? false;
    if (isMemberAsync.hasValue && !isMember) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
          title: Text(clan?.name ?? ''),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: clan != null ? Color(clan.color) : AppColors.primary,
                  child: Text(clan?.initials ?? '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                Text(clan?.name ?? 'This Clan',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  clan?.description ?? 'Join this clan to read and send messages.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text('${clan?.memberCount ?? 0} members',
                    style: const TextStyle(color: AppColors.textHint)),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: currentUser == null
                      ? null
                      : () async {
                          await ref
                              .read(clanActionsProvider.notifier)
                              .joinClan(
                                  clanId: widget.clanId,
                                  userId: currentUser.id);
                          ref.invalidate(isMemberOfClanProvider(widget.clanId));
                        },
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Join Clan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Auto-scroll on new messages
    ref.listen(clanMessagesProvider(widget.clanId), (_, next) {
      next.whenData((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(clan?.name ?? ''),
        backgroundColor: Colors.white,
        actions: [
          if (clan != null)
            Row(
              children: [
                const Icon(Icons.people_outline, size: 18),
                const SizedBox(width: 4),
                Text('${clan.memberCount}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (clan != null) _buildMeetingBanner(clan),
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) => messages.isEmpty
                  ? const Center(
                      child: Text('No messages yet. Say hello! 👋',
                          style: TextStyle(color: AppColors.textHint)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: messages.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) return _buildDateLabel('Today');
                        return _MessageBubble(message: messages[i - 1]);
                      },
                    ),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMeetingBanner(ClanModel clan) {
    if (clan.description == null || clan.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      color: AppColors.tealLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              clan.description!,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.attach_file_outlined,
                  color: AppColors.textSecondary),
              onPressed: () async {
                final picker = ImagePicker();
                final picked =
                    await picker.pickImage(source: ImageSource.gallery);
                if (picked == null) return;
                final user = ref.read(currentUserProvider);
                if (user == null) return;
                ref.read(clanActionsProvider.notifier).send(
                      clanId: widget.clanId,
                      senderId: user.id,
                      senderName: user.firstName,
                      content: '',
                      imageUrl: picked.path,
                    );
              }),
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              decoration: InputDecoration(
                hintText: 'Message your Clan...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.primary)),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: AppColors.teal, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ClanMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // Emoji-only message
    if (message.emoji != null && message.content.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.senderName,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(message.emoji!, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 2),
            Text(DateFormat.jm().format(message.timestamp),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.chipBackground,
              child: Text(message.senderName.isNotEmpty ? message.senderName[0] : '?',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!message.isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(message.senderName,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600)),
                  ),
                // Image message
                if (message.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message.imageUrl!,
                      width: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: message.isMe ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                            Radius.circular(message.isMe ? 16 : 4),
                        bottomRight:
                            Radius.circular(message.isMe ? 4 : 16),
                      ),
                      border: message.isMe
                          ? null
                          : Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                          fontSize: 14,
                          color: message.isMe
                              ? Colors.white
                              : AppColors.textPrimary),
                    ),
                  ),
                const SizedBox(height: 3),
                Text(
                  DateFormat.jm().format(message.timestamp),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/models/message_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String channelId;
  final String channelType;
  final String? title;

  const ChatPage({
    super.key,
    this.channelId = 'general',
    this.channelType = 'family',
    this.title,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final currentFamily = ref.read(currentFamilyProvider);
      final currentUser = ref.read(currentUserProvider);

      if (currentFamily == null || currentUser == null) return;

      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            familyId: currentFamily.id,
            senderId: currentUser.id,
            content: content,
            channelId: widget.channelId,
            channelType: widget.channelType,
          );

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(chatRepositoryProvider).deleteMessage(messageId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete message: $e')));
      }
    }
  }

  Future<void> _toggleReaction(String messageId, String emoji) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final repo = ref.read(chatRepositoryProvider);
    try {
      await repo.addReaction(
        messageId: messageId,
        userId: currentUser.id,
        emoji: emoji,
      );
    } catch (e) {
      // If unique constraint violation, it means we already reacted, so remove it.
      await repo.removeReaction(
        messageId: messageId,
        userId: currentUser.id,
        emoji: emoji,
      );
    }
  }

  void _markAsReadIfNeeded(MessageModel message) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    if (message.senderId == currentUser.id) return; // Don't mark own messages

    final hasRead = message.reads.any((r) => r.userId == currentUser.id);
    if (hasRead) return;

    ref
        .read(chatRepositoryProvider)
        .markMessageAsRead(messageId: message.id, userId: currentUser.id);
  }

  @override
  Widget build(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final currentUser = ref.watch(currentUserProvider);
    final membersAsync = currentFamily != null
        ? ref.watch(familyMembersProvider(currentFamily.id))
        : const AsyncValue.loading();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    if (currentFamily == null || currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Header logic
    final headerTitle = widget.title ?? 'Family Chat';
    final headerSubtitle = widget.channelType == 'family'
        ? 'Chat with everyone'
        : 'Direct Message';

    final showCustomHeader = widget.channelType == 'dm' || widget.title != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: BackgroundWidget(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (showCustomHeader)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppConstants.routeChat);
                          }
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headerTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (headerSubtitle.isNotEmpty)
                              Text(
                                headerSubtitle,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ref
                    .watch(
                      chatMessagesProvider((
                        familyId: currentFamily.id,
                        channelId: widget.channelId,
                      )),
                    )
                    .when(
                      data: (messages) {
                        if (messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet.\nStart the conversation!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderId == currentUser.id;

                            // Mark as read if needed
                            if (!isMe) {
                              _markAsReadIfNeeded(message);
                            }

                            String? senderName;
                            String? senderAvatar;

                            final members = membersAsync.valueOrNull ?? [];
                            if (!isMe && members.isNotEmpty) {
                              try {
                                final sender = members.firstWhere(
                                  (m) => m.uid == message.senderId,
                                );
                                senderName = sender.displayName;
                                senderAvatar = sender.photoURL;
                              } catch (_) {}
                            }

                            return MessageBubble(
                              content: message.content,
                              isMe: isMe,
                              createdAt: message.createdAt,
                              senderName: senderName ?? 'Member',
                              senderAvatarUrl: senderAvatar,
                              onLongPress: isMe
                                  ? () => _deleteMessage(message.id)
                                  : null,
                              reactions: message.reactions,
                              reads: message.reads,
                              currentUserId: currentUser.id,
                              onReactionSelected: (emoji) =>
                                  _toggleReaction(message.id, emoji),
                            );
                          },
                        );
                      },
                      error: (err, stack) => Center(child: Text('Error: $err')),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                    ),
              ),
              // Input Area
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom:
                      12 +
                      bottomPadding +
                      (bottomPadding == 0 ? ResponsiveHelper.h(130) : 0),
                  // Keeping the padding fix
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isSending
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 20,
                              ),
                        onPressed: _isSending ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

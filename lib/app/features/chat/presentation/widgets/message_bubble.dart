import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../data/models/reaction_model.dart';
import '../../../../data/models/read_receipt_model.dart';

class MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatarUrl;
  final VoidCallback? onLongPress;
  final List<ReactionModel> reactions;
  final List<ReadReceiptModel> reads;
  final Function(String emoji)? onReactionSelected;
  final String currentUserId;

  const MessageBubble({
    super.key,
    required this.content,
    required this.isMe,
    required this.createdAt,
    this.senderName,
    this.senderAvatarUrl,
    this.onLongPress,
    this.reactions = const [],
    this.reads = const [],
    this.onReactionSelected,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _handleLongPress(context),
      child: _buildBubble(context),
    );
  }

  VoidCallback? _handleLongPress(BuildContext context) {
    if (onLongPress == null && onReactionSelected == null) return null;

    return () {
      // If we have onLongPress (delete), we might want to show a menu
      // containing both "React" and "Delete".
      // For now, let's show a modal bottom sheet with reactions and a delete option.
      showModalBottomSheet(
        context: context,
        builder: (context) => _buildActionSheet(context),
      );
    };
  }

  Widget _buildActionSheet(BuildContext context) {
    final emojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reaction Picker
          if (onReactionSelected != null) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: emojis.map((emoji) {
                  final hasReacted = reactions.any(
                    (r) => r.userId == currentUserId && r.emoji == emoji,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onReactionSelected!(emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasReacted
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
          ],

          // Delete Option (only if onLongPress provided)
          if (onLongPress != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Message',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                onLongPress!();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 40 : 8,
        right: isMe ? 8 : 40,
        bottom: 12, // Increased bottom padding for reactions
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                AvatarWidget(
                  avatarPath: senderAvatarUrl,
                  radius: 14,
                  displayName: senderName ?? 'User',
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: isMe
                              ? const Radius.circular(20)
                              : const Radius.circular(4),
                          bottomRight: isMe
                              ? const Radius.circular(4)
                              : const Radius.circular(20),
                        ),
                      ),
                      child: Text(
                        content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isMe
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (reactions.isNotEmpty) _buildReactionsDisplay(context),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isMe ? 0 : 36, // Align with bubble not avatar
              right: isMe ? 0 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: reads.isNotEmpty
                        ? Colors.blue
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsDisplay(BuildContext context) {
    // Group reactions by emoji
    final Map<String, int> counts = {};
    for (var r in reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
        children: counts.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withOpacity(0.5),
                width: 0.5,
              ),
            ),
            child: Text(
              '${entry.key} ${entry.value}',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, ({String familyId, String channelId})>((
      ref,
      params,
    ) {
      return ref
          .watch(chatRepositoryProvider)
          .subscribeToMessages(
            familyId: params.familyId,
            channelId: params.channelId,
          );
    });

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  Future<List<MessageModel>> getMessages({
    required String familyId,
    String channelId = 'general',
    int limit = 50,
  }) async {
    try {
      final List<dynamic> data = await _supabase
          .from('messages')
          .select('*, message_reactions(*), message_reads(*)')
          .eq('family_id', familyId)
          .eq('channel_id', channelId)
          .order('created_at', ascending: false) // Fetch newest first
          .limit(limit);

      return data
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<void> sendMessage({
    required String familyId,
    required String content,
    required String senderId,
    String channelId = 'general',
    String channelType = 'family',
    String? mediaUrl,
  }) async {
    try {
      await _supabase.from('messages').insert({
        'family_id': familyId,
        'sender_id': senderId,
        'content': content,
        'channel_id': channelId,
        'channel_type': channelType,
        'media_url': mediaUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<MessageModel>> subscribeToMessages({
    required String familyId,
    String channelId = 'general',
  }) {
    late StreamController<List<MessageModel>> controller;
    RealtimeChannel? subscription;

    void fetchMessages() async {
      try {
        final messages = await getMessages(
          familyId: familyId,
          channelId: channelId,
        );
        if (!controller.isClosed) {
          controller.add(messages);
        }
      } catch (e) {
        // Handle error silently or log
        // if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<MessageModel>>(
      onListen: () {
        // Initial fetch
        fetchMessages();

        final channelName = 'chat:$familyId:$channelId';
        subscription = _supabase.channel(channelName);

        // Listen for changes in messages
        subscription!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'family_id',
                value: familyId,
              ),
              callback: (_) => fetchMessages(),
            )
            // Listen for changes in reactions
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'message_reactions',
              callback: (_) => fetchMessages(),
            )
            // Listen for changes in read receipts
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'message_reads',
              callback: (_) => fetchMessages(),
            )
            .subscribe();
      },
      onCancel: () {
        subscription?.unsubscribe();
        controller.close();
      },
    );

    return controller.stream;
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('messages').delete().eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> addReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await _supabase.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
      });
    } catch (e) {
      // Ignore duplicates
    }
  }

  Future<void> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await _supabase
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji);
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  Future<void> markMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      await _supabase.from('message_reads').insert({
        'message_id': messageId,
        'user_id': userId,
      });
    } catch (e) {
      // Ignore duplicates
    }
  }
}

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageService {
  final _supabase = Supabase.instance.client;

  /// Gets or creates a conversation between buyer and seller for a product
  Future<String> getOrCreateConversation({
    required String productId,
    required String buyerId,
    required String seller_id,
  }) async {
    try {
      // Try to find existing conversation
      final existing = await _supabase
          .from('conversations')
          .select('id')
          .eq('product_id', productId)
          .eq('buyer_id', buyerId)
          .eq('seller_id', seller_id)
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      // Create new one if not found
      final response = await _supabase
          .from('conversations')
          .insert({
            'product_id': productId,
            'buyer_id': buyerId,
            'seller_id': seller_id,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error getting/creating conversation: $e');
      rethrow;
    }
  }

  /// Finds an existing conversation without creating one
  Future<String?> findExistingConversation({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) async {
    try {
      final existing = await _supabase
          .from('conversations')
          .select('id')
          .eq('product_id', productId)
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .maybeSingle();

      return existing?['id'] as String?;
    } catch (e) {
      print('Error finding existing conversation: $e');
      return null;
    }
  }

  /// Sanitizes a filename for use in storage keys (removes emojis and other invalid characters).
  static String _sanitizeStorageFileName(String fileName) {
    final ext = fileName.contains('.') ? fileName.substring(fileName.lastIndexOf('.')) : '.jpg';
    final nameWithoutExt = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
    final safeBase = nameWithoutExt.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(RegExp(r'\s+'), '_').trim();
    return (safeBase.isEmpty ? 'image' : safeBase) + ext;
  }

  /// Uploads an attachment (image/audio) for a message and returns the public URL.
  /// Uses bucket 'message-attachments' (create in Supabase Storage and set public if needed) with path userId/timestamp_sanitizedFilename.
  Future<String> uploadMessageAttachment({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final safeName = _sanitizeStorageFileName(fileName);
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      await _supabase.storage.from('message-attachments').uploadBinary(
        path,
        bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      return _supabase.storage.from('message-attachments').getPublicUrl(path);
    } catch (e) {
      print('Error uploading message attachment: $e');
      rethrow;
    }
  }

  /// Sends a message in a conversation
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    try {
      // 1. Send the user's message
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'is_read': false, // Explicitly set to unread for the recipient
      });

      // 2. Update conversation metadata for sorting
      // We wrap this in a try-catch because last_message_sender_id might be missing
      try {
        await _supabase.from('conversations').update({
          'created_at': DateTime.now().toIso8601String(),
        }).eq('id', conversationId);
      } catch (e) {
        print('DEBUG: Non-critical error updating conversation metadata: $e');
      }

    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }


  /// One-time fetch of messages for a conversation. Use for chat view with polling (Realtime filtered stream is unreliable).
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    final list = response as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Stream<List<Map<String, dynamic>>> streamMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }

  /// Streams IDs of conversations that have unread messages for the user
  Stream<Set<String>> streamUnreadConversationIds(String userId) {
    // We stream from the messages table directly to check for unread messages
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((data) {
          try {
            final unread = data
              .where((m) => m['is_read'] == false && m['sender_id'] != userId)
              .map((m) => m['conversation_id'] as String)
              .toSet();
            print('DEBUG: streamUnreadConversationIds emitted ${unread.length} unread conversations for user $userId');
            return unread;
          } catch (e) {
            print('DEBUG: Error in streamUnreadConversationIds (likely missing is_read column): $e');
            return <String>{};
          }
        });
  }

  /// Streams unread message count per conversation (conversationId -> count). Used for WhatsApp-style badges.
  Stream<Map<String, int>> streamUnreadCountByConversation(String userId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((data) {
          try {
            final Map<String, int> counts = {};
            for (final m in data) {
              if (m['is_read'] != false) continue;
              if (m['sender_id'] == userId) continue;
              final cid = m['conversation_id'] as String?;
              if (cid == null || cid.isEmpty) continue;
              counts[cid] = (counts[cid] ?? 0) + 1;
            }
            return counts;
          } catch (e) {
            return <String, int>{};
          }
        });
  }

  /// Streams active conversations for a user
  Stream<List<Map<String, dynamic>>> streamConversations(String userId) {
    // Note: Supabase stream doesn't support .or() filters
    // We'll filter in the UI layer or use two separate streams
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          if (data.isNotEmpty) {
            print('DEBUG: Conversation keys: ${data.first.keys.toList()}');
          }
          final filtered = data.where((conv) {
            final buyerId = conv['buyer_id'] as String?;
            final sellerId = conv['seller_id'] as String?;
            return buyerId == userId || sellerId == userId;
          }).toList();
          print('DEBUG: streamConversations emitted ${filtered.length} conversations for user $userId');
          return filtered;
        });
  }

  /// Gets a single conversation by ID
  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    return await _supabase
        .from('conversations')
        .select()
        .eq('id', conversationId)
        .single();
  }

  /// Deletes a conversation and all its messages.
  /// Throws if the conversation was not found or could not be deleted (e.g. RLS).
  Future<void> deleteConversation(String conversationId) async {
    try {
      print('Deleting conversation: $conversationId');

      // Delete all messages in the conversation first
      await _supabase
          .from('messages')
          .delete()
          .eq('conversation_id', conversationId);

      // Then delete the conversation; require that exactly one row was deleted
      final conversationDeleted = await _supabase
          .from('conversations')
          .delete()
          .eq('id', conversationId)
          .select();

      final list = conversationDeleted as List;
      if (list.isEmpty) {
        throw Exception(
          'Conversation could not be deleted. You may not have permission, or it may already be deleted.',
        );
      }
      print('Deleted conversation: ${list.length} row(s)');
    } catch (e) {
      print('Error deleting conversation: $e');
      rethrow;
    }
  }

  /// Marks all messages in a conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      // Mark all messages in that conversation as read where the user is NOT the sender
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // We wrap in a try-catch to handle cases where is_read column might be missing
      try {
        await _supabase
            .from('messages')
            .update({'is_read': true})
            .eq('conversation_id', conversationId)
            .neq('sender_id', user.id);
      } catch (e) {
        print('DEBUG: is_read column missing in messages table, skipping update: $e');
      }
          
      print('DEBUG: markConversationAsRead completed for $conversationId');
    } catch (e) {
      print('Error marking conversation as read: $e');
    }
  }

  /// Marks all conversations for a user as read (persists to DB so badge/dots stay updated after popup close).
  Future<void> markAllAsRead(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.id != userId) return;

      // Fetch conversation IDs where user is buyer or seller (two queries to avoid .or() syntax issues)
      final asBuyer = await _supabase
          .from('conversations')
          .select('id')
          .eq('buyer_id', userId);
      final asSeller = await _supabase
          .from('conversations')
          .select('id')
          .eq('seller_id', userId);

      final Set<String> ids = {};
      void addIds(dynamic response) {
        if (response == null) return;
        final list = response as List;
        for (final c in list) {
          if (c is Map<String, dynamic>) {
            final id = c['id'];
            if (id != null) {
              final idStr = id is String ? id : id.toString();
              if (idStr.isNotEmpty) ids.add(idStr);
            }
          }
        }
      }
      addIds(asBuyer);
      addIds(asSeller);

      for (final conversationId in ids) {
        try {
          await _supabase
              .from('messages')
              .update({'is_read': true})
              .eq('conversation_id', conversationId)
              .neq('sender_id', userId);
        } catch (e) {
          print('DEBUG: markAllAsRead single conversation $conversationId: $e');
        }
      }

      print('DEBUG: markAllAsRead completed for user $userId (${ids.length} conversations)');
    } catch (e) {
      print('Error marking all as read: $e');
      rethrow;
    }
  }
}

final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService();
});

final userConversationsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return ref.watch(messageServiceProvider).streamConversations(userId);
});

/// Messages for one conversation (Realtime stream).
///
/// Note: we keep this as a StreamProvider so the chat view rebuilds as soon
/// as new messages arrive. The web messages page also has a lightweight
/// polling fallback which periodically invalidates this provider while a
/// conversation is open, to work around any edge cases with filtered streams.
final conversationMessagesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, conversationId) {
  return ref.watch(messageServiceProvider).streamMessages(conversationId);
});

final unreadConversationsProvider = StreamProvider.family<Set<String>, String>((ref, userId) {
  return ref.watch(messageServiceProvider).streamUnreadConversationIds(userId);
});

/// Unread message count per conversation (conversationId -> count) for WhatsApp-style badges.
final unreadCountByConversationProvider = StreamProvider.family<Map<String, int>, String>((ref, userId) {
  return ref.watch(messageServiceProvider).streamUnreadCountByConversation(userId);
});

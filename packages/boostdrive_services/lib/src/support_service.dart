import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String userType;
  final String issueType;
  final String status;
  final String subject;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userType,
    required this.issueType,
    required this.status,
    required this.subject,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['id'],
      userId: map['user_id'],
      userType: map['user_type'],
      issueType: map['issue_type'],
      status: map['status'],
      subject: map['subject'],
      adminNotes: map['admin_notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class TicketMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String message;
  final bool isAdmin;
  final DateTime createdAt;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.message,
    required this.isAdmin,
    required this.createdAt,
  });

  factory TicketMessage.fromMap(Map<String, dynamic> map) {
    return TicketMessage(
      id: map['id'],
      ticketId: map['ticket_id'],
      senderId: map['sender_id'],
      message: map['message'],
      isAdmin: map['is_admin'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class SupportService {
  final _supabase = Supabase.instance.client;

  Future<List<SupportTicket>> getAllTickets() async {
    final res = await _supabase
        .from('support_tickets')
        .select()
        .order('created_at', ascending: false);
    return (res as List).map((e) => SupportTicket.fromMap(e)).toList();
  }

  Future<SupportTicket> getTicket(String ticketId) async {
    final res = await _supabase
        .from('support_tickets')
        .select()
        .eq('id', ticketId)
        .single();
    return SupportTicket.fromMap(res);
  }

  Future<List<TicketMessage>> getTicketMessages(String ticketId) async {
    final res = await _supabase
        .from('ticket_messages')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);
    return (res as List).map((e) => TicketMessage.fromMap(e)).toList();
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _supabase
        .from('support_tickets')
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', ticketId);
  }

  Future<void> updateAdminNotes(String ticketId, String notes) async {
    await _supabase
        .from('support_tickets')
        .update({'admin_notes': notes, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', ticketId);
  }

  Future<void> addMessage({
    required String ticketId,
    required String senderId,
    required String message,
    required bool isAdmin,
  }) async {
    await _supabase.from('ticket_messages').insert({
      'ticket_id': ticketId,
      'sender_id': senderId,
      'message': message,
      'is_admin': isAdmin,
    });
    
    // Auto-set status to open if user messages
    if (!isAdmin) {
      await updateTicketStatus(ticketId, 'open');
    }
  }
  
  Future<void> createTicket({
    required String userId,
    required String userType,
    required String issueType,
    required String subject,
  }) async {
    await _supabase.from('support_tickets').insert({
      'user_id': userId,
      'user_type': userType,
      'issue_type': issueType,
      'subject': subject,
      'status': 'open',
    });
  }
  
  Future<List<SupportTicket>> getUserTickets(String userId) async {
    final res = await _supabase
        .from('support_tickets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => SupportTicket.fromMap(e)).toList();
  }
}

final supportServiceProvider = Provider<SupportService>((ref) => SupportService());

final allTicketsProvider = FutureProvider<List<SupportTicket>>((ref) {
  return ref.watch(supportServiceProvider).getAllTickets();
});

final userTicketsProvider = FutureProvider.family<List<SupportTicket>, String>((ref, userId) {
  return ref.watch(supportServiceProvider).getUserTickets(userId);
});

final ticketMessagesProvider = FutureProvider.family<List<TicketMessage>, String>((ref, ticketId) {
  return ref.watch(supportServiceProvider).getTicketMessages(ticketId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobCardService {
  JobCardService([SupabaseClient? client]) : _c = client ?? Supabase.instance.client;

  final SupabaseClient _c;

  Future<List<Map<String, dynamic>>> listJobCards(String providerId) async {
    final rows = await _c
        .from('provider_job_cards')
        .select()
        .eq('provider_id', providerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List<dynamic>);
  }

  Future<List<Map<String, dynamic>>> listJobCardsForRequester(String requesterId) async {
    final rows = await _c
        .from('provider_job_cards')
        .select()
        .eq('requester_id', requesterId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List<dynamic>);
  }

  Future<List<Map<String, dynamic>>> listIncomingJobCardsForProvider(String providerId) async {
    // Two queries avoid fragile PostgREST `.or()` nesting (which can drop rows or parse wrong).
    final submitted = await _c
        .from('provider_job_cards')
        .select()
        .eq('status', 'submitted')
        .order('created_at', ascending: false);
    final mineAssigned = await _c
        .from('provider_job_cards')
        .select()
        .eq('assigned_provider_id', providerId)
        .inFilter('status', ['quoted', 'accepted'])
        .order('created_at', ascending: false);
    // Backward compatibility for rows that were assigned via provider_id only.
    final mineLegacy = await _c
        .from('provider_job_cards')
        .select()
        .eq('provider_id', providerId)
        .inFilter('status', ['quoted', 'accepted'])
        .order('created_at', ascending: false);
    List<Map<String, dynamic>> asMaps(dynamic raw) {
      if (raw == null) return [];
      final list = raw as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    final byId = <String, Map<String, dynamic>>{};
    for (final m in asMaps(submitted)) {
      final id = m['id']?.toString();
      if (id != null && id.isNotEmpty) byId[id] = m;
    }
    for (final m in asMaps(mineAssigned)) {
      final id = m['id']?.toString();
      if (id != null && id.isNotEmpty) byId[id] = m;
    }
    for (final m in asMaps(mineLegacy)) {
      final id = m['id']?.toString();
      if (id != null && id.isNotEmpty) byId[id] = m;
    }
    final out = byId.values.toList();
    out.sort((a, b) {
      final ta = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return out;
  }

  Future<String> createJobCard({
    required String providerId,
    String? customerId,
    required String vehicleLabel,
    required String concernSummary,
    String? diagnosisNotes,
    double laborAmount = 0,
  }) async {
    final row = await _c.from('provider_job_cards').insert({
      'provider_id': providerId,
      'customer_id': customerId,
      'vehicle_label': vehicleLabel,
      'concern_summary': concernSummary,
      'diagnosis_notes': diagnosisNotes ?? '',
      'labor_amount': laborAmount,
      'status': 'draft',
    }).select('id').single();
    return row['id'].toString();
  }

  Future<String> createJobCardRequest({
    required String requesterId,
    required String requesterRole,
    required String vehicleLabel,
    required String concernSummary,
    String? diagnosisNotes,
  }) async {
    final row = await _c.from('provider_job_cards').insert({
      'requester_id': requesterId,
      'requester_role': requesterRole,
      'customer_id': requesterId,
      'provider_id': null,
      'assigned_provider_id': null,
      'vehicle_label': vehicleLabel,
      'concern_summary': concernSummary,
      'diagnosis_notes': diagnosisNotes ?? '',
      'labor_amount': 0,
      'status': 'submitted',
    }).select('id').single();
    final jobCardId = row['id'].toString();
    await _notifyAllServiceProvidersForNewRequest(
      requesterId: requesterId,
      requesterRole: requesterRole,
      jobCardId: jobCardId,
      vehicleLabel: vehicleLabel,
      concernSummary: concernSummary,
    );
    return jobCardId;
  }

  Future<void> updateJobCard({
    required String jobCardId,
    required String vehicleLabel,
    required String concernSummary,
    required String diagnosisNotes,
    required double laborAmount,
  }) async {
    await _c.from('provider_job_cards').update({
      'vehicle_label': vehicleLabel,
      'concern_summary': concernSummary,
      'diagnosis_notes': diagnosisNotes,
      'labor_amount': laborAmount,
    }).eq('id', jobCardId);
  }

  Future<void> setJobCardStatus({
    required String jobCardId,
    required String status,
  }) async {
    await _c.from('provider_job_cards').update({'status': status}).eq('id', jobCardId);
  }

  Future<void> providerQuoteJobCard({
    required String jobCardId,
    required String providerId,
    required double quotedLaborAmount,
  }) async {
    var quoted = false;
    try {
      final result = await _c.rpc(
        'claim_and_quote_job_card',
        params: {
          'p_job_card_id': jobCardId,
          'p_provider_id': providerId,
          'p_labor_amount': quotedLaborAmount,
        },
      );
      final ok = result == true ||
          result == 1 ||
          result == 't' ||
          result == 'true' ||
          (result is String && result.toLowerCase() == 'true');
      if (!ok) {
        throw Exception('This job card was already quoted by another provider.');
      }
      quoted = true;
    } catch (e) {
      // RPC not deployed yet: fall back to a single-row claim update (less safe under race; prefer RPC in DB).
      final msg = e.toString().toLowerCase();
      final rpcMissing = msg.contains('claim_and_quote_job_card') ||
          msg.contains('could not find') ||
          msg.contains('does not exist') ||
          msg.contains('unknown function') ||
          msg.contains('pgrst202') ||
          msg.contains('42883');
      if (!rpcMissing) rethrow;
      final updated = await _c
          .from('provider_job_cards')
          .update({
            'provider_id': providerId,
            'assigned_provider_id': providerId,
            'labor_amount': quotedLaborAmount,
            'quoted_at': DateTime.now().toUtc().toIso8601String(),
            'status': 'quoted',
          })
          .eq('id', jobCardId)
          .eq('status', 'submitted')
          .select('id');
      final list = updated as List<dynamic>? ?? [];
      if (list.isEmpty) {
        throw Exception('This job card was already quoted by another provider.');
      }
      quoted = true;
    }
    if (quoted) {
      await _notifyRequesterQuoteSubmitted(
        jobCardId: jobCardId,
        providerId: providerId,
        quotedLaborAmount: quotedLaborAmount,
      );
    }
  }

  Future<void> customerDecideOnQuote({
    required String jobCardId,
    required String requesterId,
    required bool accept,
  }) async {
    await _c.from('provider_job_cards').update({
      'status': accept ? 'accepted' : 'declined',
      'customer_decision_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', jobCardId).eq('requester_id', requesterId).eq('status', 'quoted');
    if (accept) {
      await _ensureSosTrackingForAcceptedJobCard(jobCardId: jobCardId);
    }
    await _notifyProviderCustomerDecision(
      jobCardId: jobCardId,
      requesterId: requesterId,
      accepted: accept,
    );
  }

  Future<void> cancelJobCardRequest({
    required String jobCardId,
    required String requesterId,
  }) async {
    await _c.from('provider_job_cards').update({
      'status': 'cancelled',
      'customer_decision_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', jobCardId).eq('requester_id', requesterId).inFilter('status', ['submitted', 'quoted']);
    await _notifyProviderCustomerCancelled(
      jobCardId: jobCardId,
      requesterId: requesterId,
    );
  }

  Future<void> markPushedToCustomer(String jobCardId) async {
    await _c
        .from('provider_job_cards')
        .update({'pushed_to_customer_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', jobCardId);
  }

  Future<void> pushRequiredPartsToCustomerCart({
    required String jobCardId,
    required String providerId,
  }) async {
    final card = await _c
        .from('provider_job_cards')
        .select('id,provider_id,customer_id,vehicle_label,concern_summary')
        .eq('id', jobCardId)
        .eq('provider_id', providerId)
        .maybeSingle();
    if (card == null) throw Exception('Job card not found.');
    final customerId = card['customer_id']?.toString();
    if (customerId == null || customerId.trim().isEmpty) {
      throw Exception('Set customer ID on this job card before pushing parts.');
    }
    final parts = await listJobCardParts(jobCardId);
    if (parts.isEmpty) throw Exception('No required parts to push.');

    final push = await _c.from('customer_cart_pushes').insert({
      'job_card_id': jobCardId,
      'provider_id': providerId,
      'customer_id': customerId,
      'vehicle_label': card['vehicle_label']?.toString() ?? '',
      'notes': card['concern_summary']?.toString() ?? '',
      'status': 'pending',
    }).select('id').single();
    final pushId = push['id'].toString();

    for (final p in parts) {
      await _c.from('customer_cart_push_items').insert({
        'push_id': pushId,
        'job_card_part_id': p['id']?.toString(),
        'product_id': p['product_id']?.toString(),
        'part_name': p['part_name']?.toString() ?? '',
        'quantity': (p['quantity'] as num?)?.toInt() ?? 1,
        'unit_price': (p['unit_price'] as num?)?.toDouble() ?? 0,
      });
    }

    await markPushedToCustomer(jobCardId);
  }

  Future<void> deleteJobCard(String jobCardId) async {
    await _c.from('provider_job_cards').delete().eq('id', jobCardId);
  }

  Future<List<Map<String, dynamic>>> listJobCardParts(String jobCardId) async {
    final rows = await _c
        .from('provider_job_card_parts')
        .select()
        .eq('job_card_id', jobCardId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows as List<dynamic>);
  }

  Future<void> addJobCardPart({
    required String jobCardId,
    required String partName,
    required int quantity,
    required double unitPrice,
    String? productId,
  }) async {
    await _c.from('provider_job_card_parts').insert({
      'job_card_id': jobCardId,
      'part_name': partName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'product_id': productId,
    });
  }

  Future<void> updateJobCardPart({
    required String partId,
    required String partName,
    required int quantity,
    required double unitPrice,
  }) async {
    await _c.from('provider_job_card_parts').update({
      'part_name': partName,
      'quantity': quantity,
      'unit_price': unitPrice,
    }).eq('id', partId);
  }

  Future<void> deleteJobCardPart(String partId) async {
    await _c.from('provider_job_card_parts').delete().eq('id', partId);
  }

  Future<List<Map<String, dynamic>>> listPendingCartPushesForCustomer(String customerId) async {
    final rows = await _c
        .from('customer_cart_pushes')
        .select()
        .eq('customer_id', customerId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List<dynamic>);
  }

  Future<List<Map<String, dynamic>>> listCartPushItems(String pushId) async {
    final rows = await _c
        .from('customer_cart_push_items')
        .select()
        .eq('push_id', pushId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows as List<dynamic>);
  }

  Future<void> setCartPushStatus({
    required String pushId,
    required String status,
  }) async {
    await _c.from('customer_cart_pushes').update({'status': status}).eq('id', pushId);
  }

  Future<List<Map<String, dynamic>>> listExecutionJobCardsForProvider(String providerId) async {
    final rows = await _c
        .from('provider_job_cards')
        .select()
        .eq('assigned_provider_id', providerId)
        .inFilter('status', ['accepted', 'active', 'in_progress'])
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List<dynamic>);
  }

  Future<List<Map<String, dynamic>>> listExecutionJobCardHistoryForProvider(String providerId) async {
    final rows = await _c
        .from('provider_job_cards')
        .select()
        .eq('assigned_provider_id', providerId)
        .inFilter('status', ['completed', 'declined', 'cancelled'])
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List<dynamic>);
  }

  Future<void> setExecutionStatus({
    required String jobCardId,
    required String providerId,
    required String status,
  }) async {
    final allowed = {'accepted', 'active', 'in_progress', 'completed'};
    if (!allowed.contains(status)) {
      throw Exception('Unsupported execution status: $status');
    }
    await _c
        .from('provider_job_cards')
        .update({
          'status': status,
          if (status == 'completed') 'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', jobCardId)
        .eq('assigned_provider_id', providerId);
    await _syncLinkedSosStatus(jobCardId: jobCardId, status: status);
    await _notifyRequesterExecutionStatus(jobCardId: jobCardId, providerId: providerId, status: status);
    if (status == 'completed') {
      await _finalizeJobCardCompletion(jobCardId: jobCardId, providerId: providerId);
      await _createReviewPromptForCompletedJobCard(jobCardId: jobCardId, providerId: providerId);
      await _notifyRequesterJobCompleted(jobCardId: jobCardId, providerId: providerId);
    }
  }

  Future<void> _notifyAllServiceProvidersForNewRequest({
    required String requesterId,
    required String requesterRole,
    required String jobCardId,
    required String vehicleLabel,
    required String concernSummary,
  }) async {
    try {
      final rows = await _c
          .from('profiles')
          .select('id, role, status')
          .neq('id', requesterId);
      final allProfiles = List<Map<String, dynamic>>.from(rows as List<dynamic>);
      final providerIds = allProfiles.where((p) {
        final status = (p['status'] ?? '').toString().toLowerCase().trim();
        if (status.isNotEmpty && status != 'active') return false;
        final role = (p['role'] ?? '').toString().toLowerCase().trim();
        if (role.isEmpty) return false;
        return role.contains('mechanic') ||
            role.contains('towing') ||
            role.contains('provider') ||
            role.contains('service pro') ||
            role.contains('service_pro') ||
            role.contains('logistics') ||
            role.contains('rental');
      }).map((p) => p['id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet().toList();

      if (providerIds.isEmpty) return;

      final concernPreview = concernSummary.trim().isEmpty ? 'New service request needs a provider response.' : concernSummary.trim();
      final title = 'New Job Card Request';
      final message = '${requesterRole.toUpperCase()} submitted a request for $vehicleLabel: $concernPreview';

      const batchSize = 200;
      for (var i = 0; i < providerIds.length; i += batchSize) {
        final end = (i + batchSize < providerIds.length) ? i + batchSize : providerIds.length;
        final chunk = providerIds.sublist(i, end).map((providerId) {
          return {
            'user_id': providerId,
            'title': title,
            'message': message,
            'type': 'job_card_request',
            'is_read': false,
            'metadata': {
              'job_card_id': jobCardId,
              'requester_id': requesterId,
              'requester_role': requesterRole,
            },
          };
        }).toList();
        await _c.from('notifications').insert(chunk);
      }
    } catch (_) {
      // Notification fan-out should never block job card creation.
    }
  }

  Future<void> _notifyRequesterQuoteSubmitted({
    required String jobCardId,
    required String providerId,
    required double quotedLaborAmount,
  }) async {
    try {
      final row = await _c
          .from('provider_job_cards')
          .select('id,requester_id,customer_id,vehicle_label')
          .eq('id', jobCardId)
          .maybeSingle();
      if (row == null) return;
      final requesterId = row['requester_id']?.toString() ?? row['customer_id']?.toString() ?? '';
      if (requesterId.isEmpty) return;
      await _c.from('notifications').insert({
        'user_id': requesterId,
        'title': 'Provider Sent a Quote',
        'message':
            'A provider submitted a labor quote of N\$${quotedLaborAmount.toStringAsFixed(2)} for ${row['vehicle_label'] ?? 'your job card'}.',
        'type': 'job_card_quote',
        'is_read': false,
        'metadata': {
          'job_card_id': jobCardId,
          'provider_id': providerId,
          'action': 'quoted',
        },
      });
    } catch (_) {
      // Notifications should not block job card flow.
    }
  }

  Future<void> _notifyProviderCustomerDecision({
    required String jobCardId,
    required String requesterId,
    required bool accepted,
  }) async {
    try {
      final row = await _c
          .from('provider_job_cards')
          .select('id,assigned_provider_id,provider_id,vehicle_label')
          .eq('id', jobCardId)
          .maybeSingle();
      if (row == null) return;
      final providerId = row['assigned_provider_id']?.toString() ?? row['provider_id']?.toString() ?? '';
      if (providerId.isEmpty) return;
      final verb = accepted ? 'accepted' : 'declined';
      await _c.from('notifications').insert({
        'user_id': providerId,
        'title': 'Customer Decision on Quote',
        'message': 'The customer/seller has $verb your quote for ${row['vehicle_label'] ?? 'a job card'}.',
        'type': 'job_card_decision',
        'is_read': false,
        'metadata': {
          'job_card_id': jobCardId,
          'requester_id': requesterId,
          'action': verb,
        },
      });
    } catch (_) {
      // Notifications should not block job card flow.
    }
  }

  Future<void> _notifyProviderCustomerCancelled({
    required String jobCardId,
    required String requesterId,
  }) async {
    try {
      final row = await _c
          .from('provider_job_cards')
          .select('id,assigned_provider_id,provider_id,vehicle_label')
          .eq('id', jobCardId)
          .maybeSingle();
      if (row == null) return;
      final providerId = row['assigned_provider_id']?.toString() ?? row['provider_id']?.toString() ?? '';
      if (providerId.isEmpty) return;
      await _c.from('notifications').insert({
        'user_id': providerId,
        'title': 'Job Card Request Cancelled',
        'message': 'The customer/seller cancelled the job card request for ${row['vehicle_label'] ?? 'a vehicle'}.',
        'type': 'job_card_cancelled',
        'is_read': false,
        'metadata': {
          'job_card_id': jobCardId,
          'requester_id': requesterId,
          'action': 'cancelled',
        },
      });
    } catch (_) {
      // Notifications should not block job card flow.
    }
  }

  Future<void> _finalizeJobCardCompletion({
    required String jobCardId,
    required String providerId,
  }) async {
    // Read card + parts to compute totals and post-completion effects.
    final card = await _c
        .from('provider_job_cards')
        .select('id,vehicle_label,labor_amount,requester_id')
        .eq('id', jobCardId)
        .maybeSingle();
    if (card == null) return;
    final labor = (card['labor_amount'] as num?)?.toDouble() ?? 0;
    final parts = await listJobCardParts(jobCardId);
    var partsTotal = 0.0;
    for (final p in parts) {
      final qty = (p['quantity'] as num?)?.toInt() ?? 0;
      final unit = (p['unit_price'] as num?)?.toDouble() ?? 0;
      partsTotal += qty * unit;
      await _decrementInventoryForPart(
        providerId: providerId,
        partName: p['part_name']?.toString() ?? '',
        quantity: qty,
      );
    }
    final grandTotal = labor + partsTotal;

    // Update provider earnings dashboard field.
    try {
      final profile = await _c.from('profiles').select('total_earnings').eq('id', providerId).maybeSingle();
      final current = (profile?['total_earnings'] as num?)?.toDouble() ?? 0;
      await _c.from('profiles').update({'total_earnings': current + grandTotal}).eq('id', providerId);
    } catch (_) {
      // Non-blocking: keep completion successful even if profile schema differs.
    }

    // Persist invoice row if table exists.
    try {
      await _c.from('provider_job_card_invoices').insert({
        'job_card_id': jobCardId,
        'provider_id': providerId,
        'requester_id': card['requester_id']?.toString(),
        'vehicle_label': card['vehicle_label']?.toString() ?? '',
        'labor_amount': labor,
        'parts_amount': partsTotal,
        'total_amount': grandTotal,
        'status': 'generated',
      });
    } catch (_) {
      // Table may not exist yet on current schema.
    }
  }

  Future<void> _decrementInventoryForPart({
    required String providerId,
    required String partName,
    required int quantity,
  }) async {
    if (partName.trim().isEmpty || quantity <= 0) return;
    try {
      final row = await _c
          .from('provider_inventory')
          .select('id,stock_quantity')
          .eq('provider_id', providerId)
          .ilike('name', partName.trim())
          .limit(1)
          .maybeSingle();
      if (row == null) return;
      final id = row['id']?.toString();
      if (id == null || id.isEmpty) return;
      final stock = (row['stock_quantity'] as num?)?.toInt() ?? 0;
      final next = stock - quantity;
      await _c.from('provider_inventory').update({'stock_quantity': next < 0 ? 0 : next}).eq('id', id);
    } catch (_) {
      // Keep completion non-blocking if inventory schema/rows differ.
    }
  }

  Future<void> _notifyRequesterJobCompleted({
    required String jobCardId,
    required String providerId,
  }) async {
    try {
      final row = await _c
          .from('provider_job_cards')
          .select('id,requester_id,customer_id,vehicle_label')
          .eq('id', jobCardId)
          .maybeSingle();
      if (row == null) return;
      final requesterId = row['requester_id']?.toString() ?? row['customer_id']?.toString() ?? '';
      if (requesterId.isEmpty) return;
      await _c.from('notifications').insert({
        'user_id': requesterId,
        'title': 'Job Completed',
        'message': 'Your job card for ${row['vehicle_label'] ?? 'your vehicle'} has been marked completed.',
        'type': 'job_card_completed',
        'is_read': false,
        'metadata': {
          'job_card_id': jobCardId,
          'provider_id': providerId,
          'action': 'completed',
        },
      });
      await _c.from('notifications').insert({
        'user_id': requesterId,
        'title': 'Rate Your Provider',
        'message': 'Please rate the service provider for ${row['vehicle_label'] ?? 'your completed task'}.',
        'type': 'job_card_review_request',
        'is_read': false,
        'metadata': {
          'job_card_id': jobCardId,
          'provider_id': providerId,
          'action': 'review_request',
        },
      });
    } catch (_) {
      // Non-blocking.
    }
  }

  Future<void> _createReviewPromptForCompletedJobCard({
    required String jobCardId,
    required String providerId,
  }) async {
    try {
      final card = await _c
          .from('provider_job_cards')
          .select('id,requester_id,customer_id,sos_request_id,vehicle_label')
          .eq('id', jobCardId)
          .maybeSingle();
      if (card == null) return;
      final customerId = card['requester_id']?.toString() ?? card['customer_id']?.toString() ?? '';
      if (customerId.isEmpty) return;
      final provider = await _c.from('profiles').select('full_name').eq('id', providerId).maybeSingle();
      final providerName = (provider?['full_name']?.toString().trim().isNotEmpty == true)
          ? provider!['full_name'].toString()
          : 'Service Provider';

      // Duplicate guard: if a pending review already exists for this customer/provider, skip.
      final existing = await _c
          .from('sos_provider_reviews')
          .select('id')
          .eq('customer_id', customerId)
          .eq('provider_id', providerId)
          .isFilter('submitted_at', null)
          .limit(1);
      final existingList = List<dynamic>.from(existing as List<dynamic>);
      if (existingList.isNotEmpty) return;

      final base = {
        'customer_id': customerId,
        'provider_id': providerId,
        'provider_name_snapshot': providerName,
      };
      final withRefs = {
        ...base,
        'source_type': 'job_card',
        'source_id': jobCardId,
        'service_label': card['vehicle_label']?.toString() ?? '',
        'sos_request_id': card['sos_request_id']?.toString(),
      };

      try {
        await _c.from('sos_provider_reviews').insert(withRefs);
      } catch (_) {
        // Fallback for older table schemas without source fields.
        await _c.from('sos_provider_reviews').insert(base);
      }
    } catch (_) {
      // Non-blocking so completion cannot fail due to review prompt write.
    }
  }

  Future<void> _ensureSosTrackingForAcceptedJobCard({
    required String jobCardId,
  }) async {
    try {
      final card = await _c
          .from('provider_job_cards')
          .select(
              'id,requester_id,customer_id,assigned_provider_id,vehicle_label,concern_summary,sos_request_id')
          .eq('id', jobCardId)
          .maybeSingle();
      if (card == null) return;
      final existingSos = card['sos_request_id']?.toString() ?? '';
      if (existingSos.isNotEmpty) return;

      final requesterId = card['requester_id']?.toString() ?? card['customer_id']?.toString() ?? '';
      final providerId = card['assigned_provider_id']?.toString() ?? '';
      if (requesterId.isEmpty || providerId.isEmpty) return;

      final note = (card['concern_summary']?.toString() ?? '').trim();
      final vehicle = (card['vehicle_label']?.toString() ?? '').trim();
      Map<String, dynamic> location = {'lat': 0, 'lng': 0};
      try {
        final lastKnown = await _c
            .from('sos_requests')
            .select('location')
            .eq('user_id', requesterId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        final loc = lastKnown?['location'] as Map<String, dynamic>?;
        if (loc != null && loc['lat'] != null && loc['lng'] != null) {
          location = {'lat': (loc['lat'] as num).toDouble(), 'lng': (loc['lng'] as num).toDouble()};
        }
      } catch (_) {
        // Fallback stays at neutral location when no prior location is available.
      }
      final insert = await _c.from('sos_requests').insert({
        'user_id': requesterId,
        'type': 'mechanic',
        'status': 'assigned',
        'assigned_provider_id': providerId,
        'responded_at': DateTime.now().toUtc().toIso8601String(),
        // Reuse latest known customer SOS location when available.
        'location': location,
        'user_note': vehicle.isEmpty ? note : '$vehicle${note.isEmpty ? '' : ' • $note'}',
        'emergency_category': 'job_card',
      }).select('id').single();
      final sosId = insert['id']?.toString() ?? '';
      if (sosId.isEmpty) return;
      // Best effort link for future sync/query.
      try {
        await _c.from('provider_job_cards').update({'sos_request_id': sosId}).eq('id', jobCardId);
      } catch (_) {
        // Column may not exist yet on local schema.
      }
    } catch (_) {
      // Non-blocking to keep acceptance flow successful.
    }
  }

  Future<void> _syncLinkedSosStatus({
    required String jobCardId,
    required String status,
  }) async {
    try {
      final card = await _c
          .from('provider_job_cards')
          .select('sos_request_id')
          .eq('id', jobCardId)
          .maybeSingle();
      final sosId = card?['sos_request_id']?.toString() ?? '';
      if (sosId.isEmpty) return;
      final sosStatus = switch (status) {
        'accepted' => 'assigned',
        'active' => 'active',
        'in_progress' => 'active',
        'completed' => 'completed',
        _ => null,
      };
      if (sosStatus == null) return;
      await _c.from('sos_requests').update({'status': sosStatus}).eq('id', sosId);
    } catch (_) {
      // Non-blocking status sync.
    }
  }

  Future<void> _notifyRequesterExecutionStatus({
    required String jobCardId,
    required String providerId,
    required String status,
  }) async {
    if (status != 'active' && status != 'in_progress') return;
    try {
      final row = await _c
          .from('provider_job_cards')
          .select('id,requester_id,customer_id,vehicle_label')
          .eq('id', jobCardId)
          .maybeSingle();
      if (row == null) return;
      final requesterId = row['requester_id']?.toString() ?? row['customer_id']?.toString() ?? '';
      if (requesterId.isEmpty) return;
      final label = status == 'active' ? 'ACTIVE' : 'IN PROGRESS';
      await _c.from('notifications').insert({
        'user_id': requesterId,
        'title': 'Job Status Updated',
        'message': 'Your provider updated the job to $label for ${row['vehicle_label'] ?? 'your vehicle'}.',
        'type': 'job_card_status',
        'is_read': false,
        'metadata': {
          'job_card_id': jobCardId,
          'provider_id': providerId,
          'action': status,
        },
      });
    } catch (_) {
      // Non-blocking.
    }
  }
}

final jobCardServiceProvider = Provider<JobCardService>((ref) => JobCardService());

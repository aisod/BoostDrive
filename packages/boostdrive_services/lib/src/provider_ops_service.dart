import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed provider inventory, equipment, kits, catalog services, and service_requests.
/// Tables are created by `supabase/migrations/20260413153000_provider_inventory_orders_services.sql`.
class ProviderOpsService {
  ProviderOpsService([SupabaseClient? client]) : _c = client ?? Supabase.instance.client;

  final SupabaseClient _c;

  /// Works for [PostgrestException] and Postgres-style errors thrown on web (`PostgresException`).
  ({String? code, String msg}) _sqlErr(Object e) {
    if (e is PostgrestException) {
      return (code: e.code, msg: (e.message).toLowerCase());
    }
    try {
      final d = e as dynamic;
      final c = d.code?.toString();
      final m = (d.message ?? '$e').toString().toLowerCase();
      return (code: c, msg: m);
    } catch (_) {
      return (code: null, msg: e.toString().toLowerCase());
    }
  }

  bool _isMissingSchemaError(Object e) {
    final err = _sqlErr(e);
    final code = err.code;
    final msg = err.msg;
    // PGRST204: missing column in schema cache; PGRST205: table not found in schema cache
    return code == 'PGRST204' ||
        code == 'PGRST205' ||
        code == '42703' || // undefined_column
        msg.contains('pgrst204') ||
        msg.contains('schema cache') ||
        msg.contains('could not find the table') ||
        msg.contains('does not exist') ||
        msg.contains('could not find the') ||
        msg.contains('unknown column') ||
        (msg.contains('column') && msg.contains('not found'));
  }

  /// True when trying another insert payload shape might succeed (unknown columns, NOT NULL, enum labels).
  bool _isRetryableProviderServiceInsert(Object e) {
    final err = _sqlErr(e);
    final code = err.code;
    final msg = err.msg;
    if (code == '42501' || code == 'PGRST301' || msg.contains('row-level security')) return false;
    // Unique / conflict — do not keep inserting alternate payloads (wastes requests + confuses users).
    if (code == '23505' || msg.contains('duplicate key') || msg.contains('unique constraint')) return false;
    if (_isMissingSchemaError(e)) return true;
    if (code == '23502') return true; // not_null_violation — e.g. legacy `user_id` required
    if (msg.contains('null value in column')) return true;
    if (msg.contains('invalid input value for enum')) return true;
    return false;
  }

  /// Insert hit PK duplicate — row often already exists (double-submit or retry after a successful write).
  bool _isDuplicateProviderServicesPkeyInsert(Object e) {
    final err = _sqlErr(e);
    return err.code == '23505' && err.msg.contains('provider_services_pkey');
  }

  List<Map<String, dynamic>> _normalizeProviderServiceRows(List<Map<String, dynamic>> rows) {
    return rows.map((raw) {
      final row = Map<String, dynamic>.from(raw);
      final id = row['id'] ?? row['service_id'] ?? row['provider_service_id'];
      if (id != null) row['id'] = id;
      if (row['estimated_minutes'] == null && row['duration_minutes'] != null) {
        row['estimated_minutes'] = row['duration_minutes'];
      }
      return row;
    }).toList();
  }

  /// Many Supabase schemas require **both** `provider_id` and `user_id` NOT NULL — try dual-key first for one fast round-trip.
  List<Map<String, dynamic>> _providerServiceInsertPayloads({
    required String providerId,
    required String name,
    required String category,
    required String description,
    required double price,
    required int estimatedMinutes,
    required bool isActive,
  }) {
    Map<String, dynamic> coreNoTime() => {
          'name': name,
          'category': category,
          'description': description,
          'price': price,
        };
    Map<String, dynamic> coreTimeEst() => {
          ...coreNoTime(),
          'estimated_minutes': estimatedMinutes,
        };
    Map<String, dynamic> coreTimeDur() => {
          ...coreNoTime(),
          'duration_minutes': estimatedMinutes,
        };
    Map<String, dynamic> withActive(Map<String, dynamic> m) => {...m, 'is_active': isActive};

    final out = <Map<String, dynamic>>[
      // Fast path: your DB requires BOTH `provider_id` and `user_id` as NOT NULL.
      withActive({...coreTimeEst(), 'provider_id': providerId, 'user_id': providerId}),
      {...coreTimeEst(), 'provider_id': providerId, 'user_id': providerId},
      withActive({...coreNoTime(), 'provider_id': providerId, 'user_id': providerId}),
      {...coreNoTime(), 'provider_id': providerId, 'user_id': providerId},
      withActive({...coreTimeDur(), 'provider_id': providerId, 'user_id': providerId}),
      // Legacy single-key fallbacks
      withActive({...coreTimeEst(), 'provider_id': providerId}),
      withActive({...coreTimeEst(), 'user_id': providerId}),
      {...coreTimeEst(), 'provider_id': providerId},
      {...coreTimeEst(), 'user_id': providerId},
      withActive({...coreNoTime(), 'provider_id': providerId}),
      withActive({...coreNoTime(), 'user_id': providerId}),
      {...coreNoTime(), 'provider_id': providerId},
      {...coreNoTime(), 'user_id': providerId},
      withActive({...coreTimeDur(), 'provider_id': providerId}),
      withActive({...coreTimeDur(), 'user_id': providerId}),
    ];
    final seen = <String>{};
    return out.where((row) {
      final key = row.entries.map((e) => '${e.key}=${e.value}').join('|');
      return seen.add(key);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> listProviderInventory(String providerId) async {
    try {
      final rows = await _c
          .from('provider_inventory')
          .select()
          .eq('provider_id', providerId)
          .order('name');
      return List<Map<String, dynamic>>.from(rows as List<dynamic>).map((row) {
        row.putIfAbsent('available_for_mobile', () => true);
        row.putIfAbsent('item_category', () => 'part');
        row.putIfAbsent('low_stock_threshold', () => 5);
        row.putIfAbsent('stock_quantity', () => 0);
        return row;
      }).toList();
    } catch (e) {
      if (_isMissingSchemaError(e)) {
        // Graceful fallback while local DB is still on older schema.
        return <Map<String, dynamic>>[];
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listProviderEquipment(String providerId) async {
    try {
      final rows = await _c.from('provider_equipment').select().eq('provider_id', providerId).order('name');
      return List<Map<String, dynamic>>.from(rows as List<dynamic>);
    } catch (e) {
      if (_isMissingSchemaError(e)) return <Map<String, dynamic>>[];
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listServiceKits(String providerId) async {
    try {
      final rows = await _c.from('service_kits').select().eq('provider_id', providerId).order('name');
      return List<Map<String, dynamic>>.from(rows as List<dynamic>);
    } catch (e) {
      if (_isMissingSchemaError(e)) return <Map<String, dynamic>>[];
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listProviderServices(String providerId) async {
    try {
      final rows = await _c
          .from('provider_services')
          .select()
          .eq('provider_id', providerId)
          .order('name');
      return _normalizeProviderServiceRows(List<Map<String, dynamic>>.from(rows as List<dynamic>));
    } catch (e) {
      if (_isMissingSchemaError(e)) {
        try {
          final rows = await _c
              .from('provider_services')
              .select()
              .eq('user_id', providerId)
              .order('name');
          return _normalizeProviderServiceRows(List<Map<String, dynamic>>.from(rows as List<dynamic>));
        } catch (_) {
          return <Map<String, dynamic>>[];
        }
      }
      rethrow;
    }
  }

  Future<void> insertProviderService({
    required String providerId,
    required String name,
    required String category,
    required String description,
    required double price,
    required int estimatedMinutes,
    bool isActive = true,
  }) async {
    // Single category string avoids tripling insert attempts (reduces duplicate-key noise on web).
    final cat = category.trim();
    final payloads = _providerServiceInsertPayloads(
      providerId: providerId,
      name: name,
      category: cat,
      description: description,
      price: price,
      estimatedMinutes: estimatedMinutes,
      isActive: isActive,
    );
    Object? lastError;
    for (final row in payloads) {
      try {
        await _c.from('provider_services').insert(row);
        return;
      } catch (e) {
        lastError = e;
        if (kDebugMode) {
          final err = _sqlErr(e);
          debugPrint('provider_services insert failed keys=${row.keys.join(",")} code=${err.code} msg=${err.msg}');
        }
        if (_isDuplicateProviderServicesPkeyInsert(e)) {
          // Row was likely already inserted (e.g. first attempt succeeded then client retried).
          return;
        }
        if (!_isRetryableProviderServiceInsert(e)) {
          rethrow;
        }
      }
    }
    if (lastError != null) throw lastError;
  }

  Future<void> updateProviderService({
    required String id,
    required String name,
    required String category,
    required String description,
    required double price,
    required int estimatedMinutes,
  }) async {
    await _c.from('provider_services').update({
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'estimated_minutes': estimatedMinutes,
    }).eq('id', id);
  }

  Future<void> updateProviderServiceActive({
    required String id,
    required bool isActive,
  }) async {
    await _c.from('provider_services').update({'is_active': isActive}).eq('id', id);
  }

  Future<void> deleteProviderService(String id) async {
    await _c.from('provider_services').delete().eq('id', id);
  }

  /// Assigned to this provider, or open scheduled jobs visible in the pool.
  Future<List<Map<String, dynamic>>> listServiceRequestsHistory(String providerId) async {
    try {
      final rows = await _c
          .from('service_requests')
          .select()
          .eq('assigned_provider_id', providerId)
          .or('status.eq.finished,status.eq.cancelled')
          .order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List<dynamic>);
    } catch (e) {
      if (_isMissingSchemaError(e)) return <Map<String, dynamic>>[];
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listServiceRequestsForProvider(String providerId) async {
    dynamic assigned;
    dynamic open;
    try {
      assigned = await _c
          .from('service_requests')
          .select()
          .eq('assigned_provider_id', providerId)
          .order('created_at', ascending: false);
      open = await _c
          .from('service_requests')
          .select()
          .eq('status', 'open')
          .eq('request_kind', 'scheduled')
          .order('scheduled_start', ascending: true);
    } catch (e) {
      if (_isMissingSchemaError(e)) {
        // Legacy fallback without `request_kind` / `scheduled_start`.
        try {
          assigned = await _c
              .from('service_requests')
              .select()
              .eq('assigned_provider_id', providerId)
              .order('created_at', ascending: false);
          open = await _c
              .from('service_requests')
              .select()
              .eq('status', 'open')
              .order('created_at', ascending: false);
        } catch (_) {
          return <Map<String, dynamic>>[];
        }
      } else {
        rethrow;
      }
    }

    final a = List<Map<String, dynamic>>.from(assigned as List<dynamic>);
    final o = List<Map<String, dynamic>>.from(open as List<dynamic>);
    final seen = a.map((e) => e['id'].toString()).toSet();
    for (final row in o) {
      final id = row['id']?.toString();
      if (id != null && !seen.contains(id)) {
        a.add(row);
        seen.add(id);
      }
    }
    return a;
  }

  Future<void> insertInventoryItem({
    required String providerId,
    required String name,
    String? description,
    String? sku,
    String? barcode,
    int stockQuantity = 0,
    int lowStockThreshold = 5,
    double? unitPrice,
    String itemCategory = 'part',
    bool availableForMobile = true,
  }) async {
    final baseRow = <String, dynamic>{
      'provider_id': providerId,
      'name': name,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      if (unitPrice != null) 'unit_price': unitPrice,
      'item_category': itemCategory,
      'available_for_mobile': availableForMobile,
    };
    try {
      await _c.from('provider_inventory').insert(baseRow);
    } catch (e) {
      if (!_isMissingSchemaError(e)) rethrow;
      // Backward compatibility for older local schema.
      await _c.from('provider_inventory').insert({
        'provider_id': providerId,
        'name': name,
        if (description != null) 'description': description,
        if (sku != null) 'sku': sku,
        if (barcode != null) 'barcode': barcode,
        'stock_quantity': stockQuantity,
      });
    }
  }

  Future<void> setInventoryMobileAvailability({
    required String inventoryRowId,
    required bool availableForMobile,
  }) async {
    try {
      await _c.from('provider_inventory').update({'available_for_mobile': availableForMobile}).eq('id', inventoryRowId);
    } catch (e) {
      if (_isMissingSchemaError(e)) return;
      rethrow;
    }
  }

  Future<void> updateInventoryItem({
    required String inventoryRowId,
    required String name,
    String? description,
    String? sku,
    String? barcode,
    required int stockQuantity,
    required int lowStockThreshold,
    String itemCategory = 'part',
  }) async {
    final patch = <String, dynamic>{
      'name': name,
      'description': description ?? '',
      'sku': sku ?? '',
      'barcode': barcode ?? '',
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'item_category': itemCategory,
    };
    try {
      await _c.from('provider_inventory').update(patch).eq('id', inventoryRowId);
    } catch (e) {
      if (!_isMissingSchemaError(e)) rethrow;
      // Backward compatibility for older local schema.
      await _c.from('provider_inventory').update({
        'name': name,
        'description': description ?? '',
        'sku': sku ?? '',
        'barcode': barcode ?? '',
        'stock_quantity': stockQuantity,
      }).eq('id', inventoryRowId);
    }
  }

  Future<void> deleteInventoryItem(String inventoryRowId) async {
    await _c.from('provider_inventory').delete().eq('id', inventoryRowId);
  }

  Future<void> upsertEquipment({
    required String providerId,
    required String name,
    String status = 'available',
    String? notes,
  }) async {
    try {
      await _c.from('provider_equipment').insert({
        'provider_id': providerId,
        'name': name,
        'status': status,
        if (notes != null) 'notes': notes,
      });
    } catch (e) {
      if (_isMissingSchemaError(e)) return;
      rethrow;
    }
  }

  Future<void> updateEquipment({
    required String equipmentRowId,
    required String name,
    required String status,
    String? notes,
  }) async {
    await _c.from('provider_equipment').update({
      'name': name,
      'status': status,
      'notes': notes ?? '',
    }).eq('id', equipmentRowId);
  }

  Future<void> deleteEquipment(String equipmentRowId) async {
    await _c.from('provider_equipment').delete().eq('id', equipmentRowId);
  }

  Future<void> insertServiceKit({
    required String providerId,
    required String name,
    String? description,
    String? vehicleNotes,
  }) async {
    await _c.from('service_kits').insert({
      'provider_id': providerId,
      'name': name,
      'description': description ?? '',
      'vehicle_notes': vehicleNotes ?? '',
    });
  }

  Future<void> updateServiceKit({
    required String kitRowId,
    required String name,
    String? description,
    String? vehicleNotes,
  }) async {
    await _c.from('service_kits').update({
      'name': name,
      'description': description ?? '',
      'vehicle_notes': vehicleNotes ?? '',
    }).eq('id', kitRowId);
  }

  Future<void> deleteServiceKit(String kitRowId) async {
    await _c.from('service_kits').delete().eq('id', kitRowId);
  }
}

final providerOpsServiceProvider = Provider<ProviderOpsService>((ref) => ProviderOpsService());

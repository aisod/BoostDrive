import 'dart:io' show Platform;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists an FCM registration token for the signed-in user so the `sos-push-notify` Edge Function can reach this device.
/// Call this from your Firebase Messaging setup (after `FirebaseMessaging.instance.getToken()`), once `firebase_core` /
/// `firebase_messaging` and `google-services.json` / `GoogleService-Info.plist` are configured.
Future<void> upsertFcmDeviceTokenForCurrentUser(String fcmToken) async {
  final trimmed = fcmToken.trim();
  if (trimmed.isEmpty) return;
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return;

  final platform = Platform.isAndroid
      ? 'android'
      : Platform.isIOS
          ? 'ios'
          : 'other';

  await Supabase.instance.client.from('device_push_tokens').upsert(
    {
      'user_id': uid,
      'fcm_token': trimmed,
      'platform': platform,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    },
    onConflict: 'user_id,fcm_token',
  );
}

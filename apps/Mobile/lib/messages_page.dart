import 'dart:async';
import 'dart:typed_data';

import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:intl/intl.dart';
import 'mobile_app_bar_actions.dart';

class MessagesPage extends ConsumerStatefulWidget {
  final String? initialConversationId;
  
  const MessagesPage({super.key, this.initialConversationId});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

/// Holds a pending image attachment (bytes + name) until the user taps Send.
class _PendingAttachment {
  const _PendingAttachment({required this.bytes, required this.fileName});
  final Uint8List bytes;
  final String fileName;
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  String? _selectedConversationId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const int _maxAttachments = 5;
  List<_PendingAttachment>? _pendingAttachments;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecordingVoice = false;
  /// WhatsApp-style 3-mode voice: (A) Tap & hold → release = send; (B) Slide left = cancel; (C) Slide up = lock (hands-free, then Stop/Trash).
  /// Optional future: Supabase Edge + Whisper for transcript under the voice note.
  bool _voiceLocked = false;
  StreamSubscription<Uint8List>? _recordingSub;
  Completer<void>? _recordingStreamDone;
  final BytesBuilder _voiceBuffer = BytesBuilder();
  DateTime? _voiceRecordingStartTime;
  Timer? _voiceRecordingTimer;
  bool _voiceSlideToCancel = false;
  double _voiceDragOffsetX = 0;
  double _voiceDragOffsetY = 0;
  bool _voiceMicPulse = false;
  static const double _slideToCancelThresholdPx = 100;
  static const double _lockThresholdPx = 100;

  /// After stopping recording, the voice note is kept in memory until the user taps Send or Discard.
  /// No upload or send happens on stop—only when the user explicitly taps Send in the pending bar.
  Uint8List? _pendingVoiceNoteBytes;
  String _pendingVoiceNoteDuration = '0:00';
  /// When the pending bar was first shown; used to ignore accidental/immediate taps on Send.
  DateTime? _pendingVoiceNoteShownAt;
  /// When user taps "continue" on the pending bar: PCM to prepend to the next recording (append mode).
  Uint8List? _pendingPcmPrefix;
  /// Duration in seconds of _pendingPcmPrefix; added to timer when in append mode.
  int _pendingRecordingDurationSeconds = 0;
  /// Restore this duration string if user cancels while in append mode.
  String _pendingVoiceNoteDurationWhenContinued = '0:00';

  /// Polling fallback so the other user's messages appear without reload (Supabase filtered stream often only emits once).
  Timer? _messagePollTimer;
  static const Duration _messagePollInterval = Duration(seconds: 2);

  /// Lightweight polling for unread counts and the conversation list.
  /// Supabase Realtime can occasionally miss updates (especially across tabs),
  /// so this acts as a safety net to keep badges and the list fresh without
  /// requiring a full page reload.
  Timer? _unreadPollTimer;
  static const Duration _unreadPollInterval = Duration(seconds: 4);

  /// Which voice message URL is currently playing. Only one at a time; others stop when this changes.
  final ValueNotifier<String?> currentPlayingVoiceUrl = ValueNotifier<String?>(null);

  void _startMessagePolling() {
    _messagePollTimer?.cancel();
    if (_selectedConversationId == null) return;
    final conversationId = _selectedConversationId!;
    _messagePollTimer = Timer.periodic(_messagePollInterval, (_) {
      if (!mounted || _selectedConversationId != conversationId) {
        _messagePollTimer?.cancel();
        return;
      }
      final _ = ref.refresh(conversationMessagesProvider(conversationId));
    });
  }

  void _stopMessagePolling() {
    _messagePollTimer?.cancel();
    _messagePollTimer = null;
  }

  void _startUnreadPolling() {
    _unreadPollTimer?.cancel();
    _unreadPollTimer = Timer.periodic(_unreadPollInterval, (_) {
      if (!mounted) {
        _stopUnreadPolling();
        return;
      }
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Refresh unread badges + conversation list as a safety net when Realtime is flaky.
        ref.invalidate(unreadConversationsProvider(user.id));
        ref.invalidate(unreadCountByConversationProvider(user.id));
        ref.invalidate(userConversationsProvider(user.id));
      }
    });
  }

  void _stopUnreadPolling() {
    _unreadPollTimer?.cancel();
    _unreadPollTimer = null;
  }

  @override
  void initState() {
    super.initState();
    _pendingAttachments = [];
    _startUnreadPolling();
    if (widget.initialConversationId != null) {
      _selectedConversationId = widget.initialConversationId;
      // Mark as read if an initial conversation is provided (e.g. from notification tap)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(messageServiceProvider).markConversationAsRead(widget.initialConversationId!);
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && mounted) {
          ref.invalidate(unreadConversationsProvider(user.id));
          final _ = ref.refresh(unreadCountByConversationProvider(user.id));
        }
        if (mounted) _startMessagePolling();
      });
    }
  }

  @override
  void dispose() {
    _stopMessagePolling();
    _stopUnreadPolling();
    _voiceRecordingTimer?.cancel();
    currentPlayingVoiceUrl.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _recordingSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startVoiceRecording() async {
    if (_selectedConversationId == null || _isRecordingVoice) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to send voice messages')),
        );
      }
      return;
    }
    _voiceBuffer.clear();
    _recordingStreamDone = Completer<void>();
    final stream = await _audioRecorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 44100,
        numChannels: 1,
      ),
    );
    _recordingSub = stream.listen(
      (data) => _voiceBuffer.add(data),
      onDone: () => _recordingStreamDone?.complete(),
      onError: (_) => _recordingStreamDone?.complete(),
    );
    _voiceRecordingStartTime = DateTime.now();
    _voiceSlideToCancel = false;
    _voiceLocked = false;
    _voiceDragOffsetX = 0;
    _voiceDragOffsetY = 0;
    _voiceMicPulse = false;
    _voiceRecordingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _voiceMicPulse = !_voiceMicPulse);
    });
    if (mounted) setState(() => _isRecordingVoice = true);
  }

  Future<void> _toggleVoiceRecording() async {
    if (_selectedConversationId == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (!_isRecordingVoice) {
      await _startVoiceRecording();
      return;
    }

    if (_voiceSlideToCancel) {
      await _cancelVoiceRecording();
      return;
    }

    // Stop recording and show pending bar (user taps Send or Discard).
    final durationText = _voiceRecordingDurationText;
    setState(() {
      _isRecordingVoice = false;
      _voiceLocked = false;
      _voiceSlideToCancel = false;
      _voiceDragOffsetX = 0;
      _voiceDragOffsetY = 0;
    });
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;
    _voiceRecordingStartTime = null;
    try {
      await _audioRecorder.stop();
      await _recordingStreamDone?.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } catch (_) {
      // Ignore stop errors
    }
    _recordingSub?.cancel();
    _recordingSub = null;
    _recordingStreamDone = null;

    if (_voiceBuffer.isEmpty && _pendingPcmPrefix == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audio recorded. Try again.')),
        );
      }
      return;
    }
    final newPcm = _voiceBuffer.toBytes();
    _voiceBuffer.clear();
    final Uint8List fullPcm;
    if (_pendingPcmPrefix != null) {
      fullPcm = Uint8List.fromList([..._pendingPcmPrefix!, ...newPcm]);
      setState(() {
        _pendingPcmPrefix = null;
        _pendingRecordingDurationSeconds = 0;
        _pendingVoiceNoteDurationWhenContinued = '0:00';
      });
    } else {
      fullPcm = Uint8List.fromList(newPcm);
    }
    final bytes = _pcm16MonoToWav(fullPcm, 44100);

    // Stop only: keep the recording in memory. Do not upload or send here.
    // Delay before showing the pending bar so the tap that stopped recording cannot hit Send.
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _pendingVoiceNoteBytes = Uint8List.fromList(bytes);
        _pendingVoiceNoteDuration = durationText;
        _pendingVoiceNoteShownAt = DateTime.now();
      });
    }
  }

  Future<void> _sendPendingVoiceNote() async {
    final bytes = _pendingVoiceNoteBytes;
    if (bytes == null || _selectedConversationId == null) return;
    // Ignore taps that happen within 400ms of the pending bar appearing (avoids accidental send from same gesture as Stop).
    final shownAt = _pendingVoiceNoteShownAt;
    if (shownAt != null && DateTime.now().difference(shownAt) < const Duration(milliseconds: 400)) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() {
      _pendingVoiceNoteBytes = null;
      _pendingVoiceNoteDuration = '0:00';
      _pendingVoiceNoteShownAt = null;
    });
    try {
      final url = await ref.read(messageServiceProvider).uploadMessageAttachment(
        userId: user.id,
        bytes: bytes,
        fileName: 'voice_message.wav',
      );
      if (mounted) await _sendText(url);
    } catch (e) {
      if (mounted) {
        setState(() => _pendingVoiceNoteBytes = bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice note: $e')),
        );
      }
    }
  }

  void _discardPendingVoiceNote() {
    setState(() {
      _pendingVoiceNoteBytes = null;
      _pendingVoiceNoteDuration = '0:00';
      _pendingVoiceNoteShownAt = null;
      _pendingPcmPrefix = null;
      _pendingRecordingDurationSeconds = 0;
      _pendingVoiceNoteDurationWhenContinued = '0:00';
    });
  }

  /// Continue recording: append to the existing pending voice note (tap mic icon on pending bar).
  Future<void> _continueVoiceRecording() async {
    if (_pendingVoiceNoteBytes == null || _pendingVoiceNoteBytes!.length <= 44 || _isRecordingVoice) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to add more')),
        );
      }
      return;
    }
    // Decode WAV to PCM (skip 44-byte header); 16-bit mono 44100 Hz → seconds = length / 88200
    final pcm = Uint8List.fromList(_pendingVoiceNoteBytes!.sublist(44));
    final prefixSeconds = pcm.length ~/ 88200;
    setState(() {
      _pendingPcmPrefix = pcm;
      _pendingRecordingDurationSeconds = prefixSeconds;
      _pendingVoiceNoteDurationWhenContinued = _pendingVoiceNoteDuration;
      _pendingVoiceNoteBytes = null;
      _pendingVoiceNoteDuration = '0:00';
      _pendingVoiceNoteShownAt = null;
    });
    await _startVoiceRecording();
  }

  Future<void> _cancelVoiceRecording() async {
    if (!_isRecordingVoice) return;
    final wasAppending = _pendingPcmPrefix != null;
    final prefixPcm = _pendingPcmPrefix;
    final durationWhenContinued = _pendingVoiceNoteDurationWhenContinued;
    setState(() {
      _isRecordingVoice = false;
      _voiceLocked = false;
      _voiceSlideToCancel = false;
      _voiceDragOffsetX = 0;
      _voiceDragOffsetY = 0;
      _voiceMicPulse = false;
      _pendingPcmPrefix = null;
      _pendingRecordingDurationSeconds = 0;
      _pendingVoiceNoteDurationWhenContinued = '0:00';
    });
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;
    _voiceRecordingStartTime = null;
    try {
      await _audioRecorder.stop();
      await _recordingStreamDone?.future.timeout(const Duration(seconds: 2), onTimeout: () {});
    } catch (_) {}
    _recordingSub?.cancel();
    _recordingSub = null;
    _recordingStreamDone = null;
    _voiceBuffer.clear();
    if (wasAppending && prefixPcm != null && mounted) {
      final wav = _pcm16MonoToWav(prefixPcm, 44100);
      setState(() {
        _pendingVoiceNoteBytes = Uint8List.fromList(wav);
        _pendingVoiceNoteDuration = durationWhenContinued;
        _pendingVoiceNoteShownAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added part cancelled; previous recording kept')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice message cancelled')),
      );
    }
  }

  /// Called when user releases finger (Mode A: send immediately) or when pan ends on the bar.
  void _onVoiceRelease() {
    if (!_isRecordingVoice) return;
    if (_voiceSlideToCancel) {
      _cancelVoiceRecording();
      return;
    }
    if (_voiceLocked) return; // Keep recording hands-free; user will tap Stop or Trash.
    _stopAndSendVoiceNoteImmediately();
  }

  /// Mode A: Stop recording and send the voice note immediately (no pending bar).
  Future<void> _stopAndSendVoiceNoteImmediately() async {
    if (_selectedConversationId == null || !_isRecordingVoice) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() {
      _isRecordingVoice = false;
      _voiceLocked = false;
      _voiceSlideToCancel = false;
      _voiceDragOffsetX = 0;
      _voiceDragOffsetY = 0;
      _voiceMicPulse = false;
    });
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;
    _voiceRecordingStartTime = null;
    try {
      await _audioRecorder.stop();
      await _recordingStreamDone?.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } catch (_) {}
    _recordingSub?.cancel();
    _recordingSub = null;
    _recordingStreamDone = null;
    if (_voiceBuffer.isEmpty && _pendingPcmPrefix == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audio recorded. Try again.')),
        );
      }
      return;
    }
    final newPcm = _voiceBuffer.toBytes();
    _voiceBuffer.clear();
    final Uint8List fullPcm;
    if (_pendingPcmPrefix != null) {
      fullPcm = Uint8List.fromList([..._pendingPcmPrefix!, ...newPcm]);
      setState(() {
        _pendingPcmPrefix = null;
        _pendingRecordingDurationSeconds = 0;
        _pendingVoiceNoteDurationWhenContinued = '0:00';
      });
    } else {
      fullPcm = Uint8List.fromList(newPcm);
    }
    final bytes = _pcm16MonoToWav(fullPcm, 44100);
    try {
      final url = await ref.read(messageServiceProvider).uploadMessageAttachment(
        userId: user.id,
        bytes: Uint8List.fromList(bytes),
        fileName: 'voice_message.wav',
      );
      if (mounted) await _sendText(url);
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice note: $e')),
        );
      }
    }
  }

  String get _voiceRecordingDurationText {
    final baseSec = _voiceRecordingStartTime != null
        ? DateTime.now().difference(_voiceRecordingStartTime!).inSeconds
        : 0;
    final totalSec = baseSec + _pendingRecordingDurationSeconds;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onVoiceRecordingBarPanUpdate(DragUpdateDetails details) {
    _voiceDragOffsetX += details.delta.dx;
    _voiceDragOffsetY += details.delta.dy;
    if (!_voiceLocked && _voiceDragOffsetY <= -_lockThresholdPx) {
      setState(() => _voiceLocked = true);
    }
    if (!_voiceLocked && _voiceDragOffsetX <= -_slideToCancelThresholdPx && !_voiceSlideToCancel) {
      setState(() => _voiceSlideToCancel = true);
    }
  }

  void _onVoiceRecordingBarPanEnd(DragEndDetails details) {
    _onVoiceRelease();
  }

  void _onVoiceRecordingBarPanStart(DragStartDetails details) {
    _voiceDragOffsetX = 0;
    _voiceDragOffsetY = 0;
  }

  /// Sends the current input: text first (if any), then each image attachment in order.
  Future<void> _sendMessage() async {
    if (_selectedConversationId == null) return;
    final text = _messageController.text.trim();
    final hasText = text.isNotEmpty;
    final attachments = List<_PendingAttachment>.from(_pendingAttachments ?? []);
    final hasImages = attachments.isNotEmpty;
    if (!hasText && !hasImages) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final conversationId = _selectedConversationId!;

    try {
      // 1. Always send text first so it appears above the image(s) in the chat.
      if (hasText) {
        await _sendText(text);
        // Brief delay so the text message gets an earlier timestamp than the following image(s).
        if (attachments.isNotEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      }
      // 2. Then send each image as a separate message, in the order they were attached.
      for (final att in attachments) {
        final url = await ref.read(messageServiceProvider).uploadMessageAttachment(
          userId: user.id,
          bytes: att.bytes,
          fileName: att.fileName,
        );
        await _sendText(url);
      }
      if (!mounted) return;
      setState(() {
        _pendingAttachments?.clear();
        _messageController.clear();
      });
      final _ = ref.refresh(conversationMessagesProvider(conversationId));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  /// Sends a message with the given content (used for reactions, image URLs, voice placeholder).
  /// Invalidates the conversation messages stream so the new message appears immediately.
  Future<void> _sendText(String content) async {
    if (_selectedConversationId == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final conversationId = _selectedConversationId!;
    try {
      await ref.read(messageServiceProvider).sendMessage(
        conversationId: conversationId,
        senderId: user.id,
        content: content,
      );
      if (!mounted) return;
      final _ = ref.refresh(conversationMessagesProvider(conversationId));
      // Scroll to show the latest message (only if the list is mounted)
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  /// Pick image(s) and add to pending attachments (max 5). Shown in the input area until user taps Send.
  Future<void> _pickAndAddImages(ImageSource source) async {
    _pendingAttachments ??= [];
    if (_pendingAttachments!.length >= _maxAttachments) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maximum $_maxAttachments images at a time')),
        );
      }
      return;
    }
    try {
      final picker = ImagePicker();
      final List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await picker.pickMultiImage(imageQuality: 85);
      } else {
        final single = await picker.pickImage(source: source, imageQuality: 85);
        picked = single != null ? [single] : [];
      }
      if (!mounted) return;
      for (final xFile in picked) {
        if (_pendingAttachments!.length >= _maxAttachments) break;
        final bytes = await xFile.readAsBytes();
        final fileName = xFile.name.isNotEmpty ? xFile.name : 'image.jpg';
        setState(() => _pendingAttachments!.add(_PendingAttachment(bytes: bytes, fileName: fileName)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add image: $e')),
        );
      }
    }
  }

  void _removePendingImage(int index) {
    setState(() => _pendingAttachments?.removeAt(index));
  }

  Widget _buildVoiceRecordingBar() {
    final palette = DashboardPalette.of(context);
    return GestureDetector(
      onPanStart: _onVoiceRecordingBarPanStart,
      onPanUpdate: _onVoiceRecordingBarPanUpdate,
      onPanEnd: _onVoiceRecordingBarPanEnd,
      child: MessagesUi.voiceRecordingBar(
        palette: palette,
        durationText: _voiceRecordingDurationText,
        hintText: _voiceLocked
            ? 'Recording locked • Tap Stop or Trash'
            : _voiceSlideToCancel
                ? 'Release to cancel'
                : 'Slide left to cancel • Slide up to lock',
        micPulse: _voiceMicPulse,
        voiceLocked: _voiceLocked,
        voiceSlideToCancel: _voiceSlideToCancel,
        onStop: _toggleVoiceRecording,
        onCancel: _cancelVoiceRecording,
        onDelete: _voiceLocked ? _cancelVoiceRecording : null,
      ),
    );
  }

  /// Bar shown after stopping a voice recording: user can Send or Discard before the message is sent.
  /// Tapping the mic icon or "Voice note" label continues recording (appends to the same note).
  Widget _buildPendingVoiceNoteBar() {
    final palette = DashboardPalette.of(context);
    return MessagesUi.pendingVoiceBar(
      palette: palette,
      durationLabel: _pendingVoiceNoteDuration,
      onContinue: _continueVoiceRecording,
      onSend: _sendPendingVoiceNote,
      onDiscard: _discardPendingVoiceNote,
    );
  }

  Widget _buildPendingThumbnails() {
    final palette = DashboardPalette.of(context);
    final list = _pendingAttachments ?? [];
    return MessagesUi.pendingImageThumbnails(
      palette: palette,
      thumbnails: List.generate(list.length, (index) {
        final att = list[index];
        return MessagesUi.pendingImageThumb(
          palette: palette,
          onRemove: () => _removePendingImage(index),
          image: Image.memory(att.bytes, width: 56, height: 56, fit: BoxFit.cover),
        );
      }),
    );
  }

  void _showEmojiPicker() {
    final palette = DashboardPalette.of(context);
    final emojis = [
      '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '👍', '👋', '🙌', '👏', '❤️', '🔥', '⭐', '✅', '❌', '💯', '🎉', '🙏',
    ];
    MessagesUi.showEmojiPicker(
      context: context,
      palette: palette,
      emojis: emojis,
      onEmojiSelected: (e) {
        final pos = _messageController.selection.baseOffset;
        final text = _messageController.text;
        if (pos >= 0 && pos <= text.length) {
          _messageController.text = '${text.substring(0, pos)}$e${text.substring(pos)}';
          _messageController.selection = TextSelection.collapsed(offset: pos + e.length);
        } else {
          _messageController.text = text + e;
          _messageController.selection = TextSelection.collapsed(offset: _messageController.text.length);
        }
      },
    );
  }

  String _formatMessageDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final DateTime date = timestamp is String ? DateTime.parse(timestamp) : timestamp as DateTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final DateTime date = timestamp is String ? DateTime.parse(timestamp) : timestamp as DateTime;
    return DateFormat('HH:mm').format(date);
  }

  /// Listing type label for a conversation (product category or repair).
  /// Used in list and chat header so buyer/seller see e.g. "Vehicle for sale", "Spare part for sale", "Car for rent", or "Repair job".
  String _listingTypeLabel(String? category, {bool isRepairFallback = true}) {
    if (category == null || category.isEmpty) return isRepairFallback ? 'Repair job' : 'Product';
    switch (category.toLowerCase()) {
      case 'car':
        return 'Vehicle for sale';
      case 'part':
        return 'Spare part for sale';
      case 'rental':
        return 'Car for rent';
      default:
        return isRepairFallback ? 'Repair job' : category;
    }
  }

  /// Role of the other party in this conversation (for current user: "Buyer" or "Seller").
  String _otherPartyRoleLabel(String currentUserId, String? buyerId, String? sellerId) {
    if (buyerId == currentUserId) return 'Seller'; // I am buyer → other is seller
    if (sellerId == currentUserId) return 'Buyer';  // I am seller → other is buyer
    return 'User';
  }

  Widget _buildMessageInputBar({bool isSuspended = false}) {
    final palette = DashboardPalette.of(context);
    if (isSuspended) {
      return MessagesUi.suspendedBanner(palette);
    }

    return MessagesUi.composerShell(
      palette: palette,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!kIsWeb)
            MessagesUi.composerIconButton(
              palette: palette,
              icon: Icons.camera_alt_rounded,
              onPressed: () => _pickAndAddImages(ImageSource.camera),
              tooltip: 'Camera',
            ),
          MessagesUi.composerIconButton(
            palette: palette,
            icon: Icons.photo_library_rounded,
            onPressed: () => _pickAndAddImages(ImageSource.gallery),
            tooltip: 'Attach image',
          ),
          GestureDetector(
            onLongPressStart: (_) => _startVoiceRecording(),
            onLongPressEnd: (_) => _onVoiceRelease(),
            onPanUpdate: (d) {
              if (!_isRecordingVoice) return;
              setState(() {
                _voiceDragOffsetX += d.delta.dx;
                _voiceDragOffsetY += d.delta.dy;
                if (!_voiceLocked && _voiceDragOffsetY <= -_lockThresholdPx) _voiceLocked = true;
                if (!_voiceLocked && _voiceDragOffsetX <= -_slideToCancelThresholdPx) _voiceSlideToCancel = true;
              });
            },
            onPanEnd: (_) => _onVoiceRelease(),
            child: MessagesUi.composerIconButton(
              palette: palette,
              icon: _isRecordingVoice ? Icons.stop_circle_rounded : Icons.mic_rounded,
              iconColor: _isRecordingVoice ? palette.error : null,
              onPressed: _toggleVoiceRecording,
              tooltip: _isRecordingVoice
                  ? 'Release to send • Slide left to cancel • Slide up to lock'
                  : 'Hold to record • Release to send',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: MessagesUi.composerTextFieldShell(
              palette: palette,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isRecordingVoice) _buildVoiceRecordingBar(),
                  if (_pendingVoiceNoteBytes != null) _buildPendingVoiceNoteBar(),
                  if ((_pendingAttachments ?? []).isNotEmpty) _buildPendingThumbnails(),
                  TextField(
                    controller: _messageController,
                    style: GoogleFonts.manrope(fontSize: 15, color: palette.title),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 4,
                    minLines: 1,
                    decoration: MessagesUi.composerInputDecoration(palette).copyWith(
                      suffixIcon: IconButton(
                        onPressed: _showEmojiPicker,
                        icon: Icon(Icons.emoji_emotions_outlined, color: palette.onSurfaceVariant, size: 22),
                        tooltip: 'Emoji',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          MessagesUi.composerIconButton(
            palette: palette,
            icon: Icons.thumb_up_rounded,
            onPressed: () => _sendText('👍'),
            tooltip: 'Like',
          ),
          const SizedBox(width: 4),
          MessagesUi.sendButton(palette: palette, onTap: _sendMessage),
        ],
      ),
    );
  }

  Widget _buildOtherUserAvatar(
    UserProfile? profile, {
    double radius = 22,
    bool showOnlineDot = false,
  }) {
    final palette = DashboardPalette.of(context);
    final isSupport = profile?.role == 'admin' || profile?.role == 'super_admin';
    final name = (profile?.fullName != null && profile!.fullName.isNotEmpty)
        ? profile.fullName
        : (isSupport ? 'BoostDrive Support' : '?');
    final initial = isSupport ? 'S' : (name.isNotEmpty ? name[0].toUpperCase() : '?');
    return MessagesUi.otherUserAvatar(
      palette: palette,
      initial: initial,
      imageUrl: profile?.profileImg,
      isSupport: isSupport,
      radius: radius,
      showOnlineDot: showOnlineDot,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return MessagesUi.loginRequired(palette);
    }

    final profileAsync = ref.watch(userProfileProvider(user.id));
    final isSuspended = profileAsync.when(
      data: (p) => p?.status == 'suspended' || p?.status == 'banned',
      loading: () => false,
      error: (_, _) => false,
    );

    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      final inChat = _selectedConversationId != null;
      return Scaffold(
        backgroundColor: MessagesUi.scaffoldBackground(palette),
        appBar: inChat
            ? MessagesUi.chatAppBar(
                context: context,
                palette: palette,
                onBack: () => setState(() => _selectedConversationId = null),
                trailing: mobileAppBarActions(),
              )
            : MessagesUi.listAppBar(context: context, palette: palette),
        body: inChat
            ? _buildChatView(user.id, isSuspended: isSuspended)
            : _buildConversationList(user.id),
      );
    }

    return Scaffold(
      backgroundColor: MessagesUi.scaffoldBackground(palette),
      body: Row(
        children: [
          SizedBox(
            width: 350,
            child: Container(
              decoration: BoxDecoration(
                color: palette.surfaceContainerLow,
                border: Border(right: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.2))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MessagesUi.tabletListHeader(palette),
                  Expanded(child: _buildConversationList(user.id)),
                ],
              ),
            ),
          ),
          Expanded(
            child: _selectedConversationId == null
                ? _buildEmptyState()
                : _buildChatView(user.id, isSuspended: isSuspended),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(String conversationId, String productTitle) async {
    final palette = DashboardPalette.of(context);
    final confirmed = await MessagesUi.showDeleteDialog(context, palette);

    if (confirmed == true) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      try {
        await ref.read(messageServiceProvider).deleteConversation(conversationId);

        if (!mounted) return;

        // Force conversation list and related data to refresh immediately
        // ignore: unused_result
        ref.refresh(userConversationsProvider(user.id));
        ref.invalidate(unreadConversationsProvider(user.id));
        // ignore: unused_result
        ref.refresh(conversationMessagesProvider(conversationId));

        // Clear selection if we deleted the currently selected conversation
        if (_selectedConversationId == conversationId) {
          _stopMessagePolling();
          setState(() {
            _selectedConversationId = null;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete conversation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildConversationList(String userId) {
    final palette = DashboardPalette.of(context);
    return ref.watch(userConversationsProvider(userId)).when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return MessagesUi.emptyConversationList(palette);
        }

        final sortedConversations = List<Map<String, dynamic>>.from(conversations);
        sortedConversations.sort((a, b) {
          final aTime = a['created_at'] != null ? DateTime.parse(a['created_at']) : DateTime(2000);
          final bTime = b['created_at'] != null ? DateTime.parse(b['created_at']) : DateTime(2000);
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: sortedConversations.length,
          itemBuilder: (context, index) {
            final conv = sortedConversations[index];
            final isSelected = conv['id'] == _selectedConversationId;
            final otherUserId = conv['buyer_id'] == userId ? conv['seller_id'] : conv['buyer_id'];
            final productId = conv['product_id'] as String?;
            final productAsync = ref.watch(productByIdProvider(productId ?? ''));
            final product = productAsync.valueOrNull;
            final isDirectMessage = productId == null || productId.isEmpty;
            final listingType = isDirectMessage ? 'Support' : _listingTypeLabel(product?.category);
            final productTitle =
                product?.title ?? conv['product_title'] ?? (isDirectMessage ? 'General Inquiry' : 'Product');

            final otherProfile = ref.watch(userProfileProvider(otherUserId ?? '')).valueOrNull;
            final isOtherAdmin = otherProfile?.role == 'admin' || otherProfile?.role == 'super_admin';
            final otherName = otherProfile != null
                ? otherProfile.displayName
                : (isOtherAdmin ? 'BoostDrive Support' : 'User');
            final roleLabel =
                isOtherAdmin ? 'Support' : _otherPartyRoleLabel(userId, conv['buyer_id'] as String?, conv['seller_id'] as String?);

            final unreadConvs = ref.watch(unreadConversationsProvider(userId)).value ?? {};
            final isUnread = unreadConvs.contains(conv['id']);
            final unreadCounts = ref.watch(unreadCountByConversationProvider(userId)).value ?? {};
            final unreadCount = isSelected ? 0 : (unreadCounts[conv['id']] ?? 0);

            final avatar = ref.watch(userProfileProvider(otherUserId)).when(
              data: (profile) => _buildOtherUserAvatar(profile, radius: 24),
              loading: () => CircleAvatar(
                radius: 24,
                backgroundColor: palette.surfaceContainer,
                child: CircularProgressIndicator(strokeWidth: 2, color: palette.primaryContainer),
              ),
              error: (_, _) => CircleAvatar(
                radius: 24,
                backgroundColor: palette.surfaceContainer,
                child: Icon(Icons.person, color: palette.onSurfaceVariant),
              ),
            );

            return MessagesUi.conversationTile(
              palette: palette,
              isSelected: isSelected,
              isUnread: isUnread,
              avatar: avatar,
              displayName: otherName,
              listingTypeLabel: listingType,
              isDirectMessage: isDirectMessage,
              roleLabel: roleLabel,
              productTitle: productTitle,
              previewText: conv['last_message'] ?? 'Start a conversation',
              dateLabel: conv['created_at'] != null ? _formatMessageDate(conv['created_at']) : null,
              unreadCount: unreadCount,
              onTap: () async {
                setState(() => _selectedConversationId = conv['id']);
                _startMessagePolling();
                await ref.read(messageServiceProvider).markConversationAsRead(conv['id']);
                if (mounted) {
                  ref.invalidate(unreadConversationsProvider(userId));
                  final _ = ref.refresh(unreadCountByConversationProvider(userId));
                }
              },
              onDelete: () => _showDeleteConfirmation(conv['id'], productTitle),
            );
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: palette.primaryContainer)),
      error: (err, _) => Center(
        child: Text('Error: $err', style: TextStyle(color: palette.error)),
      ),
    );
  }

  Widget _buildChatView(String userId, {bool isSuspended = false}) {
    final palette = DashboardPalette.of(context);

    return Column(
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: ref.read(messageServiceProvider).getConversation(_selectedConversationId!),
          builder: (context, convSnapshot) {
            if (!convSnapshot.hasData) return const SizedBox();
            final conversation = convSnapshot.data!;
            final otherUserId =
                conversation['buyer_id'] == userId ? conversation['seller_id'] : conversation['buyer_id'];
            final chatProductId = conversation['product_id'] as String?;
            final chatProduct = ref.watch(productByIdProvider(chatProductId ?? '')).valueOrNull;
            final isChatDirect = chatProductId == null || chatProductId.isEmpty;
            final chatListingType = isChatDirect ? 'Support' : _listingTypeLabel(chatProduct?.category);
            final chatProductTitle =
                chatProduct?.title ?? conversation['product_title'] ?? (isChatDirect ? 'General Inquiry' : 'Product');

            final otherChatProfile = ref.watch(userProfileProvider(otherUserId ?? '')).valueOrNull;
            final isOtherChatAdmin =
                otherChatProfile?.role == 'admin' || otherChatProfile?.role == 'super_admin';
            final otherChatName = otherChatProfile != null
                ? otherChatProfile.displayName
                : (isOtherChatAdmin ? 'BoostDrive Support' : 'User');
            final chatRoleLabel = isOtherChatAdmin
                ? 'Support'
                : _otherPartyRoleLabel(userId, conversation['buyer_id'] as String?, conversation['seller_id'] as String?);

            final contextLine = isChatDirect ? chatProductTitle : 'Re: $chatProductTitle';

            final avatar = ref.watch(userProfileProvider(otherUserId)).when(
              data: (profile) => _buildOtherUserAvatar(profile, radius: 22, showOnlineDot: true),
              loading: () => CircleAvatar(
                radius: 22,
                backgroundColor: palette.surfaceContainer,
                child: CircularProgressIndicator(strokeWidth: 2, color: MessagesUi.primaryButtonFg(palette)),
              ),
              error: (_, _) => CircleAvatar(
                radius: 22,
                child: Icon(Icons.person, color: MessagesUi.primaryButtonFg(palette)),
              ),
            );

            return MessagesUi.chatParticipantHeader(
              palette: palette,
              avatar: avatar,
              displayName: otherChatName,
              contextLine: contextLine,
              listingTypeLabel: chatListingType,
              isDirectMessage: isChatDirect,
              roleLabel: palette.isDark ? chatRoleLabel : null,
            );
          },
        ),
        Expanded(
          child: ColoredBox(
            color: MessagesUi.threadBackground(palette),
            child: ref.watch(conversationMessagesProvider(_selectedConversationId!)).when(
              data: (messages) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: ref.read(messageServiceProvider).getConversation(_selectedConversationId!),
                  builder: (context, convSnapshot) {
                    if (!convSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator(color: palette.primaryContainer));
                    }
                    final conversation = convSnapshot.data!;
                    final buyerId = conversation['buyer_id'] as String;
                    final sellerId = conversation['seller_id'] as String;
                    final sortedMessages = messages.reversed.toList();
                    return _buildMessageList(sortedMessages, buyerId, sellerId, userId);
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator(color: palette.primaryContainer)),
              error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: palette.error))),
            ),
          ),
        ),
        Divider(height: 1, color: palette.outlineVariant.withValues(alpha: palette.isDark ? 0.15 : 0.35)),
        _buildMessageInputBar(isSuspended: isSuspended),
      ],
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages, String buyerId, String sellerId, String currentUserId) {
    final palette = DashboardPalette.of(context);
    final metaBelowBubble = !palette.isDark;
    final maxWidth = MediaQuery.of(context).size.width * (MediaQuery.of(context).size.width < 900 ? 0.78 : 0.45);

    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final senderId = msg['sender_id'] as String;
        final isBuyerMessage = senderId == buyerId;
        final isMe = senderId == currentUserId;
        final timeLabel = _formatMessageTime(msg['created_at']);

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (index == messages.length - 1 || _shouldShowDateHeader(messages[index], messages[index + 1]))
                MessagesUi.dateSeparator(palette, _formatMessageDate(msg['created_at'])),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: MessagesUi.messageBubbleDecoration(palette: palette, isMe: isMe),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMe)
                            Consumer(
                              builder: (context, ref, child) {
                                final senderProfile = ref.watch(userProfileProvider(senderId)).valueOrNull;
                                final isSenderAdmin = senderProfile?.role == 'admin' ||
                                    senderProfile?.role == 'super_admin';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    isSenderAdmin ? 'Support' : (isBuyerMessage ? 'Buyer' : 'Seller'),
                                    style: MessagesUi.senderLabelStyle(palette, isAdmin: isSenderAdmin),
                                  ),
                                );
                              },
                            ),
                          if (_isImageUrl(msg['content'] as String? ?? ''))
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                msg['content'] as String,
                                width: 200,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) => progress == null
                                    ? child
                                    : SizedBox(
                                        width: 200,
                                        height: 150,
                                        child: Center(
                                          child: CircularProgressIndicator(color: palette.primaryContainer),
                                        ),
                                      ),
                                errorBuilder: (_, _, _) => Text(
                                  msg['content'] as String,
                                  style: MessagesUi.messageTextStyle(palette, isMe: isMe),
                                ),
                              ),
                            )
                          else if (_isAudioUrl(msg['content'] as String? ?? ''))
                            _VoiceMessagePlayer(
                              url: msg['content'] as String,
                              isMe: isMe,
                              currentPlayingUrlNotifier: currentPlayingVoiceUrl,
                            )
                          else
                            Text(
                              msg['content'] as String,
                              style: MessagesUi.messageTextStyle(palette, isMe: isMe),
                            ),
                          if (!metaBelowBubble)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: MessagesUi.messageMetaRow(
                                palette: palette,
                                isMe: isMe,
                                timeLabel: timeLabel,
                                isRead: msg['is_read'] == true,
                                isDelivered: true,
                                belowBubble: false,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (metaBelowBubble)
                      MessagesUi.messageMetaRow(
                        palette: palette,
                        isMe: isMe,
                        timeLabel: timeLabel,
                        isRead: msg['is_read'] == true,
                        isDelivered: true,
                        belowBubble: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a WAV file (44-byte header + PCM) from raw PCM 16-bit mono so it can be played in browser.
  static Uint8List _pcm16MonoToWav(Uint8List pcm, int sampleRate) {
    final numChannels = 1;
    final bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * (bitsPerSample >> 3);
    final dataSize = pcm.length;
    final fileSize = 36 + dataSize;
    final out = BytesBuilder();
    out.add('RIFF'.codeUnits);
    out.add(_uint32ToBytes(fileSize));
    out.add('WAVE'.codeUnits);
    out.add('fmt '.codeUnits);
    out.add(_uint32ToBytes(16));
    out.add(_uint16ToBytes(1));
    out.add(_uint16ToBytes(numChannels));
    out.add(_uint32ToBytes(sampleRate));
    out.add(_uint32ToBytes(byteRate));
    out.add(_uint16ToBytes((numChannels * bitsPerSample) >> 3));
    out.add(_uint16ToBytes(bitsPerSample));
    out.add('data'.codeUnits);
    out.add(_uint32ToBytes(dataSize));
    out.add(pcm);
    return out.toBytes();
  }

  static List<int> _uint32ToBytes(int v) => [v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff];
  static List<int> _uint16ToBytes(int v) => [v & 0xff, (v >> 8) & 0xff];

  static bool _isImageUrl(String content) {
    final s = content.trim();
    if (!s.startsWith('http://') && !s.startsWith('https://')) return false;
    final lower = s.toLowerCase();
    return lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png') ||
        lower.contains('.gif') || lower.contains('.webp') || lower.contains('image');
  }

  static bool _isAudioUrl(String content) {
    final lower = content.trim().toLowerCase();
    return lower.endsWith('.webm') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.wav');
  }

  bool _shouldShowDateHeader(Map<String, dynamic> current, Map<String, dynamic> next) {
    if (current['created_at'] == null || next['created_at'] == null) return false;
    final date1 = DateTime.parse(current['created_at']);
    final date2 = DateTime.parse(next['created_at']);
    return date1.day != date2.day || date1.month != date2.month || date1.year != date2.year;
  }

  Widget _buildEmptyState() {
    return MessagesUi.emptyChatSelection(DashboardPalette.of(context));
  }
}

/// In-app player for voice message URLs so the receiver can play without leaving the app.
/// Only one voice note plays at a time; starting another stops the current one.
class _VoiceMessagePlayer extends StatefulWidget {
  const _VoiceMessagePlayer({
    required this.url,
    required this.isMe,
    required this.currentPlayingUrlNotifier,
  });

  final String url;
  final bool isMe;
  final ValueNotifier<String?> currentPlayingUrlNotifier;

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;
  String? _error;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;
  void _onCurrentPlayingUrlChanged() {
    final current = widget.currentPlayingUrlNotifier.value;
    if (current != null && current != widget.url && _playing && mounted) {
      _player.stop();
      setState(() {
        _playing = false;
        _position = Duration.zero;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      widget.currentPlayingUrlNotifier.value = null;
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });

    widget.currentPlayingUrlNotifier.addListener(_onCurrentPlayingUrlChanged);

    // Preload the audio source so we know the full duration
    // before the user taps play (WhatsApp-style voice notes).
    _player.setSource(UrlSource(widget.url)).catchError((_) {});
  }

  @override
  void dispose() {
    widget.currentPlayingUrlNotifier.removeListener(_onCurrentPlayingUrlChanged);
    if (_playing) {
      widget.currentPlayingUrlNotifier.value = null;
    }
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay() async {
    if (_loading) return;
    try {
      if (_playing) {
        await _player.pause();
        widget.currentPlayingUrlNotifier.value = null;
        setState(() => _playing = false);
        return;
      }
      setState(() { _loading = true; _error = null; });
      widget.currentPlayingUrlNotifier.value = widget.url;
      await _player.play(UrlSource(widget.url));
      if (mounted) setState(() { _playing = true; _loading = false; });
    } catch (e) {
      widget.currentPlayingUrlNotifier.value = null;
      if (mounted) {
        setState(() {
          _loading = false;
          _playing = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final color = widget.isMe ? MessagesUi.primaryButtonFg(palette) : palette.title;
    final secondary = palette.onSurfaceVariant;
    if (_error != null) {
      return Text(
        'Could not play',
        style: TextStyle(color: secondary, fontSize: 13),
      );
    }
    final hasDuration = _duration.inMilliseconds > 0;
    final progress = hasDuration
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    final timeLabel = hasDuration
        ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
        : _formatDuration(_position);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : _togglePlay,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _loading ? Icons.hourglass_empty_rounded : (_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                color: color,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: secondary.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeLabel,
                    style: TextStyle(color: secondary, fontSize: 11, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

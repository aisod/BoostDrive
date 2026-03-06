import 'dart:async';
import 'dart:typed_data';

import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:intl/intl.dart';

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
  StreamSubscription<Uint8List>? _recordingSub;
  Completer<void>? _recordingStreamDone;
  final BytesBuilder _voiceBuffer = BytesBuilder();
  DateTime? _voiceRecordingStartTime;
  Timer? _voiceRecordingTimer;
  bool _voiceSlideToCancel = false;
  double _voiceDragOffset = 0;
  static const double _slideToCancelThreshold = 80;

  @override
  void initState() {
    super.initState();
    _pendingAttachments = [];
    if (widget.initialConversationId != null) {
      _selectedConversationId = widget.initialConversationId;
      // Mark as read if an initial conversation is provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(messageServiceProvider).markConversationAsRead(widget.initialConversationId!);
      });
    }
  }

  @override
  void dispose() {
    _voiceRecordingTimer?.cancel();
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
    _voiceDragOffset = 0;
    _voiceRecordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
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

    // Stop recording: stop the recorder and wait for stream to close so we get all data
    setState(() => _isRecordingVoice = false);
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;
    _voiceRecordingStartTime = null;
    _voiceSlideToCancel = false;
    _voiceDragOffset = 0;
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

    if (_voiceBuffer.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audio recorded. Try again.')),
        );
      }
      return;
    }
    final pcmBytes = _voiceBuffer.toBytes();
    _voiceBuffer.clear();
    final bytes = _pcm16MonoToWav(pcmBytes, 44100);

    try {
      final url = await ref.read(messageServiceProvider).uploadMessageAttachment(
        userId: user.id,
        bytes: bytes,
        fileName: 'voice_message.wav',
      );
      await _sendText(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice message: $e')),
        );
      }
    }
  }

  Future<void> _cancelVoiceRecording() async {
    if (!_isRecordingVoice) return;
    setState(() => _isRecordingVoice = false);
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;
    _voiceRecordingStartTime = null;
    _voiceSlideToCancel = false;
    _voiceDragOffset = 0;
    try {
      await _audioRecorder.stop();
      await _recordingStreamDone?.future.timeout(const Duration(seconds: 2), onTimeout: () {});
    } catch (_) {}
    _recordingSub?.cancel();
    _recordingSub = null;
    _recordingStreamDone = null;
    _voiceBuffer.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice message cancelled')),
      );
    }
  }

  String get _voiceRecordingDurationText {
    if (_voiceRecordingStartTime == null) return '0:00';
    final sec = DateTime.now().difference(_voiceRecordingStartTime!).inSeconds;
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _onVoiceRecordingBarPanUpdate(DragUpdateDetails details) {
    _voiceDragOffset += details.delta.dx;
    if (_voiceDragOffset < -_slideToCancelThreshold && !_voiceSlideToCancel) {
      setState(() => _voiceSlideToCancel = true);
    }
  }

  void _onVoiceRecordingBarPanEnd(DragEndDetails details) {
    if (_voiceSlideToCancel) {
      _cancelVoiceRecording();
    }
  }

  void _onVoiceRecordingBarPanStart(DragStartDetails details) {
    _voiceDragOffset = 0;
  }

  Future<void> _sendMessage() async {
    if (_selectedConversationId == null) return;
    final text = _messageController.text.trim();
    final hasText = text.isNotEmpty;
    final hasImages = (_pendingAttachments ?? []).isNotEmpty;
    if (!hasText && !hasImages) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final conversationId = _selectedConversationId!;

    try {
      if (hasText) await _sendText(text);
      for (final att in _pendingAttachments ?? []) {
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
      ref.invalidate(conversationMessagesProvider(conversationId));
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
      // Force the message list to refresh so the sent message appears immediately
      ref.invalidate(conversationMessagesProvider(conversationId));
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
    return GestureDetector(
      onPanStart: _onVoiceRecordingBarPanStart,
      onPanUpdate: _onVoiceRecordingBarPanUpdate,
      onPanEnd: _onVoiceRecordingBarPanEnd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.mic_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              _voiceRecordingDurationText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _voiceSlideToCancel ? 'Release to cancel' : 'Slide to cancel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: _voiceSlideToCancel ? 0.9 : 0.6),
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              onPressed: _voiceSlideToCancel ? _cancelVoiceRecording : _toggleVoiceRecording,
              icon: Icon(
                _voiceSlideToCancel ? Icons.close_rounded : Icons.send_rounded,
                color: _voiceSlideToCancel ? Colors.white70 : BoostDriveTheme.primaryColor,
                size: 24,
              ),
              tooltip: _voiceSlideToCancel ? 'Cancel' : 'Send',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingThumbnails() {
    final list = _pendingAttachments ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(list.length, (index) {
            final att = list[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      att.bytes,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => _removePendingImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    final emojis = [
      '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '👍', '👋', '🙌', '👏', '❤️', '🔥', '⭐', '✅', '❌', '💯', '🎉', '🙏',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: BoostDriveTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emojis.map((e) => InkWell(
            onTap: () {
              final pos = _messageController.selection.baseOffset;
              final text = _messageController.text;
              if (pos >= 0 && pos <= text.length) {
                _messageController.text = '${text.substring(0, pos)}$e${text.substring(pos)}';
                _messageController.selection = TextSelection.collapsed(offset: pos + e.length);
              } else {
                _messageController.text = text + e;
                _messageController.selection = TextSelection.collapsed(offset: _messageController.text.length);
              }
              Navigator.pop(ctx);
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(e, style: const TextStyle(fontSize: 28)),
            ),
          )).toList(),
        ),
      ),
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

  static const Color _inputBarBg = Color(0xFF0D0D0D);
  static const Color _inputIconColor = Colors.white;

  /// Message input bar: camera (mobile only), gallery, mic, text field (Aa + emoji), thumbs-up, send (far right).
  /// Colors: black (bar bg), orange (send), white (icons).
  Widget _buildMessageInputBar() {
    return Container(
      color: _inputBarBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Camera – only on mobile, not web
            if (!kIsWeb)
              IconButton(
                onPressed: () => _pickAndAddImages(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, color: _inputIconColor, size: 24),
                tooltip: 'Camera',
              ),
            // Gallery – add to pending (max 5), send when user taps Send
            IconButton(
              onPressed: () => _pickAndAddImages(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded, color: _inputIconColor, size: 24),
              tooltip: 'Attach image',
            ),
            // Microphone – tap to start/stop, or hold to record and release to send (WhatsApp-style)
            GestureDetector(
              onLongPressStart: (_) => _startVoiceRecording(),
              onLongPressEnd: (_) => _toggleVoiceRecording(),
              child: IconButton(
                onPressed: _toggleVoiceRecording,
                icon: Icon(
                  _isRecordingVoice ? Icons.stop_circle_rounded : Icons.mic_rounded,
                  color: _isRecordingVoice ? Colors.redAccent : _inputIconColor,
                  size: 24,
                ),
                tooltip: _isRecordingVoice ? 'Stop recording' : 'Hold to record, release to send',
              ),
            ),
            const SizedBox(width: 8),
            // Text field with pending image thumbnails above and "Aa" hint; emoji inside
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isRecordingVoice) _buildVoiceRecordingBar(),
                    if ((_pendingAttachments ?? []).isNotEmpty) _buildPendingThumbnails(),
                    TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Aa',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Icon(Icons.text_fields_rounded, color: Colors.white.withValues(alpha: 0.7), size: 22),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 24),
                        suffixIcon: IconButton(
                          onPressed: _showEmojiPicker,
                          icon: Icon(Icons.emoji_emotions_outlined, color: Colors.white.withValues(alpha: 0.7), size: 22),
                          tooltip: 'Emoji',
                        ),
                        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Thumbs-up (quick reaction)
            IconButton(
              onPressed: () => _sendText('👍'),
              icon: const Icon(Icons.thumb_up_rounded, color: _inputIconColor, size: 24),
              tooltip: 'Like',
            ),
            const SizedBox(width: 4),
            // Send – orange rounded square, white icon, far right
            Material(
              color: BoostDriveTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _sendMessage,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an avatar for the other user in a conversation. Uses Image.network with
  /// errorBuilder so that when the profile image fails to load (e.g. when viewed by
  /// another user due to signed URLs), we fall back to initials.
  Widget _buildOtherUserAvatar(UserProfile? profile, {double radius = 20, bool darkBg = true}) {
    final name = profile?.fullName ?? '?';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final imageUrl = profile?.profileImg;
    final bgColor = darkBg ? BoostDriveTheme.primaryColor : Colors.white.withValues(alpha: 0.2);
    final textStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: radius * 0.5,
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(initial, style: textStyle),
      );
    }

    return ClipOval(
      child: Image.network(
        imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(initial, style: textStyle)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages')),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Scaffold(
        backgroundColor: BoostDriveTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: BoostDriveTheme.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _selectedConversationId == null ? 'Messages' : 'Chat',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: _selectedConversationId != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => setState(() => _selectedConversationId = null),
                )
              : null,
        ),
        body: _selectedConversationId == null
            ? _buildConversationList(user.id)
            : _buildChatView(user.id),
      );
    }

    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      body: Row(
        children: [
          // Conversations List
          SizedBox(
            width: 350,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Messages',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: _buildConversationList(user.id)),
                ],
              ),
            ),
          ),
          // Chat View
          Expanded(
            child: _selectedConversationId == null
                ? _buildEmptyState()
                : _buildChatView(user.id),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(String conversationId, String productTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Conversation', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(messageServiceProvider).deleteConversation(conversationId);
        
        // If the deleted conversation was selected, clear selection
        if (_selectedConversationId == conversationId) {
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
    return ref.watch(userConversationsProvider(userId)).when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return const Center(
            child: Text(
              'No conversations yet',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        // Sort conversations by created_at descending to show newest first
        final sortedConversations = List<Map<String, dynamic>>.from(conversations);
        sortedConversations.sort((a, b) {
          final aTime = a['created_at'] != null ? DateTime.parse(a['created_at']) : DateTime(2000);
          final bTime = b['created_at'] != null ? DateTime.parse(b['created_at']) : DateTime(2000);
          return bTime.compareTo(aTime);
        });

        return ListView.separated(
          itemCount: sortedConversations.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
          itemBuilder: (context, index) {
            final conv = sortedConversations[index];
            final isSelected = conv['id'] == _selectedConversationId;
            final otherUserId = conv['buyer_id'] == userId ? conv['seller_id'] : conv['buyer_id'];
            final productId = conv['product_id'] as String?;
            final productAsync = ref.watch(productByIdProvider(productId ?? ''));
            final product = productAsync.valueOrNull;
            final listingType = _listingTypeLabel(product?.category);
            final productTitle = product?.title ?? conv['product_title'] ?? (productId == null ? 'Service Request' : 'Product');
            final roleLabel = _otherPartyRoleLabel(userId, conv['buyer_id'] as String?, conv['seller_id'] as String?);
            
            // Unread indicator logic for the conversation list
            final unreadConvs = ref.watch(unreadConversationsProvider(userId)).value ?? {};
            final isUnread = unreadConvs.contains(conv['id']);

            return ListTile(
              selected: isSelected,
              selectedTileColor: BoostDriveTheme.primaryColor.withOpacity(0.1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ref.watch(userProfileProvider(otherUserId)).when(
                data: (profile) => Stack(
                  children: [
                    _buildOtherUserAvatar(profile, radius: 20, darkBg: true),
                    if (isUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: BoostDriveTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                loading: () => const CircleAvatar(backgroundColor: Colors.white10, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white24)),
              ),
              title: ref.watch(userProfileProvider(otherUserId)).when(
                data: (profile) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile?.fullName ?? 'User',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: isUnread ? FontWeight.w900 : FontWeight.w600, 
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: BoostDriveTheme.primaryColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listingType.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                loading: () => const Text('Loading...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                error: (_, __) => const Text('User', style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    roleLabel,
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    productTitle,
                    style: const TextStyle(color: BoostDriveTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conv['last_message'] ?? 'Start a conversation',
                    style: TextStyle(
                      color: isUnread ? Colors.white : Colors.white54, 
                      fontSize: 12,
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (conv['created_at'] != null)
                    Text(
                      _formatMessageDate(conv['created_at']),
                      style: TextStyle(
                        color: isUnread ? BoostDriveTheme.primaryColor : Colors.white24, 
                        fontSize: 10,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(conv['id'], productTitle),
                    child: Icon(
                      Icons.delete_outline,
                      color: isSelected ? BoostDriveTheme.primaryColor : Colors.red.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
                ],
              ),
              onTap: () {
                setState(() {
                  _selectedConversationId = conv['id'];
                });
                // Mark as read when selected
                ref.read(messageServiceProvider).markConversationAsRead(conv['id']);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildChatView(String userId) {
    return Column(
      children: [
        // Chat Header
        FutureBuilder<Map<String, dynamic>>(
          future: ref.read(messageServiceProvider).getConversation(_selectedConversationId!),
          builder: (context, convSnapshot) {
            if (!convSnapshot.hasData) return const SizedBox();
            final conversation = convSnapshot.data!;
            final otherUserId = conversation['buyer_id'] == userId ? conversation['seller_id'] : conversation['buyer_id'];
            final chatProductId = conversation['product_id'] as String?;
            final chatProductAsync = ref.watch(productByIdProvider(chatProductId ?? ''));
            final chatProduct = chatProductAsync.valueOrNull;
            final chatListingType = _listingTypeLabel(chatProduct?.category);
            final chatProductTitle = chatProduct?.title ?? conversation['product_title'] ?? (chatProductId == null ? 'Service Request' : 'Product');
            final chatRoleLabel = _otherPartyRoleLabel(userId, conversation['buyer_id'] as String?, conversation['seller_id'] as String?);
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: BoostDriveTheme.primaryColor,
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  ref.watch(userProfileProvider(otherUserId)).when(
                    data: (profile) => _buildOtherUserAvatar(profile, radius: 20, darkBg: false),
                    loading: () => const CircleAvatar(radius: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    error: (_, __) => const CircleAvatar(radius: 20, child: Icon(Icons.person, color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ref.watch(userProfileProvider(otherUserId)).when(
                              data: (profile) => Text(
                                profile?.fullName ?? 'User',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              loading: () => const Text('Loading...', style: TextStyle(color: Colors.white70)),
                              error: (_, __) => const Text('User', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                chatListingType.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          chatRoleLabel,
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          chatProductTitle,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // WhatsApp Bridge Logic
                      final phone = '264812345678'; // Placeholder
                      final url = 'https://wa.me/$phone';
                      // launchUrl(Uri.parse(url));
                    },
                    icon: const Icon(Icons.chat, color: Colors.white),
                    tooltip: 'WhatsApp Bridge',
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: ref.watch(conversationMessagesProvider(_selectedConversationId!)).when(
            data: (messages) {
              return FutureBuilder<Map<String, dynamic>>(
                future: ref.read(messageServiceProvider).getConversation(_selectedConversationId!),
                builder: (context, convSnapshot) {
                  if (!convSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final conversation = convSnapshot.data!;
                  final buyerId = conversation['buyer_id'] as String;
                  final sellerId = conversation['seller_id'] as String;
                  
                  final sortedMessages = messages.reversed.toList();
                  return _buildMessageList(sortedMessages, buyerId, sellerId, userId);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        _buildMessageInputBar(),
      ],
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages, String buyerId, String sellerId, String currentUserId) {
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final senderId = msg['sender_id'] as String;
        
        // Buyer messages (senderId == buyerId) -> RIGHT
        // Seller messages (senderId == sellerId) -> LEFT
        final isBuyerMessage = senderId == buyerId;
        final isMe = senderId == currentUserId;
        
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Date header logic
              if (index == messages.length - 1 || _shouldShowDateHeader(messages[index], messages[index + 1]))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatMessageDate(msg['created_at']),
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (MediaQuery.of(context).size.width < 900 ? 0.75 : 0.45)),
                decoration: BoxDecoration(
                  // My messages: Orange gradient
                  gradient: isMe ? const LinearGradient(
                    colors: [BoostDriveTheme.primaryColor, Colors.orangeAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ) : null,
                  // Other messages: White/Glassmorphism
                  color: isMe ? null : Colors.white,
                  boxShadow: isMe ? [
                    BoxShadow(
                      color: BoostDriveTheme.primaryColor.withOpacity(0.3), 
                      blurRadius: 8, 
                      offset: const Offset(0, 4)
                    )
                  ] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                  border: isMe ? null : Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label logic: only show label for the message that isn't from the viewer
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          isBuyerMessage ? 'Buyer' : 'Seller',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (_isImageUrl(msg['content'] as String? ?? ''))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          msg['content'] as String,
                          width: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : const SizedBox(width: 200, height: 150, child: Center(child: CircularProgressIndicator())),
                          errorBuilder: (_, __, ___) => Text(
                            msg['content'] as String,
                            style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
                          ),
                        ),
                      )
                    else if (_isAudioUrl(msg['content'] as String? ?? ''))
                      _VoiceMessagePlayer(
                        url: msg['content'] as String,
                        isMe: isMe,
                      )
                    else
                      Text(
                        msg['content'] as String,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Time and read receipts (WhatsApp-style ticks) for sender
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _formatMessageTime(msg['created_at']),
                          style: TextStyle(
                            color: isMe ? Colors.white.withOpacity(0.6) : Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildReadReceiptTicks(msg['is_read'] == true),
                        ],
                      ],
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

  /// WhatsApp-style read receipts: single grey tick = delivered but not seen, double orange tick = seen.
  Widget _buildReadReceiptTicks(bool isRead) {
    const double tickSize = 14;
    if (isRead) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_rounded, size: tickSize, color: BoostDriveTheme.primaryColor),
          Transform.translate(
            offset: const Offset(-4, 2),
            child: Icon(Icons.done_rounded, size: tickSize, color: BoostDriveTheme.primaryColor),
          ),
        ],
      );
    }
    return Icon(
      Icons.done_rounded,
      size: tickSize,
      color: Colors.grey.shade400,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Select a conversation to start messaging',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// In-app player for voice message URLs so the receiver can play without leaving the app.
class _VoiceMessagePlayer extends StatefulWidget {
  const _VoiceMessagePlayer({required this.url, required this.isMe});

  final String url;
  final bool isMe;

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
      if (mounted) setState(() {
        _playing = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
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
        setState(() => _playing = false);
        return;
      }
      setState(() { _loading = true; _error = null; });
      await _player.play(UrlSource(widget.url));
      if (mounted) setState(() { _playing = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _playing = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.white : Colors.black87;
    final secondary = color.withValues(alpha: 0.7);
    if (_error != null) {
      return Text(
        'Could not play',
        style: TextStyle(color: secondary, fontSize: 13),
      );
    }
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
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
                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
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

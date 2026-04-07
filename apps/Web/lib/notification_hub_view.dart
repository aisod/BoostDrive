import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';

class NotificationHubView extends ConsumerStatefulWidget {
  const NotificationHubView({super.key});

  @override
  ConsumerState<NotificationHubView> createState() => _NotificationHubViewState();
}

class _NotificationHubViewState extends ConsumerState<NotificationHubView> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildTabBar(),
          const SizedBox(height: 24),
          Expanded(
            child: TabBarView(
              children: [
                _buildNotificationsTab(),
                _buildPromotionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Notifications & Alerts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showNotificationDialog(context),
              icon: const Icon(Icons.add_alert, size: 18),
              label: const Text('NEW NOTIFICATION'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showPromotionDialog(context),
              icon: const Icon(Icons.campaign, size: 18),
              label: const Text(
                'NEW PROMOTION',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: BoostDriveTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      isScrollable: true,
      labelColor: BoostDriveTheme.primaryColor,
      unselectedLabelColor: Colors.black54,
      indicatorColor: BoostDriveTheme.primaryColor,
      indicatorWeight: 3,
      tabs: const [
        Tab(text: 'HISTORY'),
        Tab(text: 'PROMOTIONS'),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationHistory(),
        ],
      ),
    );
  }

  Widget _buildPromotionsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPromotionsHistory(),
        ],
      ),
    );
  }

  Widget _buildNotificationHistory() {
    return FutureBuilder<List<NotificationRecord>>(
      future: ref.read(notificationHubServiceProvider).getNotificationHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.black26),
                  SizedBox(height: 16),
                  Text(
                    'No notifications sent yet',
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.notifications, color: BoostDriveTheme.primaryColor),
                ),
                title: Text(
                  notif.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notif.message, style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text(
                      'Target: ${notif.targetGroup} • ${notif.createdAt.toString().split('.')[0]}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPromotionsHistory() {
    return FutureBuilder<List<NotificationPromotion>>(
      future: ref.read(notificationHubServiceProvider).getPromotionsHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Center(child: Padding(padding: EdgeInsets.all(48), child: Text('Error: ${snapshot.error}')));
        }

        final promotions = snapshot.data ?? [];

        if (promotions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.local_offer_outlined, size: 64, color: Colors.black26),
                  const SizedBox(height: 16),
                  Text(
                    'No promotions created yet',
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: promotions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final promo = promotions[index];
              final isExpired = promo.expiryDate.isBefore(DateTime.now());
              final isActive = promo.isActive && !isExpired;

              return ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: (isActive ? Colors.orange : Colors.grey).withValues(alpha: 0.1),
                  child: Icon(Icons.campaign, color: isActive ? Colors.orange : Colors.grey),
                ),
                title: Row(
                  children: [
                    Text(
                      promo.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'EXPIRED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(promo.description, style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text(
                      'Type: ${promo.type} • Discount: ${promo.discountPercentage}% • Expires: ${promo.expiryDate.toString().split('.')[0]}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                trailing: promo.targetCategory != null
                    ? Chip(
                        label: Text(promo.targetCategory!.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NotificationDialog(),
    ).then((_) => setState(() {}));
  }

  void _showPromotionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PromotionDialog(),
    ).then((_) => setState(() {}));
  }
}

class NotificationDialog extends ConsumerStatefulWidget {
  final String? initialGroup;
  const NotificationDialog({super.key, this.initialGroup});

  @override
  ConsumerState<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends ConsumerState<NotificationDialog> {
  int _currentStep = 1; // 1 to 5
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _actionLinkController = TextEditingController();
  String? _selectedGroup;
  final Set<String> _selectedMethods = {'in_app'};
  bool _isSending = false;
  int? _estimatedReach;
  String? _stepError;

  @override
  void initState() {
    super.initState();
    if (widget.initialGroup != null) {
      _selectedGroup = widget.initialGroup!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _actionLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1D2939),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildStepContent(),
            const SizedBox(height: 40),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.campaign, color: BoostDriveTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step $_currentStep of 5',
                style: const TextStyle(fontFamily: 'Manrope', fontSize: 10, fontWeight: FontWeight.w800, color: BoostDriveTheme.primaryColor, letterSpacing: 1),
              ),
              const Text(
                'Notification Hub',
                style: TextStyle(fontFamily: 'Manrope', fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Initiation();
      case 2:
        return _buildStep2Audience();
      case 3:
        return _buildStep3Compose();
      case 4:
        return _buildStep4Delivery();
      case 5:
        return _buildStep5Review();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1Initiation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('STEP 1 · INITIATION'),
        const SizedBox(height: 16),
        const Text(
          'Target your audience across Namibia. This tool allows you to send critical alerts, promotions, and system updates instantly.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildInfoCard(Icons.security, 'SOS Alerts & critical safety notifications should be clear and concise.'),
      ],
    );
  }

  Widget _buildStep2Audience() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('STEP 2 · AUDIENCE SELECTION'),
        const SizedBox(height: 16),
        _buildTargetGroupSelector(),
        if (_currentStep == 2 && _stepError != null) ...[
          const SizedBox(height: 12),
          _buildErrorMessage(),
        ],
      ],
    );
  }

  Widget _buildStep3Compose() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('STEP 3 · COMPOSE MESSAGE'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _titleController,
          label: 'SUBJECT LINE (max 50 chars)',
          hintText: 'e.g. System Update',
          maxLength: 50,
          onChanged: (_) => setState(() => _stepError = null),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _messageController,
          label: 'MESSAGE BODY',
          hintText: 'Keep it plain text for high deliverability...',
          maxLines: 4,
          maxLength: 1000,
          onChanged: (_) => setState(() => _stepError = null),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _actionLinkController,
          label: 'ACTION LINK (optional)',
          hintText: 'https://boostdrive.na/updates',
        ),
        if (_currentStep == 3 && _stepError != null) ...[
          const SizedBox(height: 12),
          _buildErrorMessage(),
        ],
      ],
    );
  }

  Widget _buildStep4Delivery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('STEP 4 · DELIVERY METHOD'),
        const SizedBox(height: 16),
        _buildDeliveryMethodPicker(),
        if (_currentStep == 4 && _stepError != null) ...[
          const SizedBox(height: 12),
          _buildErrorMessage(),
        ],
      ],
    );
  }

  Widget _buildStep5Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('STEP 5 · REVIEW & SEND'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _previewRow('Audience', (_selectedGroup ?? 'N/A').replaceAll('_', ' ').toUpperCase(), Icons.people_outline),
              const Divider(color: Colors.white10, height: 24),
              _previewRow('Subject', _titleController.text, Icons.title_outlined),
              const Divider(color: Colors.white10, height: 24),
              _previewRow('Channels', _selectedMethods.map((m) => m.toUpperCase()).join(' & '), Icons.send_outlined),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_stepError != null) _buildErrorMessage(),
        _buildReachCard(),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
          const SizedBox(width: 8),
          Text(
            _stepError!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isFirst = _currentStep == 1;
    final isLast = _currentStep == 5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isFirst)
          TextButton(
            onPressed: () => setState(() => _currentStep--),
            child: const Text('BACK', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          )
        else
          const SizedBox(),
        ElevatedButton(
          onPressed: _isSending ? null : () async {
            if (isLast) {
              await _sendNotification();
            } else {
              setState(() => _stepError = null);
              
              if (_currentStep == 2 && _selectedGroup == null) {
                setState(() => _stepError = 'Please select an audience before continuing');
                return;
              }
              if (_currentStep == 3 && (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty)) {
                setState(() => _stepError = 'Subject line and message body cannot be empty');
                return;
              }
              if (_currentStep == 4 && _selectedMethods.isEmpty) {
                setState(() => _stepError = 'Choose at least one delivery channel');
                return;
              }
              
              if (_currentStep == 3) {
                // Pre-calculate reach before review step
                _estimatedReach = await ref.read(notificationHubServiceProvider).getEstimatedReach(_selectedGroup!);
              }
              setState(() => _currentStep++);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isLast ? Colors.green : BoostDriveTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSending
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(isLast ? 'SEND NOTIFICATION' : 'CONTINUE', style: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildReachCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text(
            'Estimated Reach: ${_estimatedReach ?? '...'} users',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildDeliveryMethodPicker() {
    final methods = [
      ('in_app', Icons.notifications_none, 'In-App Notification', 'Push alert on their phone'),
      ('dashboard', Icons.web_rounded, 'Dashboard Alert', 'Persistent top banner'),
    ];
    return Column(
      children: methods.map((m) {
        final (val, icon, label, desc) = m;
        final isSelected = _selectedMethods.contains(val);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              if (_selectedMethods.length > 1) _selectedMethods.remove(val);
            } else {
              _selectedMethods.add(val);
            }
            _stepError = null;
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? BoostDriveTheme.primaryColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? BoostDriveTheme.primaryColor : Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? BoostDriveTheme.primaryColor : Colors.white38),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                if (isSelected) const Icon(Icons.check_circle, color: BoostDriveTheme.primaryColor, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFFFF8C42),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTargetGroupSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildGroupButton('All Users', 'all'),
          _buildGroupButton('Providers', 'providers'),
          _buildGroupButton('Customers', 'customers'),
        ],
      ),
    );
  }

  Widget _buildGroupButton(String label, String value) {
    final isSelected = _selectedGroup == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedGroup = value;
          _stepError = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF34495E) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      ],
    );
  }

  String _getRecipientCount() {
    switch (_selectedGroup) {
      case 'all_users':
        return '📊 Est. 7 recipients';
      case 'service_providers':
        return '📊 Est. 3 recipients';
      case 'customers':
        return '📊 Est. 4 recipients';
      default:
        return '📊 Est. 0 recipients';
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title and message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final admin = ref.read(currentUserProvider);
      if (admin == null) throw Exception('Admin not authenticated');

      await ref.read(notificationHubServiceProvider).sendNotification(
        adminId: admin.id,
        targetGroup: _selectedGroup!,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        deliveryMethods: _selectedMethods.toList(),
        actionLink: _actionLinkController.text.trim().isEmpty ? null : _actionLinkController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class PromotionDialog extends ConsumerStatefulWidget {
  const PromotionDialog({super.key});

  @override
  ConsumerState<PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends ConsumerState<PromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _discountController = TextEditingController();
  
  String? _selectedType;
  String? _targetCategory;
  DateTime? _expiryDate;
  bool _isSaving = false;
  int _estimatedReach = 0;

  final List<String> _promoTypes = ['Seasonal', 'Flash Sale', 'New User', 'Service Specific'];
  final List<String> _categories = ['towing', 'mechanic', 'rental', 'logistics'];

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: BoostDriveTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _updateReach() async {
    final reach = await ref.read(notificationHubServiceProvider).getEstimatedReach(_targetCategory ?? 'all');
    setState(() {
      _estimatedReach = reach;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                
                // Promotion Type
                _buildLabel('PROMOTION TYPE'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: Colors.white,
                  decoration: _inputDecoration('Select type...'),
                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                  items: _promoTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.black87)))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Category (if service specific or for targeting)
                _buildLabel('TARGET CATEGORY'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _targetCategory,
                  dropdownColor: Colors.white,
                  decoration: _inputDecoration('All Categories (Global)'),
                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase(), style: const TextStyle(color: Colors.black87)))).toList(),
                  onChanged: (v) {
                    setState(() => _targetCategory = v);
                    _updateReach();
                  },
                ),
                const SizedBox(height: 16),

                // Title
                _buildLabel('CAMPAIGN TITLE'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _inputDecoration('e.g. Easter Towing Special'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Details
                _buildLabel('PROMOTION DETAILS'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _detailsController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _inputDecoration('Describe the deal...'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    // Discount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('DISCOUNT %'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                            decoration: _inputDecoration('0').copyWith(
                              suffixIcon: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black26)),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = double.tryParse(v);
                              if (n == null || n < 0 || n > 100) return 'Invalid';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Expiry
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('EXPIRY DATE'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                                  const SizedBox(width: 12),
                                  Text(
                                    _expiryDate == null ? 'Set Date' : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                                    style: TextStyle(color: _expiryDate == null ? Colors.black26 : Colors.black87, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                if (_estimatedReach > 0)
                  _buildReachIndicator(),

                const SizedBox(height: 40),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReachIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Est. Reach: $_estimatedReach targeted users',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.campaign, color: BoostDriveTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Create New Promotion',
            style: TextStyle(fontFamily: 'Manrope', fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.black26),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'Manrope', fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black45, letterSpacing: 0.5),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Colors.black45),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
            side: const BorderSide(color: Colors.black12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSaving ? null : _savePromotion,
          style: ElevatedButton.styleFrom(
            backgroundColor: BoostDriveTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('CREATE PROMOTION', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Future<void> _savePromotion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set an expiry date')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final admin = ref.read(currentUserProvider);
      if (admin == null) throw Exception('Admin not authenticated');

      await ref.read(notificationHubServiceProvider).createPromotion(
            adminId: admin.id,
            type: _selectedType!,
            title: _titleController.text.trim(),
            description: _detailsController.text.trim(),
            discountPercentage: double.parse(_discountController.text),
            targetCategory: _targetCategory,
            expiryDate: _expiryDate!,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promotion launched successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to launch promotion: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

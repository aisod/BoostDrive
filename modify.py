import re

with open('apps/Web/lib/user_management_view.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Rename ALL broadcast occurrences to notification
replacements = {
    'broadcastGroup': 'notificationGroup',
    '_showBroadcastModal': '_showNotificationModal',
    'broadcastServiceProvider': 'notificationHubServiceProvider',
    'sendBroadcast': 'sendNotification',
    '_buildBroadcastPreview': '_buildNotificationPreview',
    '_broadcastSectionLabel': '_notificationSectionLabel',
    '_broadcastInputDecoration': '_notificationInputDecoration',
    "'BROADCAST'": "'NOTIFICATION'",
    '// ─── BROADCAST HUB ───────────────────────────────────────────────────────': '// ─── NOTIFICATION HUB ───────────────────────────────────────────────────────',
    'Send Broadcast to All': 'Send Notification to All',
    'Broadcast Hub': 'Notification Hub'
}
for k, v in replacements.items():
    text = text.replace(k, v)

# 2. Modify "Delivery Channels" block
# We want to remove the sections.
delivery_channel_section = """                                // ── Step 3: Delivery ──
                                _notificationSectionLabel('STEP 3 · DELIVERY CHANNELS'),
                                const SizedBox(height: 10),
                                _buildDeliveryMethodPicker(
                                  selected: deliveryMethods,
                                  onToggle: (method) => setModalState(() {
                                    if (deliveryMethods.contains(method)) {
                                      if (deliveryMethods.length > 1) deliveryMethods.remove(method);
                                    } else {
                                      deliveryMethods.add(method);
                                    }
                                  }),
                                ),
                                const SizedBox(height: 8),"""

if delivery_channel_section in text:
    text = text.replace(delivery_channel_section, "")
else:
    print("Could not find Step 3 delivery channels")

preview_channels = """              const Divider(color: Colors.white10, height: 24),
              _previewRow('Channels', deliveryMethods.join(', '), Icons.send_outlined),"""
              
if preview_channels in text:
    text = text.replace(preview_channels, "")
else:
    print("Could not find preview channels")

with open('apps/Web/lib/user_management_view.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Done")

import re

with open('apps/Web/lib/user_management_view.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 2. Modify "Delivery Channels" block using regex
# Match everything from `// ── Step 3: Delivery ──` down to right before `],`
pattern1 = r"(\s*// ── Step 3: Delivery ──\s*_notificationSectionLabel\('STEP 3 · DELIVERY CHANNELS'\);\s*const SizedBox\(height: 10\);\s*_buildDeliveryMethodPicker.*?\s*const SizedBox\(height: 8\);)"
text = re.sub(pattern1, "", text, flags=re.DOTALL)

# Also remove the Channels from preview
pattern2 = r"(\s*const Divider\(color: Colors\.white10, height: 24\);\s*_previewRow\('Channels', deliveryMethods\.join\(', '\), Icons\.send_outlined\);)"
text = re.sub(pattern2, "", text, flags=re.DOTALL)

# And another pass for SEND BROADCAST -> SEND NOTIFICATION, BROADCAST -> NOTIFICATION
replacements = {
    'actionType: \'BROADCAST_SENT\'': 'actionType: \'NOTIFICATION_SENT\'',
    '\'BROADCAST\'': '\'NOTIFICATION\'',
    'Broadcast sent': 'Notification sent',
    'SEND BROADCAST': 'SEND NOTIFICATION',
    'This broadcast will reach': 'This notification will reach'
}
for k, v in replacements.items():
    text = text.replace(k, v)

with open('apps/Web/lib/user_management_view.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Done with Regex!")

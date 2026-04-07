import os
import glob

history_dir = os.path.expandvars(r'%APPDATA%\Code\User\History')
print(f"Searching in {history_dir}")

matches = []

for root, _, files in os.walk(history_dir):
    for f in files:
        if f == 'entries.json':
            continue
        try:
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
                # We need to find the latest file that has the exact string from before my botched replace
                if "void _showNotificationModal({String preselectedGroup = 'all'})" in content:
                    mtime = os.path.getmtime(path)
                    matches.append((mtime, path))
        except:
            pass

matches.sort(reverse=True)
if matches:
    print(f"Found {len(matches)} matches. Latest is {matches[0][1]}")
    import shutil
    shutil.copy2(matches[0][1], 'apps/Web/lib/user_management_view.dart')
    print("Successfully restored!")
else:
    print("No matches found.")

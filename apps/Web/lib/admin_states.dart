import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AdminUserGroup { provider, customerSeller, admin }

final adminUserGroupProvider = StateProvider<AdminUserGroup?>((ref) => null);

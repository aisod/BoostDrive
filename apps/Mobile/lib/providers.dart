import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';

final activeRoleProvider = StateProvider<String>((ref) => 'customer');

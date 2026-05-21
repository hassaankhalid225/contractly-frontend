import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';

/// Returns the path to redirect to, or null when the current target is fine.
String? authGuard(WidgetRef ref, GoRouterState state) {
  final auth = ref.read(authProvider);
  if (auth.isInitializing) return null;

  final loc = state.matchedLocation;
  final isLoggedIn = auth.isAuthenticated;
  final isPublic = loc == '/splash' ||
      loc.startsWith('/auth') ||
      loc.startsWith('/onboarding');

  // First-launch onboarding gate.
  final onboardingSeen =
      StorageService.readPref<bool>(AppConstants.prefOnboardingSeen) ?? false;

  if (!isLoggedIn) {
    if (loc == '/splash') return null;
    if (!isPublic) {
      return onboardingSeen ? '/auth' : '/onboarding';
    }
    if (loc == '/onboarding' && onboardingSeen) return '/auth';
    return null;
  }

  // Logged in but landed on auth routes -> push them home.
  if (loc.startsWith('/auth') ||
      loc == '/onboarding' ||
      loc == '/splash') {
    return '/home';
  }
  return null;
}

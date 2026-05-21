import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/screens/auth/auth_screen.dart';
import '../../ui/screens/auth/otp_screen.dart';
import '../../ui/screens/auth/phone_input_screen.dart';
import '../../ui/screens/contracts/ai_analysis_screen.dart';
import '../../ui/screens/contracts/contract_detail_screen.dart';
import '../../ui/screens/contracts/contracts_list_screen.dart';
import '../../ui/screens/contracts/create_contract_screen.dart';
import '../../ui/screens/contracts/upload_contract_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/main_shell.dart';
import '../../ui/screens/notifications/notifications_screen.dart';
import '../../ui/screens/onboarding/onboarding_screen.dart';
import '../../ui/screens/payments/payments_screen.dart';
import '../../ui/screens/profile/profile_screen.dart';
import '../../ui/screens/sign/signature_screen.dart';
import '../../ui/screens/splash/splash_screen.dart';
import '../providers/auth_provider.dart';
import 'route_guards.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static GoRouter create(WidgetRef ref) {
    return GoRouter(
      navigatorKey: _rootNavKey,
      initialLocation: '/splash',
      debugLogDiagnostics: false,
      refreshListenable: _AuthRefreshListenable(ref),
      redirect: (context, state) => authGuard(ref, state),
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          pageBuilder: (_, __) => _fadeIn(const SplashScreen()),
        ),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          pageBuilder: (_, __) => _fadeIn(const OnboardingScreen()),
        ),
        GoRoute(
          path: '/auth',
          name: 'auth',
          pageBuilder: (_, __) => _fadeIn(const AuthScreen()),
          routes: [
            GoRoute(
              path: 'phone',
              name: 'phone',
              pageBuilder: (_, __) =>
                  _slideUp(const PhoneInputScreen()),
            ),
            GoRoute(
              path: 'otp',
              name: 'otp',
              pageBuilder: (_, state) {
                final phone = state.uri.queryParameters['phone'] ?? '';
                return _slideUp(OtpScreen(phone: phone));
              },
            ),
          ],
        ),
        ShellRoute(
          navigatorKey: _shellNavKey,
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              pageBuilder: (_, __) => _fadeIn(const HomeScreen()),
            ),
            GoRoute(
              path: '/contracts',
              name: 'contracts',
              pageBuilder: (_, __) => _fadeIn(const ContractsListScreen()),
              routes: [
                GoRoute(
                  path: 'create',
                  name: 'contracts.create',
                  parentNavigatorKey: _rootNavKey,
                  pageBuilder: (_, __) =>
                      _slideUp(const CreateContractScreen()),
                ),
                GoRoute(
                  path: 'upload',
                  name: 'contracts.upload',
                  parentNavigatorKey: _rootNavKey,
                  pageBuilder: (_, __) =>
                      _slideUp(const UploadContractScreen()),
                ),
                GoRoute(
                  path: ':id',
                  name: 'contracts.detail',
                  parentNavigatorKey: _rootNavKey,
                  pageBuilder: (_, state) =>
                      _slideUp(ContractDetailScreen(contractId: state.pathParameters['id']!)),
                  routes: [
                    GoRoute(
                      path: 'sign',
                      name: 'contracts.sign',
                      parentNavigatorKey: _rootNavKey,
                      pageBuilder: (_, state) => _slideUp(
                        SignatureScreen(contractId: state.pathParameters['id']!),
                      ),
                    ),
                    GoRoute(
                      path: 'analysis',
                      name: 'contracts.analysis',
                      parentNavigatorKey: _rootNavKey,
                      pageBuilder: (_, state) {
                        final extra = state.extra;
                        return _slideUp(AiAnalysisScreen(
                          contractId: state.pathParameters['id']!,
                          existingAnalysisJson:
                              extra is Map<String, dynamic> ? extra : null,
                        ));
                      },
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/payments',
              name: 'payments',
              pageBuilder: (_, __) => _fadeIn(const PaymentsScreen()),
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              pageBuilder: (_, __) => _fadeIn(const ProfileScreen()),
            ),
            GoRoute(
              path: '/notifications',
              name: 'notifications',
              pageBuilder: (_, __) => _slideUp(const NotificationsScreen()),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Page not found:\n${state.matchedLocation}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  static CustomTransitionPage<T> _fadeIn<T>(Widget child) {
    return CustomTransitionPage<T>(
      child: child,
      transitionsBuilder: (_, animation, __, c) =>
          FadeTransition(opacity: animation, child: c),
      transitionDuration: const Duration(milliseconds: 220),
    );
  }

  static CustomTransitionPage<T> _slideUp<T>(Widget child) {
    return CustomTransitionPage<T>(
      child: child,
      transitionsBuilder: (_, animation, __, c) {
        final tween = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: c,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }
}

/// Bridges Riverpod [authProvider] state changes into [GoRouter.refresh].
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._ref) {
    _sub = _ref.listenManual<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final WidgetRef _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

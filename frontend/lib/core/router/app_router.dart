import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/teams/screens/teams_screen.dart';
import '../../features/teams/screens/team_detail_screen.dart';
import '../../features/teams/screens/team_owner_dashboard.dart';
import '../../features/clans/screens/clans_screen.dart';
import '../../features/clans/screens/clan_chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/feed/screens/create_opportunity_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (auth.status == AuthStatus.unknown) return '/splash';
      if (auth.status == AuthStatus.unauthenticated) {
        if (location == '/login' || location == '/register' || location == '/splash') return null;
        return '/login';
      }
      if (auth.status == AuthStatus.onboarding) {
        if (location == '/onboarding') return null;
        return '/onboarding';
      }
      if (auth.status == AuthStatus.authenticated) {
        if (location == '/splash' || location == '/login' || location == '/register' || location == '/onboarding') {
          return '/feed';
        }
      }
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // Full-screen routes — rendered at root level, no bottom nav
      GoRoute(
        path: '/teams/:id',
        builder: (_, state) => TeamDetailScreen(teamId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clans/:id',
        builder: (_, state) => ClanChatScreen(clanId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/create-opportunity',
        builder: (_, __) => const CreateOpportunityScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/my-teams',
        builder: (_, __) => const TeamOwnerDashboard(),
      ),

      // Shell routes — wrapped with bottom nav bar
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
          GoRoute(path: '/teams', builder: (_, __) => const TeamsScreen()),
          GoRoute(path: '/clans', builder: (_, __) => const ClansScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});

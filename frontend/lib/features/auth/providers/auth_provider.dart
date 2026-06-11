import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/auth_repository.dart';
import '../../../shared/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, onboarding }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class OnboardingData {
  String? degreeProgram;
  List<String> skills;
  List<String> interests;
  OnboardingData({this.degreeProgram, this.skills = const [], this.interests = const []});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  final AuthRepository _repo;
  final OnboardingData onboardingData = OnboardingData();

  Future<void> _init() async {
    try {
      final userId = await _repo.getCurrentUserId();
      if (userId == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final hasOnboarded = await _repo.hasCompletedOnboarding();
      if (!hasOnboarded) {
        final user = await _repo.loadCurrentUser();
        state = AuthState(status: AuthStatus.onboarding, user: user);
        return;
      }
      final user = await _repo.loadCurrentUser();
      if (user == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      } else {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      }
    } catch (_) {
      // If anything fails during init (DB not ready, prefs unavailable, etc.)
      // fall back to unauthenticated so the app is never stuck on a blank screen.
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.signIn(email: email, password: password);
      final hasOnboarded = await _repo.hasCompletedOnboarding();
      state = AuthState(
        status: hasOnboarded ? AuthStatus.authenticated : AuthStatus.onboarding,
        user: user,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.register(name: name, email: email, password: password);
      state = AuthState(status: AuthStatus.onboarding, user: user);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> completeOnboarding() async {
    final user = state.user;
    if (user == null) return;
    await _repo.completeOnboarding(
      userId: user.id,
      degreeProgram: onboardingData.degreeProgram ?? '',
      skills: onboardingData.skills,
      interests: onboardingData.interests,
    );
    final updated = await _repo.loadCurrentUser();
    state = AuthState(status: AuthStatus.authenticated, user: updated ?? user);
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    // Local-only app — no email sending capability
    state = state.copyWith(isLoading: false,
        error: 'Password reset is not available in offline mode. '
            'Please contact support.');
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);

final currentUserProvider = Provider<UserModel?>((ref) => ref.watch(authProvider).user);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/mock_data.dart';

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

  AuthState copyWith({AuthStatus? status, UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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
  AuthNotifier() : super(const AuthState()) {
    _checkAuth();
  }

  final OnboardingData onboardingData = OnboardingData();

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;

    if (isLoggedIn && hasOnboarded) {
      state = state.copyWith(status: AuthStatus.authenticated, user: MockData.currentUser);
    } else if (isLoggedIn) {
      state = state.copyWith(status: AuthStatus.onboarding, user: MockData.currentUser);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setBool('has_onboarded', true);
    state = state.copyWith(status: AuthStatus.authenticated, user: MockData.currentUser, isLoading: false);
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    state = state.copyWith(status: AuthStatus.onboarding, user: MockData.currentUser, isLoading: false);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_onboarded', true);
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

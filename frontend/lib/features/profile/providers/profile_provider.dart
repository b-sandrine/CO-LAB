import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/profile_repository.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => ProfileRepository());

// Live stream of the current user's profile
final profileStreamProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(profileRepositoryProvider).watchUser(user.id);
});

// User's RSVPs (dates stored as int milliseconds)
final userRsvpsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value([]);
  return ref.read(profileRepositoryProvider).getUserRsvps(user.id);
});

class ProfileEditNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileEditNotifier(this._repo, this._ref) : super(const AsyncData(null));
  final ProfileRepository _repo;
  final Ref _ref;

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? degreeProgram,
    List<String>? skills,
    List<String>? interests,
  }) async {
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    try {
      await _repo.updateProfile(
        userId: userId,
        name: name,
        bio: bio,
        degreeProgram: degreeProgram,
        skills: skills,
        interests: interests,
      );
      final updated = await _ref.read(authRepositoryProvider).loadCurrentUser();
      if (updated != null) {
        _ref.read(authProvider.notifier).state =
            _ref.read(authProvider).copyWith(user: updated);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> uploadPhoto(File file) async {
    final userId = _ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    try {
      await _repo.uploadProfilePhoto(userId, file);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final profileEditProvider =
    StateNotifierProvider<ProfileEditNotifier, AsyncValue<void>>(
  (ref) => ProfileEditNotifier(
    ref.read(profileRepositoryProvider),
    ref,
  ),
);

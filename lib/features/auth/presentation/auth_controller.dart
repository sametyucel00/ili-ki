import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/shared/models/app_user.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    return ref.read(authRepositoryProvider).bootstrapSession();
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).getCurrentProfile());
  }

  Future<void> completeOnboarding() async {
    await ref.read(authRepositoryProvider).markOnboardingCompleted();
    await refreshProfile();
  }

  Future<void> linkGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).linkWithGoogle();
      return ref.read(authRepositoryProvider).getCurrentProfile();
    });
  }

  Future<void> linkApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).linkWithApple();
      return ref.read(authRepositoryProvider).getCurrentProfile();
    });
  }

  Future<void> linkEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).linkWithEmail(email, password);
      return ref.read(authRepositoryProvider).getCurrentProfile();
    });
  }

  Future<void> deleteData() async {
    await ref.read(authRepositoryProvider).deleteAllData();
    await refreshProfile();
  }

  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).bootstrapSession());
  }

  Future<void> updateDisplayName(String displayName) async {
    await ref.read(authRepositoryProvider).updateDisplayName(displayName);
    await refreshProfile();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final loginProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return false;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result =
        await ref.read(loginProvider)(email: email, password: password);
    if (result.failure != null) {
      state = AsyncError(result.failure!, StackTrace.current);
    } else {
      state = const AsyncData(true);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(false);
  }
}
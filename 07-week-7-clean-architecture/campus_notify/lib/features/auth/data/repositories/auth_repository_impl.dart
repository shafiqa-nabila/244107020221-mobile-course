import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!email.contains('@') || password.length < 6) {
        return (
          session: null,
          failure: const LocalFailure('Email atau kata sandi tidak valid'),
        );
      }
      const access = 'mock-access';
      const refresh = 'mock-refresh';
      await _storage.write(key: _accessKey, value: access);
      await _storage.write(key: _refreshKey, value: refresh);
      return (
        session: const AuthSession(access: access, refresh: refresh),
        failure: null,
      );
    } catch (e) {
      return (session: null, failure: LocalFailure('Login gagal: $e'));
    }
  }

  @override
  Future<({String? token, Failure? failure})> refresh(String refreshToken) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (refreshToken.isEmpty) {
        return (token: null, failure: const LocalFailure('Refresh token hilang'));
      }
      final renewed = 'mock-access-${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(key: _accessKey, value: renewed);
      return (token: renewed, failure: null);
    } catch (e) {
      return (token: null, failure: LocalFailure('Refresh gagal: $e'));
    }
  }

  @override
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
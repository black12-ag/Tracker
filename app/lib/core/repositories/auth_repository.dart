import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/config/app_identity.dart';
import 'package:liquid_soap_tracker/core/offline/services/local_store_service.dart';
import 'package:liquid_soap_tracker/core/offline/services/offline_error_detector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client, this._localStoreService);

  final SupabaseClient _client;
  final LocalStoreService _localStoreService;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AppProfile?> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) {
        return null;
      }

      final profile = AppProfile.fromMap(row);
      await _localStoreService.writeMap(
        LocalStoreService.profileKey,
        profile.toMap(),
      );
      return profile;
    } catch (error) {
      if (!OfflineErrorDetector.isLikelyOffline(error)) {
        rethrow;
      }

      final cached = await _localStoreService.readMap(
        LocalStoreService.profileKey,
      );
      return cached == null ? null : AppProfile.fromMap(cached);
    }
  }

  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: AppIdentity.normalizeLoginIdentifier(identifier),
      password: password,
    );
  }

  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await _localStoreService.clearAllCachedData();
  }

  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }
}

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../tv_discovery/domain/tv_device.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('SharedPreferences must be overridden at app startup.');
});

final savedTvsRepositoryProvider = Provider<SavedTvsRepository>((ref) {
  return SavedTvsRepository(ref.watch(sharedPreferencesProvider));
});

final savedTvsProvider = FutureProvider<List<TvDevice>>((ref) {
  return ref.watch(savedTvsRepositoryProvider).loadSavedTvs();
});

class SavedTvsRepository {
  SavedTvsRepository(this._preferences);

  final SharedPreferences _preferences;

  Future<List<TvDevice>> loadSavedTvs() async {
    final encodedDevices =
        _preferences.getStringList(AppConstants.savedTvsKey) ?? const [];
    return encodedDevices
        .map(
          (entry) =>
              TvDevice.fromMap(jsonDecode(entry) as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<void> saveTv(TvDevice device) async {
    final current = await loadSavedTvs();
    final withoutDuplicate = current.where((tv) => tv.id != device.id).toList();
    final updated = [device, ...withoutDuplicate];
    await _preferences.setStringList(
      AppConstants.savedTvsKey,
      updated.map((tv) => jsonEncode(tv.toMap())).toList(growable: false),
    );
  }

  Future<void> removeTv(String deviceId) async {
    final updated = (await loadSavedTvs())
        .where((tv) => tv.id != deviceId)
        .map((tv) => jsonEncode(tv.toMap()))
        .toList(growable: false);
    await _preferences.setStringList(AppConstants.savedTvsKey, updated);
  }

  Future<void> clearSavedTvs() async {
    await _preferences.remove(AppConstants.savedTvsKey);
  }
}

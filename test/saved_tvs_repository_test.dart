import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/saved_tvs/data/saved_tvs_repository.dart';
import 'package:justremote/features/tv_discovery/domain/tv_device.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves, loads, and removes paired TVs', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = SavedTvsRepository(preferences);
    const device = TvDevice(
      id: 'tv_1',
      name: 'Living Room TV',
      host: '192.168.1.20',
      port: 6466,
      type: 'android_tv',
    );

    await repository.saveTv(device);

    expect(await repository.loadSavedTvs(), [device]);

    await repository.removeTv(device.id);

    expect(await repository.loadSavedTvs(), isEmpty);
  });

  test('clearSavedTvs removes every saved TV', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = SavedTvsRepository(preferences);

    await repository.saveTv(
      const TvDevice(
        id: 'tv_1',
        name: 'Living Room TV',
        host: '192.168.1.20',
        port: 6466,
        type: 'android_tv',
      ),
    );
    await repository.clearSavedTvs();

    expect(await repository.loadSavedTvs(), isEmpty);
  });
}

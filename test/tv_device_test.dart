import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/tv_discovery/domain/tv_device.dart';

void main() {
  test('fromMap treats older saved TVs as unpaired', () {
    final device = TvDevice.fromMap(const {
      'id': 'tv_1',
      'name': 'Living Room TV',
      'host': '192.168.1.20',
      'port': 6466,
      'type': 'android_tv',
    });

    expect(device.paired, isFalse);
  });

  test('toMap persists pairing status', () {
    const device = TvDevice(
      id: 'tv_1',
      name: 'Living Room TV',
      host: '192.168.1.20',
      port: 6466,
      type: 'android_tv',
      paired: true,
    );

    expect(device.toMap()['paired'], isTrue);
  });
}

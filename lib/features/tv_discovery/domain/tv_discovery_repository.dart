import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tv_discovery_channel.dart';
import 'tv_device.dart';

final tvDiscoveryChannelProvider = Provider<TvDiscoveryChannel>((ref) {
  return TvDiscoveryChannel();
});

final tvDiscoveryRepositoryProvider = Provider<TvDiscoveryRepository>((ref) {
  return TvDiscoveryRepository(ref.watch(tvDiscoveryChannelProvider));
});

class TvDiscoveryRepository {
  TvDiscoveryRepository(this._channel);

  final TvDiscoveryChannel _channel;

  Future<List<TvDevice>> scanForTvs() => _channel.scanForTvs();
}

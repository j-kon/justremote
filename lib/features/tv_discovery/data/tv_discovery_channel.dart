import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/tv_device.dart';

class TvDiscoveryChannel {
  TvDiscoveryChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppConstants.methodChannelName);

  final MethodChannel _channel;

  Future<List<TvDevice>> scanForTvs() async {
    try {
      final response = await _channel.invokeMethod<List<dynamic>>('scanForTvs');
      return (response ?? const <dynamic>[])
          .cast<Map<dynamic, dynamic>>()
          .map(TvDevice.fromMap)
          .toList(growable: false);
    } on PlatformException catch (error) {
      throw AppException('Unable to scan for TVs.', cause: error);
    }
  }
}

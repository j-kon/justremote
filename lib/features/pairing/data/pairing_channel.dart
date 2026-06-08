import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../tv_discovery/domain/tv_device.dart';

class PairingChannel {
  PairingChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppConstants.methodChannelName);

  final MethodChannel _channel;

  Future<String> startPairing(TvDevice device) async {
    try {
      final response = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('pairTv', {
            'deviceId': device.id,
            'host': device.host,
            'port': device.port,
            'pairingCode': '',
            'name': device.name,
            'type': device.type,
          });
      final success = response?['success'] == true;
      if (!success) {
        throw AppException(
          response?['message'] as String? ?? 'Could not start pairing.',
        );
      }
      return response?['message'] as String? ??
          'Pairing started. Enter the code shown on your TV.';
    } on PlatformException catch (error) {
      throw AppException('Unable to start pairing.', cause: error);
    }
  }

  Future<String> pairTv({
    required TvDevice device,
    required String pairingCode,
  }) async {
    try {
      final response = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('pairTv', {
            'deviceId': device.id,
            'host': device.host,
            'port': device.port,
            'pairingCode': pairingCode,
            'name': device.name,
            'type': device.type,
          });
      final success = response?['success'] == true;
      if (!success) {
        throw AppException(
          response?['message'] as String? ?? 'Pairing failed.',
        );
      }
      return response?['message'] as String? ?? 'Paired successfully';
    } on PlatformException catch (error) {
      throw AppException('Unable to pair TV.', cause: error);
    }
  }
}

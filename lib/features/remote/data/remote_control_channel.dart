import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../tv_discovery/domain/tv_device.dart';
import '../domain/remote_command.dart';

class RemoteControlChannel {
  RemoteControlChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppConstants.methodChannelName);

  final MethodChannel _channel;

  Future<bool> connectToTv(TvDevice device) async {
    try {
      final response = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('connectToTv', {
            'deviceId': device.id,
            'host': device.host,
            'port': device.port,
            'name': device.name,
            'type': device.type,
          });
      return response?['success'] == true;
    } on PlatformException catch (error) {
      throw AppException('Unable to connect to TV.', cause: error);
    }
  }

  Future<bool> disconnectTv() async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'disconnectTv',
      );
      return response?['success'] == true;
    } on PlatformException catch (error) {
      throw AppException('Unable to disconnect TV.', cause: error);
    }
  }

  Future<bool> sendCommand(RemoteCommand command) async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'sendCommand',
        {'command': command.wireName},
      );
      return response?['success'] == true;
    } on PlatformException catch (error) {
      throw AppException('Unable to send command.', cause: error);
    }
  }

  Future<bool> sendText(String text) async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'sendText',
        {'text': text},
      );
      return response?['success'] == true;
    } on PlatformException catch (error) {
      throw AppException('Unable to send text.', cause: error);
    }
  }

  Future<bool> launchApp(String appLink) async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'launchApp',
        {'appLink': appLink},
      );
      return response?['success'] == true;
    } on PlatformException catch (error) {
      throw AppException('Unable to launch app.', cause: error);
    }
  }

  Future<bool> forgetTv(TvDevice device) async {
    try {
      final response = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('forgetTv', {
            'deviceId': device.id,
            'host': device.host,
            'port': device.port,
            'name': device.name,
            'type': device.type,
          });
      return response?['success'] == true;
    } on PlatformException catch (error) {
      throw AppException('Unable to forget TV.', cause: error);
    }
  }

  Future<bool> resetPairingData() async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'resetPairingData',
      );
      return response?['success'] == true;
    } on PlatformException catch (error) {
      throw AppException('Unable to reset pairing data.', cause: error);
    }
  }

  Future<Map<String, Object?>> getConnectionStatus() async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getConnectionStatus',
      );
      return Map<String, Object?>.from(response ?? const {});
    } on PlatformException catch (error) {
      throw AppException('Unable to read connection status.', cause: error);
    }
  }

  Future<Map<String, Object?>> getDiagnostics() async {
    try {
      final response = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDiagnostics',
      );
      return Map<String, Object?>.from(response ?? const {});
    } on PlatformException catch (error) {
      throw AppException('Unable to read diagnostics.', cause: error);
    }
  }
}

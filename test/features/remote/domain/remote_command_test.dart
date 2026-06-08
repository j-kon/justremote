import 'package:flutter_test/flutter_test.dart';
import 'package:justremote/features/remote/domain/remote_command.dart';

void main() {
  group('RemoteCommand media commands', () {
    test('mediaPlayPause wire name is mediaPlayPause', () {
      expect(RemoteCommand.mediaPlayPause.wireName, 'mediaPlayPause');
    });
    test('mediaStop wire name is mediaStop', () {
      expect(RemoteCommand.mediaStop.wireName, 'mediaStop');
    });
    test('mediaNext wire name is mediaNext', () {
      expect(RemoteCommand.mediaNext.wireName, 'mediaNext');
    });
    test('mediaPrevious wire name is mediaPrevious', () {
      expect(RemoteCommand.mediaPrevious.wireName, 'mediaPrevious');
    });
    test('mediaRewind wire name is mediaRewind', () {
      expect(RemoteCommand.mediaRewind.wireName, 'mediaRewind');
    });
    test('mediaFastForward wire name is mediaFastForward', () {
      expect(RemoteCommand.mediaFastForward.wireName, 'mediaFastForward');
    });
  });
}

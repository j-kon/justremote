enum RemoteCommand {
  power('power'),
  home('home'),
  back('back'),
  menu('menu'),
  up('up'),
  down('down'),
  left('left'),
  right('right'),
  select('select'),
  volumeUp('volumeUp'),
  volumeDown('volumeDown'),
  mute('mute'),
  channelUp('channelUp'),
  channelDown('channelDown'),
  mediaPlayPause('mediaPlayPause'),
  mediaStop('mediaStop'),
  mediaNext('mediaNext'),
  mediaPrevious('mediaPrevious'),
  mediaRewind('mediaRewind'),
  mediaFastForward('mediaFastForward');

  const RemoteCommand(this.wireName);

  final String wireName;
}

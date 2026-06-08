package com.justremote.justremote.remote.protocol

import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteDirection
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteKeyCode
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteKeyInject
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteMessage

object RemoteCommandMapper {
    private val keyCodes = mapOf(
        "power" to RemoteKeyCode.KEYCODE_POWER,
        "home" to RemoteKeyCode.KEYCODE_HOME,
        "back" to RemoteKeyCode.KEYCODE_BACK,
        "menu" to RemoteKeyCode.KEYCODE_MENU,
        "up" to RemoteKeyCode.KEYCODE_DPAD_UP,
        "down" to RemoteKeyCode.KEYCODE_DPAD_DOWN,
        "left" to RemoteKeyCode.KEYCODE_DPAD_LEFT,
        "right" to RemoteKeyCode.KEYCODE_DPAD_RIGHT,
        "select" to RemoteKeyCode.KEYCODE_DPAD_CENTER,
        "volumeUp" to RemoteKeyCode.KEYCODE_VOLUME_UP,
        "volumeDown" to RemoteKeyCode.KEYCODE_VOLUME_DOWN,
        "mute" to RemoteKeyCode.KEYCODE_VOLUME_MUTE,
        "channelUp" to RemoteKeyCode.KEYCODE_CHANNEL_UP,
        "channelDown" to RemoteKeyCode.KEYCODE_CHANNEL_DOWN,
        "mediaPlayPause" to RemoteKeyCode.KEYCODE_MEDIA_PLAY_PAUSE,
        "mediaStop" to RemoteKeyCode.KEYCODE_MEDIA_STOP,
        "mediaNext" to RemoteKeyCode.KEYCODE_MEDIA_NEXT,
        "mediaPrevious" to RemoteKeyCode.KEYCODE_MEDIA_PREVIOUS,
        "mediaRewind" to RemoteKeyCode.KEYCODE_MEDIA_REWIND,
        "mediaFastForward" to RemoteKeyCode.KEYCODE_MEDIA_FAST_FORWARD,
    )

    fun toKeyCode(command: String): RemoteKeyCode? = keyCodes[command]

    fun toKeyInjectMessage(command: String): RemoteMessage? {
        val keyCode = toKeyCode(command) ?: return null
        return RemoteMessage.newBuilder()
            .setRemoteKeyInject(
                RemoteKeyInject.newBuilder()
                    .setKeyCode(keyCode)
                    .setDirection(RemoteDirection.SHORT)
            )
            .build()
    }
}

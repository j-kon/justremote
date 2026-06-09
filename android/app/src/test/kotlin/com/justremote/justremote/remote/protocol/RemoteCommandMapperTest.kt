package com.justremote.justremote.remote.protocol

import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteDirection
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteKeyCode
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class RemoteCommandMapperTest {
    @Test
    fun mapsFlutterCommandsToAndroidTvKeyCodes() {
        val expected = mapOf(
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
            "channelDown" to RemoteKeyCode.KEYCODE_CHANNEL_DOWN
        )

        expected.forEach { (command, keyCode) ->
            assertEquals(keyCode, RemoteCommandMapper.toKeyCode(command))
        }
    }

    @Test
    fun returnsNullForUnknownCommand() {
        assertNull(RemoteCommandMapper.toKeyCode("keyboard"))
    }

    @Test
    fun buildsShortKeyInjectMessages() {
        val message = RemoteCommandMapper.toKeyInjectMessage("back")

        assertEquals(RemoteKeyCode.KEYCODE_BACK, message?.remoteKeyInject?.keyCode)
        assertEquals(RemoteDirection.SHORT, message?.remoteKeyInject?.direction)
    }
}

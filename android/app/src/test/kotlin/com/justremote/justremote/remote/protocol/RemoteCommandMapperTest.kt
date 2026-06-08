package com.justremote.justremote.remote.protocol

import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteDirection
import com.justremote.justremote.remote.protocol.protobuf.RemoteMessageProto.RemoteKeyCode
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class RemoteCommandMapperTest {
    @Test
    fun mapsFlutterCommandsToAndroidTvKeyCodes() {
        assertEquals(RemoteKeyCode.KEYCODE_HOME, RemoteCommandMapper.toKeyCode("home"))
        assertEquals(RemoteKeyCode.KEYCODE_DPAD_CENTER, RemoteCommandMapper.toKeyCode("select"))
        assertEquals(RemoteKeyCode.KEYCODE_VOLUME_MUTE, RemoteCommandMapper.toKeyCode("mute"))
        assertEquals(RemoteKeyCode.KEYCODE_CHANNEL_UP, RemoteCommandMapper.toKeyCode("channelUp"))
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

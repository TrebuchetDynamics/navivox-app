package com.trebuchetdynamics.navivox.pairing

import java.net.URI

object PairingHandoffIntentParser {
    const val ACTION_VIEW = "android.intent.action.VIEW"
    const val ACTION_SEND = "android.intent.action.SEND"
    const val EXTRA_TEXT = "android.intent.extra.TEXT"

    fun parse(
        action: String?,
        type: String?,
        data: String?,
        text: String?,
    ): PairingHandoffPayload? {
        return when (action) {
            ACTION_VIEW -> parseDirectAppOpen(data)
            ACTION_SEND -> parseSharedText(type, text)
            else -> null
        }
    }

    private fun parseDirectAppOpen(data: String?): PairingHandoffPayload? {
        val payload = data?.trim()?.takeIf { it.isNotEmpty() } ?: return null
        val uri = runCatching { URI(payload) }.getOrNull() ?: return null
        if (!uri.isNavivoxConnectUri()) return null
        return PairingHandoffPayload(
            payload = payload,
            source = PairingHandoffPayload.Source.DirectAppOpen,
        )
    }

    private fun URI.isNavivoxConnectUri(): Boolean {
        return scheme.equals(NAVIVOX_SCHEME, ignoreCase = true) &&
            host.equals(NAVIVOX_CONNECT_HOST, ignoreCase = true)
    }

    private const val NAVIVOX_SCHEME = "navivox"
    private const val NAVIVOX_CONNECT_HOST = "connect"

    private fun parseSharedText(type: String?, text: String?): PairingHandoffPayload? {
        if (!type.isTextMimeType()) return null
        val payload = text?.trim()?.takeIf { it.isNotEmpty() } ?: return null
        return PairingHandoffPayload(
            payload = payload,
            source = PairingHandoffPayload.Source.SharedText,
        )
    }

    private fun String?.isTextMimeType(): Boolean {
        return orEmpty().startsWith(TEXT_MIME_TYPE_PREFIX, ignoreCase = true)
    }

    private const val TEXT_MIME_TYPE_PREFIX = "text/"
}

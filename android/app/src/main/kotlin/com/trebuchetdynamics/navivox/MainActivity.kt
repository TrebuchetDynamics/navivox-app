package com.trebuchetdynamics.navivox

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var initialConnectIntent: String? = null
    private var connectIntentEvents: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        initialConnectIntent = connectPayloadFrom(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CONNECT_INTENTS_METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialConnectIntent" -> result.success(
                    initialConnectIntent ?: connectPayloadFrom(intent),
                )
                else -> result.notImplemented()
            }
        }
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CONNECT_INTENTS_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    connectIntentEvents = events
                }

                override fun onCancel(arguments: Any?) {
                    connectIntentEvents = null
                }
            },
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val payload = connectPayloadFrom(intent) ?: return
        initialConnectIntent = payload
        connectIntentEvents?.success(payload)
    }

    private fun connectPayloadFrom(intent: Intent?): String? {
        if (intent == null) return null
        return when (intent.action) {
            Intent.ACTION_VIEW -> {
                val data = intent.data ?: return null
                if (data.scheme == "navivox" && data.host == "connect") {
                    data.toString()
                } else {
                    null
                }
            }
            Intent.ACTION_SEND -> {
                if (!intent.type.orEmpty().startsWith("text/")) return null
                intent.getStringExtra(Intent.EXTRA_TEXT)?.trim()?.takeIf { it.isNotEmpty() }
            }
            else -> null
        }
    }

    companion object {
        private const val CONNECT_INTENTS_METHOD_CHANNEL =
            "com.trebuchetdynamics.navivox/connect_intents"
        private const val CONNECT_INTENTS_EVENT_CHANNEL =
            "com.trebuchetdynamics.navivox/connect_intents/events"
    }
}

package com.example.pda

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.pda/scanner_events"
    private var eventSink: EventChannel.EventSink? = null

    private val scanReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null) return
        if ("com.sunmi.scanner.ACTION_DATA_CODE_RECEIVED" == intent.action) {

            // Always try getStringExtra first, fallback to byte[]
            val barCodeStr: String? = intent.getStringExtra("data") ?: intent.getByteArrayExtra("data")?.let { String(it) }

            barCodeStr?.let {
                Log.d("Scanner", "Scanned: $it")
                eventSink?.success(it) // send scanned code to Flutter
            }
        }
    }
}


    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerReceiver(
                        scanReceiver,
                        IntentFilter("com.sunmi.scanner.ACTION_DATA_CODE_RECEIVED")
                    )
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterReceiver(scanReceiver)
                }
            }
        )
    }
}

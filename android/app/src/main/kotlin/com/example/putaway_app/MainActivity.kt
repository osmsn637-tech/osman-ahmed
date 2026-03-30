package com.example.putaway_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "com.putaway/scanner"
    private val eventChannelName = "com.putaway/scanner/events"

    private lateinit var scannerManager: ScannerManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        scannerManager = ScannerManager(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "startListening" -> {
                        scannerManager.startListening()
                        result.success(null)
                    }
                    "stopListening" -> {
                        scannerManager.stopListening()
                        result.success(null)
                    }
                    "enableScanner" -> {
                        scannerManager.enableScanner()
                        result.success(null)
                    }
                    "disableScanner" -> {
                        scannerManager.disableScanner()
                        result.success(null)
                    }
                    "getDeviceType" -> result.success(scannerManager.deviceType())
                    "getDeviceInfo" -> result.success(scannerManager.getDeviceInfo())
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    scannerManager.setSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    scannerManager.setSink(null)
                }
            })
    }
}

class ScannerManager(private val context: Context) {
    private var zebraService: ZebraScannerService? = null
    private var honeywellService: HoneywellScannerService? = null
    private var eventSink: EventChannel.EventSink? = null

    fun deviceType(): String {
        val manufacturer = Build.MANUFACTURER.lowercase()
        return when {
            manufacturer.contains("zebra") -> "zebra"
            manufacturer.contains("honeywell") -> "honeywell"
            else -> "unknown"
        }
    }

    fun setSink(sink: EventChannel.EventSink?) {
        eventSink = sink
        zebraService?.setSink(sink)
        honeywellService?.setSink(sink)
    }

    private fun ensureService() {
        when (deviceType()) {
            "zebra" -> if (zebraService == null) zebraService = ZebraScannerService(context, eventSink)
            "honeywell" -> if (honeywellService == null) honeywellService = HoneywellScannerService(context, eventSink)
        }
    }

    fun startListening() {
        ensureService()
        zebraService?.startListening()
        honeywellService?.startListening()
    }

    fun stopListening() {
        zebraService?.stopListening()
        honeywellService?.stopListening()
    }

    fun enableScanner() {
        ensureService()
        zebraService?.enable()
        honeywellService?.enable()
    }

    fun disableScanner() {
        zebraService?.disable()
        honeywellService?.disable()
    }

    fun getDeviceInfo(): Map<String, String> {
        return mapOf(
            "deviceSerial" to resolveDeviceSerial(),
            "model" to Build.MODEL.orEmpty(),
            "osVersion" to Build.VERSION.RELEASE.orEmpty(),
        )
    }

    private fun resolveDeviceSerial(): String {
        val serial = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Build.getSerial()
            } else {
                @Suppress("DEPRECATION")
                Build.SERIAL
            }
        } catch (e: Exception) {
            null
        }

        if (!serial.isNullOrBlank() && !serial.equals(Build.UNKNOWN, ignoreCase = true)) {
            return serial
        }

        return Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
            ?.takeIf { it.isNotBlank() }
            .orEmpty()
    }
}

class ZebraScannerService(private val context: Context, private var sink: EventChannel.EventSink?) {
    private val dataWedgeAction = "com.symbol.datawedge.api.ACTION"
    private val dataWedgeResultAction = "com.symbol.datawedge.api.RESULT_ACTION"
    private val profileName = "PutawayProfile"
    private val scanIntent = "com.putawayapp.SCAN"

    private var receiverRegistered = false

    private val scanReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            if (intent == null) return
            val action = intent.action ?: return
            if (action == scanIntent || action == dataWedgeResultAction) {
                val data = intent.getStringExtra("com.symbol.datawedge.data_string")
                data?.let { sink?.success(it) }
            }
        }
    }

    fun setSink(newSink: EventChannel.EventSink?) {
        sink = newSink
    }

    fun startListening() {
        registerReceiver()
        configureProfile()
    }

    fun stopListening() {
        if (receiverRegistered) {
            context.unregisterReceiver(scanReceiver)
            receiverRegistered = false
        }
    }

    fun enable() {
        sendCommand("com.symbol.datawedge.api.SCANNER_INPUT_PLUGIN", "ENABLE")
    }

    fun disable() {
        sendCommand("com.symbol.datawedge.api.SCANNER_INPUT_PLUGIN", "DISABLE")
    }

    private fun registerReceiver() {
        if (receiverRegistered) return
        val filter = IntentFilter()
        filter.addAction(scanIntent)
        filter.addAction(dataWedgeResultAction)
        context.registerReceiver(scanReceiver, filter)
        receiverRegistered = true
    }

    private fun configureProfile() {
        // Minimal profile creation
        val createIntent = Intent()
        createIntent.action = dataWedgeAction
        createIntent.putExtra("com.symbol.datawedge.api.CREATE_PROFILE", profileName)
        context.sendBroadcast(createIntent)

        val setConfig = Intent()
        setConfig.action = dataWedgeAction
        setConfig.putExtra("com.symbol.datawedge.api.SET_CONFIG", Bundle().apply {
            putString("PROFILE_NAME", profileName)
            putString("PROFILE_ENABLED", "true")
            putString("CONFIG_MODE", "CREATE_IF_NOT_EXISTS")
            putParcelableArray("APP_LIST", arrayOf(Bundle().apply {
                putString("PACKAGE_NAME", context.packageName)
                putStringArray("ACTIVITY_LIST", arrayOf("*"))
            }))
            putBundle("OUTPUT_PLUGIN", Bundle().apply {
                putString("PLUGIN_NAME", "INTENT")
                putString("RESET_CONFIG", "true")
                putBundle("PARAM_LIST", Bundle().apply {
                    putString("intent_output_enabled", "true")
                    putString("intent_action", scanIntent)
                    putString("intent_delivery", "2") // broadcast
                })
            })
        })
        context.sendBroadcast(setConfig)
    }

    private fun sendCommand(command: String, parameter: String) {
        val dwIntent = Intent()
        dwIntent.action = dataWedgeAction
        dwIntent.putExtra(command, parameter)
        context.sendBroadcast(dwIntent)
    }
}

class HoneywellScannerService(private val context: Context, private var sink: EventChannel.EventSink?) {
    private var aidcManager: Any? = null
    private var barcodeReader: Any? = null
    private var listenerRegistered = false

    fun setSink(newSink: EventChannel.EventSink?) {
        sink = newSink
    }

    fun startListening() {
        try {
            val aidcClass = Class.forName("com.honeywell.aidc.AidcManager")
            val createMethod = aidcClass.getMethod("create", Context::class.java, aidcClass.declaredClasses.first { it.simpleName == "CreatedCallback" })
            val callbackProxy = java.lang.reflect.Proxy.newProxyInstance(
                aidcClass.classLoader,
                arrayOf(aidcClass.declaredClasses.first { it.simpleName == "CreatedCallback" })
            ) { _, method, args ->
                if (method.name == "onCreated" && args != null) {
                    aidcManager = args[0]
                    initReader()
                }
                null
            }
            createMethod.invoke(null, context, callbackProxy)
        } catch (e: Exception) {
            Log.e("Scanner", "Honeywell init failed", e)
        }
    }

    fun stopListening() {
        try {
            val reader = barcodeReader
            if (reader != null && listenerRegistered) {
                reader.javaClass.getMethod("removeBarcodeListener", Class.forName("com.honeywell.aidc.BarcodeReader\$BarcodeListener")).invoke(reader, barcodeListener)
                listenerRegistered = false
            }
            reader?.javaClass?.getMethod("close")?.invoke(reader)
            barcodeReader = null
            aidcManager?.javaClass?.getMethod("close")?.invoke(aidcManager)
            aidcManager = null
        } catch (e: Exception) {
            Log.e("Scanner", "Honeywell stop failed", e)
        }
    }

    fun enable() {
        // Honeywell scanner enables on claim; no-op here.
    }

    fun disable() {
        try {
            barcodeReader?.javaClass?.getMethod("stopDecode")?.invoke(barcodeReader)
        } catch (e: Exception) {
            Log.e("Scanner", "Honeywell disable failed", e)
        }
    }

    private fun initReader() {
        try {
            val manager = aidcManager ?: return
            val createReader = manager.javaClass.getMethod("createBarcodeReader")
            val reader = createReader.invoke(manager)
            barcodeReader = reader
            val addListenerMethod = reader.javaClass.getMethod(
                "addBarcodeListener",
                Class.forName("com.honeywell.aidc.BarcodeReader\$BarcodeListener")
            )
            addListenerMethod.invoke(reader, barcodeListener)
            listenerRegistered = true
            reader.javaClass.getMethod("claim")?.invoke(reader)
            reader.javaClass.getMethod("setProperty", String::class.java, Any::class.java)
                ?.invoke(reader, "DPR_DATA_FORMAT", "DEFAULT")
        } catch (e: Exception) {
            Log.e("Scanner", "Honeywell reader init failed", e)
        }
    }

    private val barcodeListener: Any = java.lang.reflect.Proxy.newProxyInstance(
        javaClass.classLoader,
        arrayOf(Class.forName("com.honeywell.aidc.BarcodeReader\$BarcodeListener"))
    ) { _, method, args ->
        if (method.name == "onBarcodeEvent" && args != null) {
          val event = args[0]
          try {
            val data = event.javaClass.getMethod("getBarcodeData").invoke(event) as? String
            data?.let { sink?.success(it) }
          } catch (e: Exception) {
            Log.e("Scanner", "Honeywell barcode callback failed", e)
          }
        }
        null
    }
}

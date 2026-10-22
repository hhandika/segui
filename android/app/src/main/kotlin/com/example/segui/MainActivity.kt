package com.hhandika.segui

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var mobileIo: MobileIoPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mobileIo = MobileIoPlugin(this, flutterEngine.dartExecutor.binaryMessenger).also {
            it.handleIntent(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        mobileIo?.handleIntent(intent)
    }

    @Deprecated("Flutter activities still receive results through this callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (mobileIo?.onActivityResult(requestCode, resultCode, data) == true) {
            return
        }
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        mobileIo?.dispose()
        mobileIo = null
        super.onDestroy()
    }
}

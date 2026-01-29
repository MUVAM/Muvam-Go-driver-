package com.example.muvam_rider

import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import com.qoreid.qoreidsdk.QoreidsdkPlugin

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        QoreidsdkPlugin.initialize(this)
    }
}

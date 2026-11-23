package com.iamjarl.wodrounds

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge() // light or dark system bars, following the system as the screen does
        super.onCreate(savedInstanceState)
        val prefs = getSharedPreferences("setup", MODE_PRIVATE)
        if (savedInstanceState == null) Capture.apply(intent, prefs) // debug builds only
        setContent { TimerScreen(prefs) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Capture.apply(intent, getSharedPreferences("setup", MODE_PRIVATE)) // debug builds only
    }
}

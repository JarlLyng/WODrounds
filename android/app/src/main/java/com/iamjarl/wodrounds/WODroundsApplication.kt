package com.iamjarl.wodrounds

import android.app.Application

class WODroundsApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Telemetry.start(this)
    }
}

//
//  WODTimerSync.swift
//  WODrounds
//
//  Writes timer state to App Group so the Watch app can display the same workout.
//

import Foundation

enum WODTimerSync {
    static let appGroupID = "group.com.iamjarl.WODrounds"
    static let key = "wodrounds.sync.payload"

    static var shared: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func write(_ payload: WODTimerEngine.SyncPayload) {
        guard let defaults = shared else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(payload) {
            defaults.set(data, forKey: key)
        }
    }

    static func clear() {
        shared?.removeObject(forKey: key)
    }
}

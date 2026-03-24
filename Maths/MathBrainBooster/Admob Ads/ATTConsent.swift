//
//  ATTConsent.swift
//  WatchQ
//
//  Created by Saturn Games on 10/03/26.
//

import Foundation

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
import AdSupport

enum ATTConsent {
    static func requestIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
#else
enum ATTConsent {
    static func requestIfNeeded() { }
}
#endif

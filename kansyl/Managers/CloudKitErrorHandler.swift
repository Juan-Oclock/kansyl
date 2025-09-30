//
//  CloudKitErrorHandler.swift
//  kansyl
//
//  Created on 9/25/25.
//  Comprehensive error handling for CloudKit operations
//

import Foundation
import CloudKit
import SwiftUI

struct CloudKitErrorHandler {
    
    static func handleError(_ error: Error) -> (title: String, message: String, severity: ErrorSeverity) {
        if let ckError = error as? CKError {
            return handleCloudKitError(ckError)
        } else {
            return handleGenericError(error)
        }
    }
    
    private static func handleCloudKitError(_ error: CKError) -> (title: String, message: String, severity: ErrorSeverity) {
        switch error.code {
        case .accountTemporarilyUnavailable:
            return (
                title: "iCloud Temporarily Unavailable",
                message: "Your iCloud account is temporarily unavailable. Please try again later.",
                severity: .warning
            )
            
        case .networkUnavailable, .networkFailure:
            return (
                title: "Network Connection Required",
                message: "iCloud sync requires an internet connection. Please check your network settings and try again.",
                severity: .warning
            )
            
        case .notAuthenticated:
            return (
                title: "iCloud Sign-In Required",
                message: "Please sign in to iCloud in Settings to enable sync.",
                severity: .error
            )
            
        case .quotaExceeded:
            return (
                title: "iCloud Storage Full",
                message: "Your iCloud storage is full. Please free up space or upgrade your iCloud plan.",
                severity: .error
            )
            
        case .permissionFailure:
            return (
                title: "iCloud Permission Denied",
                message: "Kansyl doesn't have permission to access iCloud. Please check your iCloud settings.",
                severity: .error
            )
            
        case .managedAccountRestricted:
            return (
                title: "iCloud Restricted",
                message: "iCloud is restricted on this device by your organization's policy.",
                severity: .error
            )
            
        case .serviceUnavailable:
            return (
                title: "iCloud Service Unavailable",
                message: "iCloud services are currently unavailable. Please try again later.",
                severity: .warning
            )
            
        case .limitExceeded:
            return (
                title: "Sync Limit Exceeded",
                message: "You've exceeded the sync limits. Please try again later.",
                severity: .warning
            )
            
        case .serverRejectedRequest:
            return (
                title: "Sync Request Rejected",
                message: "The sync request was rejected by iCloud. This may be a temporary issue.",
                severity: .warning
            )
            
        case .constraintViolation:
            return (
                title: "Data Conflict",
                message: "There was a conflict with your data. Please try syncing again.",
                severity: .warning
            )
            
        case .incompatibleVersion:
            return (
                title: "App Update Required",
                message: "Please update Kansyl to the latest version to continue using iCloud sync.",
                severity: .error
            )
            
        case .assetFileNotFound, .assetFileModified:
            return (
                title: "Sync Data Issue",
                message: "Some sync data was not found or modified. Sync will retry automatically.",
                severity: .info
            )
            
        case .zoneNotFound:
            return (
                title: "Sync Zone Missing",
                message: "iCloud sync zone is missing. Sync will be reset automatically.",
                severity: .info
            )
            
        case .userDeletedZone:
            return (
                title: "Sync Data Deleted",
                message: "Your sync data was deleted from iCloud. Sync will start fresh.",
                severity: .warning
            )
            
        default:
            return (
                title: "iCloud Sync Error",
                message: "An unexpected sync error occurred: \\(error.localizedDescription)",
                severity: .error
            )
        }
    }
    
    private static func handleGenericError(_ error: Error) -> (title: String, message: String, severity: ErrorSeverity) {
        return (
            title: "Sync Error",
            message: error.localizedDescription,
            severity: .error
        )
    }
    
    static func shouldRetry(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        
        switch ckError.code {
        case .networkUnavailable, .networkFailure, .serviceUnavailable,
             .accountTemporarilyUnavailable, .zoneBusy, .serverResponseLost,
             .requestRateLimited:
            return true
        default:
            return false
        }
    }
    
    static func retryDelay(for error: Error) -> TimeInterval {
        guard let ckError = error as? CKError else { return 5.0 }
        
        // Check for retry-after header
        if let retryAfter = ckError.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
            return min(retryAfter, 300) // Cap at 5 minutes
        }
        
        switch ckError.code {
        case .requestRateLimited:
            return 30.0
        case .zoneBusy:
            return 10.0
        case .networkUnavailable, .networkFailure:
            return 5.0
        default:
            return 15.0
        }
    }
    
    static func isRecoverableError(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return true }
        
        switch ckError.code {
        case .notAuthenticated, .permissionFailure, .managedAccountRestricted,
             .incompatibleVersion, .quotaExceeded:
            return false
        default:
            return true
        }
    }
}

enum ErrorSeverity {
    case info
    case warning
    case error
    
    var color: Color {
        switch self {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        }
    }
}

// MARK: - Error Recovery Suggestions

extension CloudKitErrorHandler {
    static func getRecoveryActions(for error: Error) -> [CloudKitRecoveryAction] {
        guard let ckError = error as? CKError else { return [] }
        
        switch ckError.code {
        case .notAuthenticated:
            return [.openSettings]
            
        case .networkUnavailable, .networkFailure:
            return [.checkNetwork, .retryLater]
            
        case .quotaExceeded:
            return [.openSettings, .upgradeStorage]
            
        case .permissionFailure:
            return [.openSettings]
            
        case .serviceUnavailable, .accountTemporarilyUnavailable:
            return [.retryLater]
            
        default:
            return [.retryNow, .contactSupport]
        }
    }
}

enum CloudKitRecoveryAction: CaseIterable {
    case retryNow
    case retryLater
    case openSettings
    case checkNetwork
    case upgradeStorage
    case contactSupport
    
    var title: String {
        switch self {
        case .retryNow:
            return "Retry Now"
        case .retryLater:
            return "Try Again Later"
        case .openSettings:
            return "Open Settings"
        case .checkNetwork:
            return "Check Network"
        case .upgradeStorage:
            return "Upgrade Storage"
        case .contactSupport:
            return "Contact Support"
        }
    }
    
    var systemImage: String {
        switch self {
        case .retryNow:
            return "arrow.clockwise"
        case .retryLater:
            return "clock"
        case .openSettings:
            return "gear"
        case .checkNetwork:
            return "wifi"
        case .upgradeStorage:
            return "icloud.and.arrow.up"
        case .contactSupport:
            return "envelope"
        }
    }
    
    func execute() {
        switch self {
        case .retryNow:
            Task {
                try? await CloudKitManager.shared.performManualSync()
            }
        case .retryLater:
            break // No action needed
        case .openSettings:
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        case .checkNetwork:
            // Could open network settings or show network troubleshooting
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        case .upgradeStorage:
            // Could open iCloud settings
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        case .contactSupport:
            if let url = URL(string: "mailto:kansyl@juan-oclock.com?subject=iCloud%20Sync%20Issue") {
                UIApplication.shared.open(url)
            }
        }
    }
}
//
//  CloudKitManager.swift
//  kansyl
//
//  Created on 9/25/25.
//  Handles CloudKit sync operations and premium user validation
//

import Foundation
import CloudKit
import CoreData
import SwiftUI

enum CloudKitSyncStatus {
    case unknown
    case available
    case unavailable
    case restricted
    case noAccount
    case networkUnavailable
    case quotaExceeded
}

enum CloudKitError: LocalizedError {
    case accountNotAvailable
    case networkUnavailable
    case quotaExceeded
    case syncDisabled
    case notPremiumUser
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "iCloud account is not available. Please sign in to iCloud in Settings."
        case .networkUnavailable:
            return "Network connection is required for iCloud sync."
        case .quotaExceeded:
            return "iCloud storage quota exceeded. Please free up space."
        case .syncDisabled:
            return "iCloud sync is disabled for this app."
        case .notPremiumUser:
            return "iCloud backup is a premium feature. Please upgrade to access sync."
        }
    }
}

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    @Published var syncStatus: CloudKitSyncStatus = .unknown
    @Published var isInitialSyncComplete: Bool = false
    @Published var lastSyncDate: Date?
    @Published var isSyncing: Bool = false
    
    private let container: CKContainer
    private var accountStatusTask: Task<Void, Never>?
    
    // Premium status check - this should be connected to your subscription manager
    var isPremiumUser: Bool {
        #if DEBUG
        // Disable premium features during development with personal team
        return false
        #else
        // TODO: Connect to your premium subscription manager
        // For now, we'll check UserDefaults as a placeholder
        return UserDefaults.standard.bool(forKey: "isPremiumUser")
        #endif
    }
    
    private init() {
        // For personal development teams without CloudKit entitlements,
        // we'll still initialize the container but disable functionality
        #if DEBUG
        // Use default container for development to avoid provisioning issues
        self.container = CKContainer.default()
        #else
        // Use custom container for production
        self.container = CKContainer(identifier: "iCloud.com.juan-oclock.kansyl.kansyl")
        #endif
        
        // Only start monitoring if premium features are available
        if isPremiumUser {
            startMonitoringAccountStatus()
        } else {
            // Set status to unavailable for non-premium users
            syncStatus = .unavailable
        }
    }
    
    deinit {
        accountStatusTask?.cancel()
    }
    
    // MARK: - Account Status Monitoring
    
    private func startMonitoringAccountStatus() {
        accountStatusTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.checkAccountStatus()
                
                // Check every 30 seconds
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
    }
    
    private func checkAccountStatus() async {
        // Skip account status check if premium features are disabled
        guard isPremiumUser else {
            await MainActor.run {
                self.syncStatus = .unavailable
            }
            return
        }
        
        do {
            let status = try await container.accountStatus()
            
            await MainActor.run {
                switch status {
                case .available:
                    self.syncStatus = .available
                case .noAccount:
                    self.syncStatus = .noAccount
                case .restricted:
                    self.syncStatus = .restricted
                case .couldNotDetermine:
                    self.syncStatus = .unknown
                case .temporarilyUnavailable:
                    self.syncStatus = .unavailable
                @unknown default:
                    self.syncStatus = .unknown
                }
            }
        } catch {
            await MainActor.run {
                self.syncStatus = .networkUnavailable
            }
        }
    }
    
    // MARK: - Sync Operations
    
    func enableSync() async throws {
        guard isPremiumUser else {
            throw CloudKitError.notPremiumUser
        }
        
        guard syncStatus == .available else {
            throw CloudKitError.accountNotAvailable
        }
        
        isSyncing = true
        
        do {
            // Trigger an initial sync by saving the context
            // This will cause CloudKit to upload any existing data
            let context = PersistenceController.shared.container.viewContext
            
            if context.hasChanges {
                try context.save()
            }
            
            // Mark sync as enabled
            UserDefaults.standard.set(true, forKey: "cloudKitSyncEnabled")
            
            await MainActor.run {
                self.lastSyncDate = Date()
                self.isInitialSyncComplete = true
            }
            
        } catch {
            throw error
        }
        
        isSyncing = false
    }
    
    func disableSync() async {
        UserDefaults.standard.set(false, forKey: "cloudKitSyncEnabled")
        
        await MainActor.run {
            self.isInitialSyncComplete = false
            self.lastSyncDate = nil
        }
    }
    
    var isSyncEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "cloudKitSyncEnabled") && isPremiumUser
    }
    
    // MARK: - Manual Sync
    
    func performManualSync() async throws {
        guard isPremiumUser else {
            throw CloudKitError.notPremiumUser
        }
        
        guard syncStatus == .available else {
            throw CloudKitError.accountNotAvailable
        }
        
        isSyncing = true
        
        do {
            let context = PersistenceController.shared.container.viewContext
            
            // Force a save to trigger CloudKit sync
            if context.hasChanges {
                try context.save()
            }
            
            // Wait a moment for the sync to process
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                self.lastSyncDate = Date()
            }
            
        } catch {
            throw error
        }
        
        isSyncing = false
    }
    
    // MARK: - Sync Status Helpers
    
    var canSync: Bool {
        return isPremiumUser && syncStatus == .available
    }
    
    var syncStatusMessage: String {
        // Show premium message if not a premium user
        guard isPremiumUser else {
            return "iCloud backup is a premium feature"
        }
        
        switch syncStatus {
        case .unknown:
            return "Checking iCloud status..."
        case .available:
            return isSyncEnabled ? "iCloud sync is active" : "iCloud sync is available"
        case .unavailable:
            return "iCloud is temporarily unavailable"
        case .restricted:
            return "iCloud is restricted on this device"
        case .noAccount:
            return "No iCloud account found. Sign in to iCloud in Settings."
        case .networkUnavailable:
            return "Network required for iCloud sync"
        case .quotaExceeded:
            return "iCloud storage is full"
        }
    }
    
    var syncStatusColor: Color {
        switch syncStatus {
        case .available:
            return isSyncEnabled ? .green : .blue
        case .unknown:
            return .gray
        default:
            return .orange
        }
    }
}

// MARK: - Notification Helpers

extension CloudKitManager {
    func setupRemoteChangeNotifications() {
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.lastSyncDate = Date()
            }
        }
    }
}
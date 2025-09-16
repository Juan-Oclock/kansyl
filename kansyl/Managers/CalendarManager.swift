//
//  CalendarManager.swift
//  kansyl
//
//  Created on 9/16/25.
//

import Foundation
import EventKit

final class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    private let userDefaultsKey = "calendar_event_ids"
    
    // Mapping: subscription.id (UUID string) -> EKEvent.eventIdentifier
    private var idMap: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: userDefaultsKey) }
    }
    
    private init() {}
    
    // MARK: - Permission
    func ensureAccess(completion: @escaping (Bool) -> Void) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            completion(true)
        case .notDetermined:
            eventStore.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }
    
    // MARK: - Public API
    func addOrUpdateEvent(for subscription: Subscription) {
        guard let id = subscription.id?.uuidString,
              let endDate = subscription.endDate else { return }
        
        ensureAccess { [weak self] granted in
            guard let self = self, granted else { return }
            
            let event: EKEvent
            if let existingIdentifier = self.idMap[id], let existingEvent = self.eventStore.event(withIdentifier: existingIdentifier) {
                event = existingEvent
            } else {
                event = EKEvent(eventStore: self.eventStore)
                // Prefer default calendar if writable, else fallback to first writable calendar
                if let defaultCal = self.eventStore.defaultCalendarForNewEvents, defaultCal.allowsContentModifications {
                    event.calendar = defaultCal
                } else if let writable = self.eventStore.calendars(for: .event).first(where: { $0.allowsContentModifications }) {
                    event.calendar = writable
                } else {
                    // No writable calendars available; abort
                    print("CalendarManager: No writable calendars available")
                    return
                }
            }
            
            let serviceName = subscription.name ?? "Subscription"
            event.title = "Trial ends: \(serviceName)"
            event.notes = "Automatically added by Kansyl."
            
            // Place the event at user's preferred notification time if available
            // Fallback to 9:00 AM if no specific notification time in preferences
            let hour = 9
            let minute = 0
            let cal = Calendar.current
            var components = cal.dateComponents([.year, .month, .day], from: endDate)
            components.hour = hour
            components.minute = minute
            let start = cal.date(from: components) ?? endDate
            
            event.startDate = start
            // 30-minute default duration
            event.endDate = start.addingTimeInterval(30 * 60)
            
            // Ensure a user-visible alert fires at the start time
            event.alarms = [EKAlarm(absoluteDate: start)]
            
            do {
                try self.eventStore.save(event, span: .thisEvent, commit: true)
                var map = self.idMap
                map[id] = event.eventIdentifier
                self.idMap = map
            } catch {
                print("Calendar event save error: \(error)")
            }
        }
    }
    
    func removeEvent(for subscription: Subscription) {
        guard let id = subscription.id?.uuidString else { return }
        ensureAccess { [weak self] granted in
            guard let self = self, granted else { return }
            
            guard let identifier = self.idMap[id], let event = self.eventStore.event(withIdentifier: identifier) else { return }
            do {
                try self.eventStore.remove(event, span: .thisEvent, commit: true)
                var map = self.idMap
                map.removeValue(forKey: id)
                self.idMap = map
            } catch {
                print("Calendar event remove error: \(error)")
            }
        }
    }
}

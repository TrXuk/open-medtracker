//
//  Medication+CoreDataClass.swift
//  OpenMedTracker
//
//  NSManagedObject subclass for Medication entity
//

import Foundation
import CoreData

@objc(Medication)
public class Medication: NSManagedObject {

    // MARK: - Lifecycle

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "createdAt")
        setPrimitiveValue(Date(), forKey: "updatedAt")
        setPrimitiveValue(true, forKey: "isActive")
    }

    public override func willSave() {
        super.willSave()
        if !isDeleted && isUpdated {
            setPrimitiveValue(Date(), forKey: "updatedAt")
        }
    }

    // MARK: - Computed Properties

    /// Full description of the medication with dosage
    public var fullDescription: String {
        "\(name) - \(dosageAmount)\(dosageUnit)"
    }

    /// Whether the medication is currently within its active date range
    public var isCurrentlyActive: Bool {
        guard isActive else { return false }

        let now = Date()
        if now < startDate { return false }
        if let end = endDate, now > end { return false }

        return true
    }

    /// Number of active schedules
    public var activeScheduleCount: Int {
        let scheduleArray = schedules?.allObjects as? [Schedule] ?? []
        return scheduleArray.filter { $0.isEnabled }.count
    }

    /// Sorted array of schedules by time of day
    public var sortedSchedules: [Schedule] {
        let scheduleArray = schedules?.allObjects as? [Schedule] ?? []
        return scheduleArray.sorted { $0.timeOfDay < $1.timeOfDay }
    }

    /// Duration in days that the medication has been taken
    public var durationInDays: Int {
        let calendar = Calendar.current
        let end = endDate ?? Date()
        let components = calendar.dateComponents([.day], from: startDate, to: end)
        return max(0, components.day ?? 0)
    }

    // MARK: - Helper Methods

    /// Deactivates the medication
    public func deactivate() {
        isActive = false
        endDate = Date()
    }

    /// Reactivates the medication
    public func reactivate() {
        isActive = true
        endDate = nil
    }

    /// Checks if the medication should be taken on a specific date
    /// - Parameter date: The date to check
    /// - Returns: True if any schedule is active for this date
    public func shouldTakeOn(date: Date) -> Bool {
        guard isCurrentlyActive else { return false }

        let scheduleArray = schedules?.allObjects as? [Schedule] ?? []
        return scheduleArray.contains { schedule in
            schedule.isEnabled && schedule.isDueOn(date: date)
        }
    }
}

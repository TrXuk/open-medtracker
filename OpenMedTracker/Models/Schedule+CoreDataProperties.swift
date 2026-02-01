//
//  Schedule+CoreDataProperties.swift
//  OpenMedTracker
//
//  Core Data properties for Schedule entity
//

import Foundation
import CoreData

extension Schedule {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Schedule> {
        return NSFetchRequest<Schedule>(entityName: "Schedule")
    }

    @NSManaged public var id: UUID
    @NSManaged public var timeOfDay: Date
    @NSManaged public var frequency: String
    @NSManaged public var daysOfWeek: Int16
    @NSManaged public var isEnabled: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var medication: Medication?
    @NSManaged public var doseHistories: NSSet?
}

// MARK: - Generated accessors for doseHistories

extension Schedule {

    @objc(addDoseHistoriesObject:)
    @NSManaged public func addToDoseHistories(_ value: DoseHistory)

    @objc(removeDoseHistoriesObject:)
    @NSManaged public func removeFromDoseHistories(_ value: DoseHistory)

    @objc(addDoseHistories:)
    @NSManaged public func addToDoseHistories(_ values: NSSet)

    @objc(removeDoseHistories:)
    @NSManaged public func removeFromDoseHistories(_ values: NSSet)
}

extension Schedule: Identifiable {}

//
//  Medication+CoreDataProperties.swift
//  OpenMedTracker
//
//  Core Data properties for Medication entity
//

import Foundation
import CoreData

extension Medication {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Medication> {
        return NSFetchRequest<Medication>(entityName: "Medication")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var dosageAmount: Double
    @NSManaged public var dosageUnit: String
    @NSManaged public var instructions: String?
    @NSManaged public var prescribedBy: String?
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var schedules: NSSet?
}

// MARK: - Generated accessors for schedules

extension Medication {

    @objc(addSchedulesObject:)
    @NSManaged public func addToSchedules(_ value: Schedule)

    @objc(removeSchedulesObject:)
    @NSManaged public func removeFromSchedules(_ value: Schedule)

    @objc(addSchedules:)
    @NSManaged public func addToSchedules(_ values: NSSet)

    @objc(removeSchedules:)
    @NSManaged public func removeFromSchedules(_ values: NSSet)
}

extension Medication: Identifiable {}

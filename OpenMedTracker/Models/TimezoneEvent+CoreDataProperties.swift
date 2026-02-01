//
//  TimezoneEvent+CoreDataProperties.swift
//  OpenMedTracker
//
//  Core Data properties for TimezoneEvent entity
//

import Foundation
import CoreData

extension TimezoneEvent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimezoneEvent> {
        return NSFetchRequest<TimezoneEvent>(entityName: "TimezoneEvent")
    }

    @NSManaged public var id: UUID
    @NSManaged public var previousTimezone: String
    @NSManaged public var newTimezone: String
    @NSManaged public var transitionTime: Date
    @NSManaged public var location: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var affectedDoses: NSSet?
}

// MARK: - Generated accessors for affectedDoses

extension TimezoneEvent {

    @objc(addAffectedDosesObject:)
    @NSManaged public func addToAffectedDoses(_ value: DoseHistory)

    @objc(removeAffectedDosesObject:)
    @NSManaged public func removeFromAffectedDoses(_ value: DoseHistory)

    @objc(addAffectedDoses:)
    @NSManaged public func addToAffectedDoses(_ values: NSSet)

    @objc(removeAffectedDoses:)
    @NSManaged public func removeFromAffectedDoses(_ values: NSSet)
}

extension TimezoneEvent: Identifiable {}

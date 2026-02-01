//
//  DoseHistory+CoreDataProperties.swift
//  OpenMedTracker
//
//  Core Data properties for DoseHistory entity
//

import Foundation
import CoreData

extension DoseHistory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DoseHistory> {
        return NSFetchRequest<DoseHistory>(entityName: "DoseHistory")
    }

    @NSManaged public var id: UUID
    @NSManaged public var scheduledTime: Date
    @NSManaged public var actualTime: Date?
    @NSManaged public var status: String
    @NSManaged public var notes: String?
    @NSManaged public var timezoneIdentifier: String
    @NSManaged public var createdAt: Date
    @NSManaged public var schedule: Schedule?
    @NSManaged public var timezoneEvent: TimezoneEvent?
}

extension DoseHistory: Identifiable {}

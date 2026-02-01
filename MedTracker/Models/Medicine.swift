//
//  Medicine.swift
//  MedTracker
//
//  Data model for medicine entries
//

import Foundation

struct Medicine: Identifiable, Codable {
    let id: UUID
    var name: String
    var dosage: String
    var frequency: String
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        dosage: String,
        frequency: String,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

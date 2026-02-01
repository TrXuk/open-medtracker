//
//  MedicineService.swift
//  MedTracker
//
//  Service layer for medicine data management
//

import Foundation

class MedicineService: ObservableObject {
    @Published var medicines: [Medicine] = []

    init() {
        // Initialize with empty medicines list
        // TODO: Load from persistent storage
    }

    func addMedicine(_ medicine: Medicine) {
        medicines.append(medicine)
        // TODO: Save to persistent storage
    }

    func updateMedicine(_ medicine: Medicine) {
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
            // TODO: Save to persistent storage
        }
    }

    func deleteMedicine(_ medicine: Medicine) {
        medicines.removeAll { $0.id == medicine.id }
        // TODO: Save to persistent storage
    }
}

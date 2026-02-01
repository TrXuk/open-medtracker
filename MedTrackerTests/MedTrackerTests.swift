//
//  MedTrackerTests.swift
//  MedTrackerTests
//
//  Unit tests for MedTracker
//

import XCTest
@testable import MedTracker

final class MedTrackerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMedicineCreation() throws {
        let medicine = Medicine(
            name: "Test Medicine",
            dosage: "10mg",
            frequency: "Once daily"
        )

        XCTAssertEqual(medicine.name, "Test Medicine")
        XCTAssertEqual(medicine.dosage, "10mg")
        XCTAssertEqual(medicine.frequency, "Once daily")
    }

    func testMedicineServiceAddMedicine() throws {
        let service = MedicineService()
        let medicine = Medicine(
            name: "Test Medicine",
            dosage: "10mg",
            frequency: "Once daily"
        )

        service.addMedicine(medicine)

        XCTAssertEqual(service.medicines.count, 1)
        XCTAssertEqual(service.medicines.first?.name, "Test Medicine")
    }
}

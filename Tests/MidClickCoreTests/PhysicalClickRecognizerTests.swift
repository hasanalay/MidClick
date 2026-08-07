import XCTest
@testable import MidClickCore

final class PhysicalClickRecognizerTests: XCTestCase {
    private let recognizer = PhysicalClickRecognizer()

    func testCenterClickRequiresSingleCenterContact() {
        XCTAssertTrue(recognizer.shouldConvertClick(
            trigger: .centerClick,
            contacts: [TouchContact(x: 0.5, y: 0.6, size: 0.2)],
            sampleAge: 0.02
        ))

        XCTAssertFalse(recognizer.shouldConvertClick(
            trigger: .centerClick,
            contacts: [TouchContact(x: 0.15, y: 0.6, size: 0.2)],
            sampleAge: 0.02
        ))
    }

    func testTwoFingerClickRequiresExactlyTwoContacts() {
        let two = [
            TouchContact(x: 0.3, y: 0.5, size: 0.2),
            TouchContact(x: 0.7, y: 0.5, size: 0.2)
        ]
        XCTAssertTrue(recognizer.shouldConvertClick(trigger: .twoFingerClick, contacts: two, sampleAge: 0.02))
        XCTAssertFalse(recognizer.shouldConvertClick(trigger: .twoFingerClick, contacts: Array(two.prefix(1)), sampleAge: 0.02))
    }

    func testThreeFingerClickRequiresExactlyThreeContacts() {
        let three = [
            TouchContact(x: 0.25, y: 0.5, size: 0.2),
            TouchContact(x: 0.5, y: 0.5, size: 0.2),
            TouchContact(x: 0.75, y: 0.5, size: 0.2)
        ]
        XCTAssertTrue(recognizer.shouldConvertClick(trigger: .threeFingerClick, contacts: three, sampleAge: 0.02))
    }

    func testTapTriggersNeverConvertPhysicalClick() {
        let contacts = [
            TouchContact(x: 0.3, y: 0.5, size: 0.2),
            TouchContact(x: 0.7, y: 0.5, size: 0.2)
        ]
        XCTAssertFalse(recognizer.shouldConvertClick(trigger: .twoFingerTap, contacts: contacts, sampleAge: 0.02))
        XCTAssertFalse(recognizer.shouldConvertClick(trigger: .threeFingerTap, contacts: contacts, sampleAge: 0.02))
    }

    func testStaleSampleNeverConverts() {
        let contacts = [
            TouchContact(x: 0.3, y: 0.5, size: 0.2),
            TouchContact(x: 0.7, y: 0.5, size: 0.2)
        ]
        XCTAssertFalse(recognizer.shouldConvertClick(trigger: .twoFingerClick, contacts: contacts, sampleAge: 0.5))
    }
}

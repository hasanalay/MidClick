import XCTest
@testable import MidClickCore

final class TapGestureRecognizerTests: XCTestCase {
    private let twoContacts = [
        TouchContact(x: 0.40, y: 0.55, size: 0.2),
        TouchContact(x: 0.60, y: 0.55, size: 0.2)
    ]

    private let threeContacts = [
        TouchContact(x: 0.35, y: 0.55, size: 0.2),
        TouchContact(x: 0.50, y: 0.55, size: 0.2),
        TouchContact(x: 0.65, y: 0.55, size: 0.2)
    ]

    func testValidTwoFingerTapEmitsOnFullRelease() {
        var recognizer = TapGestureRecognizer()

        XCTAssertFalse(recognizer.processFrame(contacts: [twoContacts[0]], timestamp: 1.00, requiredFingerCount: 2))
        XCTAssertFalse(recognizer.processFrame(contacts: twoContacts, timestamp: 1.05, requiredFingerCount: 2))
        XCTAssertFalse(recognizer.processFrame(contacts: [twoContacts[0]], timestamp: 1.12, requiredFingerCount: 2))
        XCTAssertTrue(recognizer.processFrame(contacts: [], timestamp: 1.16, requiredFingerCount: 2))
    }

    func testValidThreeFingerTapEmitsOnFullRelease() {
        var recognizer = TapGestureRecognizer()

        XCTAssertFalse(recognizer.processFrame(contacts: [threeContacts[0]], timestamp: 2.00, requiredFingerCount: 3))
        XCTAssertFalse(recognizer.processFrame(contacts: Array(threeContacts.prefix(2)), timestamp: 2.03, requiredFingerCount: 3))
        XCTAssertFalse(recognizer.processFrame(contacts: threeContacts, timestamp: 2.07, requiredFingerCount: 3))
        XCTAssertTrue(recognizer.processFrame(contacts: [], timestamp: 2.18, requiredFingerCount: 3))
    }

    func testLateFingerArrivalRejectsTap() {
        var recognizer = TapGestureRecognizer()

        XCTAssertFalse(recognizer.processFrame(contacts: [twoContacts[0]], timestamp: 3.00, requiredFingerCount: 2))
        XCTAssertFalse(recognizer.processFrame(contacts: twoContacts, timestamp: 3.13, requiredFingerCount: 2))
        XCTAssertFalse(recognizer.processFrame(contacts: [], timestamp: 3.18, requiredFingerCount: 2))
    }

    func testGestureLongerThanMaximumDurationRejectsTap() {
        var recognizer = TapGestureRecognizer()

        XCTAssertFalse(recognizer.processFrame(contacts: twoContacts, timestamp: 4.00, requiredFingerCount: 2))
        XCTAssertFalse(recognizer.processFrame(contacts: twoContacts, timestamp: 4.26, requiredFingerCount: 2))
        XCTAssertFalse(recognizer.processFrame(contacts: [], timestamp: 4.27, requiredFingerCount: 2))
    }

    func testExcessiveMovementRejectsTap() {
        var recognizer = TapGestureRecognizer()
        let moved = [
            TouchContact(x: 0.50, y: 0.55, size: 0.2),
            TouchContact(x: 0.70, y: 0.55, size: 0.2)
        ]

        XCTAssertFalse(recognizer.processFrame(contacts: twoContacts, timestamp: 5.00, requiredFingerCount: 2))
        XCTAssertFalse(recognizer.processFrame(contacts: moved, timestamp: 5.05, requiredFingerCount: 2))
        XCTAssertFalse(recognizer.processFrame(contacts: [], timestamp: 5.10, requiredFingerCount: 2))
    }

    func testTooManyFingersRejectsTap() {
        var recognizer = TapGestureRecognizer()

        XCTAssertFalse(recognizer.processFrame(contacts: twoContacts, timestamp: 6.00, requiredFingerCount: 2))
        XCTAssertFalse(recognizer.processFrame(contacts: threeContacts, timestamp: 6.04, requiredFingerCount: 2))
        XCTAssertFalse(recognizer.processFrame(contacts: [], timestamp: 6.08, requiredFingerCount: 2))
    }

    func testCancelSuppressesUntilAllContactsAreReleased() {
        var recognizer = TapGestureRecognizer()

        XCTAssertFalse(recognizer.processFrame(contacts: twoContacts, timestamp: 7.00, requiredFingerCount: 2))
        recognizer.cancel()
        XCTAssertFalse(recognizer.processFrame(contacts: twoContacts, timestamp: 7.04, requiredFingerCount: 2))
        XCTAssertFalse(recognizer.processFrame(contacts: [], timestamp: 7.08, requiredFingerCount: 2))

        XCTAssertFalse(recognizer.processFrame(contacts: twoContacts, timestamp: 8.00, requiredFingerCount: 2))
        XCTAssertTrue(recognizer.processFrame(contacts: [], timestamp: 8.10, requiredFingerCount: 2))
    }
}

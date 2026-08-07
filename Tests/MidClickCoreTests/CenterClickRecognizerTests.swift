import XCTest
@testable import MidClickCore

final class CenterClickRecognizerTests: XCTestCase {
    private let recognizer = CenterClickRecognizer()

    func testFreshSingleCenterContactConvertsClick() {
        let contacts = [TouchContact(x: 0.5, y: 0.6, size: 0.2)]

        XCTAssertTrue(recognizer.shouldConvertClick(contacts: contacts, sampleAge: 0.02))
    }

    func testOffCenterContactDoesNotConvertClick() {
        let contacts = [TouchContact(x: 0.1, y: 0.6, size: 0.2)]

        XCTAssertFalse(recognizer.shouldConvertClick(contacts: contacts, sampleAge: 0.02))
    }

    func testMultipleContactsDoNotConvertClick() {
        let contacts = [
            TouchContact(x: 0.48, y: 0.6, size: 0.2),
            TouchContact(x: 0.52, y: 0.4, size: 0.2)
        ]

        XCTAssertFalse(recognizer.shouldConvertClick(contacts: contacts, sampleAge: 0.02))
    }

    func testStaleTouchFrameDoesNotConvertClick() {
        let contacts = [TouchContact(x: 0.5, y: 0.6, size: 0.2)]

        XCTAssertFalse(recognizer.shouldConvertClick(contacts: contacts, sampleAge: 0.5))
    }

    func testZeroSizedContactIsIgnored() {
        let contacts = [TouchContact(x: 0.5, y: 0.6, size: 0)]

        XCTAssertFalse(recognizer.shouldConvertClick(contacts: contacts, sampleAge: 0.02))
    }
}

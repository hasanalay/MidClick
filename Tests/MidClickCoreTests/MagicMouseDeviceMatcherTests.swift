import XCTest
@testable import MidClickCore

final class MagicMouseDeviceMatcherTests: XCTestCase {
    func testKnownFirstGenerationProductIDMatches() {
        XCTAssertTrue(
            MagicMouseDeviceMatcher.isMagicMouse(
                productID: 0x030D,
                productName: nil
            )
        )
    }

    func testKnownLightningProductIDMatches() {
        XCTAssertTrue(
            MagicMouseDeviceMatcher.isMagicMouse(
                productID: 0x0269,
                productName: nil
            )
        )
    }

    func testKnownUSBCProductIDMatches() {
        XCTAssertTrue(
            MagicMouseDeviceMatcher.isMagicMouse(
                productID: 0x0323,
                productName: nil
            )
        )
    }

    func testMagicMouseNameMatchesCaseInsensitively() {
        XCTAssertTrue(
            MagicMouseDeviceMatcher.isMagicMouse(
                productID: 0xFFFF,
                productName: "apple magic mouse"
            )
        )
    }

    func testMagicTrackpadIsRejected() {
        XCTAssertFalse(
            MagicMouseDeviceMatcher.isMagicMouse(
                productID: 0xFFFF,
                productName: "Magic Trackpad"
            )
        )
    }

    func testUnknownDeviceIsRejected() {
        XCTAssertFalse(
            MagicMouseDeviceMatcher.isMagicMouse(
                productID: nil,
                productName: nil
            )
        )
    }
}

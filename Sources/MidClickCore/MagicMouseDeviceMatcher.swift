import Foundation

public enum MagicMouseDeviceMatcher {
    public static let knownProductIDs: Set<UInt32> = [
        0x030D,
        0x0269,
        0x0323
    ]

    public static func isMagicMouse(
        productID: UInt32?,
        productName: String?
    ) -> Bool {
        if let productID, knownProductIDs.contains(productID) {
            return true
        }

        return productName?.range(
            of: "Magic Mouse",
            options: .caseInsensitive
        ) != nil
    }
}

import Foundation

public struct PhysicalClickRecognizer: Sendable {
    public var configuration: CenterClickConfiguration

    public init(configuration: CenterClickConfiguration = .init()) {
        self.configuration = configuration
    }

    public func shouldConvertClick(
        trigger: MiddleClickTrigger,
        contacts: [TouchContact],
        sampleAge: TimeInterval
    ) -> Bool {
        guard !trigger.isTap else { return false }
        guard sampleAge >= 0, sampleAge <= configuration.maximumSampleAge else { return false }

        let activeContacts = contacts.filter { $0.size >= configuration.minimumTouchSize }

        switch trigger {
        case .centerClick:
            guard activeContacts.count == 1, let contact = activeContacts.first else { return false }
            return contact.x >= configuration.minimumX && contact.x <= configuration.maximumX
        case .twoFingerClick:
            return activeContacts.count == 2
        case .threeFingerClick:
            return activeContacts.count == 3
        case .twoFingerTap, .threeFingerTap:
            return false
        }
    }
}

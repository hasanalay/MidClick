import Foundation

public struct TouchContact: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let size: Double

    public init(x: Double, y: Double, size: Double) {
        self.x = x
        self.y = y
        self.size = size
    }
}

public struct CenterClickConfiguration: Equatable, Sendable {
    public var minimumX: Double
    public var maximumX: Double
    public var maximumSampleAge: TimeInterval
    public var minimumTouchSize: Double

    public init(
        minimumX: Double = 0.36,
        maximumX: Double = 0.64,
        maximumSampleAge: TimeInterval = 0.18,
        minimumTouchSize: Double = 0.001
    ) {
        precondition(minimumX < maximumX)
        self.minimumX = minimumX
        self.maximumX = maximumX
        self.maximumSampleAge = maximumSampleAge
        self.minimumTouchSize = minimumTouchSize
    }
}

public struct CenterClickRecognizer: Sendable {
    public var configuration: CenterClickConfiguration

    public init(configuration: CenterClickConfiguration = .init()) {
        self.configuration = configuration
    }

    public func shouldConvertClick(
        contacts: [TouchContact],
        sampleAge: TimeInterval
    ) -> Bool {
        guard sampleAge >= 0, sampleAge <= configuration.maximumSampleAge else {
            return false
        }

        let activeContacts = contacts.filter { $0.size >= configuration.minimumTouchSize }
        guard activeContacts.count == 1, let contact = activeContacts.first else {
            return false
        }

        return contact.x >= configuration.minimumX
            && contact.x <= configuration.maximumX
    }
}

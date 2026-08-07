import Foundation

public struct TapGestureConfiguration: Equatable, Sendable {
    public var maximumFingerArrivalDuration: TimeInterval
    public var maximumGestureDuration: TimeInterval
    public var maximumCentroidMovement: Double
    public var minimumTouchSize: Double

    public init(
        maximumFingerArrivalDuration: TimeInterval = 0.12,
        maximumGestureDuration: TimeInterval = 0.25,
        maximumCentroidMovement: Double = 0.04,
        minimumTouchSize: Double = 0.001
    ) {
        self.maximumFingerArrivalDuration = maximumFingerArrivalDuration
        self.maximumGestureDuration = maximumGestureDuration
        self.maximumCentroidMovement = maximumCentroidMovement
        self.minimumTouchSize = minimumTouchSize
    }
}

public struct TapGestureRecognizer: Sendable {
    private struct TrackingState: Sendable {
        let startTime: TimeInterval
        var initialCentroid: (x: Double, y: Double)?
        var reachedRequiredFingerCount: Bool
        var isReleasing: Bool
        var previousFingerCount: Int
    }

    private enum State: Sendable {
        case idle
        case tracking(TrackingState)
        case suppressed
    }

    public var configuration: TapGestureConfiguration
    private var state: State = .idle

    public init(configuration: TapGestureConfiguration = .init()) {
        self.configuration = configuration
    }

    public mutating func processFrame(
        contacts: [TouchContact],
        timestamp: TimeInterval,
        requiredFingerCount: Int
    ) -> Bool {
        precondition(requiredFingerCount >= 2)

        let activeContacts = contacts.filter { $0.size >= configuration.minimumTouchSize }
        let fingerCount = activeContacts.count

        switch state {
        case .idle:
            guard fingerCount > 0 else { return false }
            guard fingerCount <= requiredFingerCount else {
                state = .suppressed
                return false
            }

            var tracking = TrackingState(
                startTime: timestamp,
                initialCentroid: nil,
                reachedRequiredFingerCount: false,
                isReleasing: false,
                previousFingerCount: fingerCount
            )

            if fingerCount == requiredFingerCount {
                tracking.reachedRequiredFingerCount = true
                tracking.initialCentroid = centroid(of: activeContacts)
            }

            state = .tracking(tracking)
            return false

        case .suppressed:
            if fingerCount == 0 {
                state = .idle
            }
            return false

        case .tracking(var tracking):
            let elapsed = timestamp - tracking.startTime
            guard elapsed >= 0, elapsed <= configuration.maximumGestureDuration else {
                state = fingerCount == 0 ? .idle : .suppressed
                return false
            }

            guard fingerCount <= requiredFingerCount else {
                state = .suppressed
                return false
            }

            if !tracking.reachedRequiredFingerCount {
                if fingerCount == 0 {
                    state = .idle
                    return false
                }

                if fingerCount < tracking.previousFingerCount {
                    state = .suppressed
                    return false
                }

                guard elapsed <= configuration.maximumFingerArrivalDuration else {
                    state = .suppressed
                    return false
                }

                if fingerCount == requiredFingerCount {
                    tracking.reachedRequiredFingerCount = true
                    tracking.initialCentroid = centroid(of: activeContacts)
                }

                tracking.previousFingerCount = fingerCount
                state = .tracking(tracking)
                return false
            }

            if fingerCount == 0 {
                state = .idle
                return true
            }

            if tracking.isReleasing {
                guard fingerCount < tracking.previousFingerCount else {
                    state = .suppressed
                    return false
                }
            } else if fingerCount < requiredFingerCount {
                tracking.isReleasing = true
            }

            if fingerCount == requiredFingerCount,
               let initialCentroid = tracking.initialCentroid {
                let currentCentroid = centroid(of: activeContacts)
                let distance = hypot(
                    currentCentroid.x - initialCentroid.x,
                    currentCentroid.y - initialCentroid.y
                )

                guard distance <= configuration.maximumCentroidMovement else {
                    state = .suppressed
                    return false
                }
            }

            tracking.previousFingerCount = fingerCount
            state = .tracking(tracking)
            return false
        }
    }

    public mutating func cancel() {
        state = .suppressed
    }

    public mutating func reset() {
        state = .idle
    }

    private func centroid(of contacts: [TouchContact]) -> (x: Double, y: Double) {
        guard !contacts.isEmpty else { return (0, 0) }
        let sum = contacts.reduce(into: (x: 0.0, y: 0.0)) { partialResult, contact in
            partialResult.x += contact.x
            partialResult.y += contact.y
        }
        let count = Double(contacts.count)
        return (sum.x / count, sum.y / count)
    }
}

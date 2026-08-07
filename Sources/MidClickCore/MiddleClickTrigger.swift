import Foundation

public enum MiddleClickTrigger: String, CaseIterable, Sendable {
    case centerClick
    case twoFingerClick
    case threeFingerClick
    case twoFingerTap
    case threeFingerTap

    public var displayName: String {
        switch self {
        case .centerClick:
            return "Center Click"
        case .twoFingerClick:
            return "Two-Finger Click"
        case .threeFingerClick:
            return "Three-Finger Click"
        case .twoFingerTap:
            return "Two-Finger Tap"
        case .threeFingerTap:
            return "Three-Finger Tap"
        }
    }

    public var isTap: Bool {
        switch self {
        case .twoFingerTap, .threeFingerTap:
            return true
        case .centerClick, .twoFingerClick, .threeFingerClick:
            return false
        }
    }

    public var requiredFingerCount: Int {
        switch self {
        case .centerClick:
            return 1
        case .twoFingerClick, .twoFingerTap:
            return 2
        case .threeFingerClick, .threeFingerTap:
            return 3
        }
    }
}

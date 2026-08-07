import CoreGraphics
import Foundation
import MidClickCore

final class EventTapManager {
    var isEnabled: Bool = true

    var isRunning: Bool {
        eventTap != nil
    }

    private let touchMonitor: MagicTouchMonitor
    private let recognizer: CenterClickRecognizer
    private let emitter: MiddleClickEmitter

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isConvertingCurrentClick = false

    init(
        touchMonitor: MagicTouchMonitor,
        recognizer: CenterClickRecognizer = .init(),
        emitter: MiddleClickEmitter = .init()
    ) {
        self.touchMonitor = touchMonitor
        self.recognizer = recognizer
        self.emitter = emitter
    }

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }

        let eventMask = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let manager = Unmanaged<EventTapManager>
                .fromOpaque(userInfo)
                .takeUnretainedValue()

            return manager.handle(type: type, event: event)
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: userInfo
        ) else {
            return false
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            return false
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if isConvertingCurrentClick {
            if let event = CGEvent(source: nil) {
                emitter.mouseUp(at: event.location)
            }
            isConvertingCurrentClick = false
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }

        runLoopSource = nil
        eventTap = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .leftMouseDown:
            guard isEnabled else {
                return Unmanaged.passUnretained(event)
            }

            let snapshot = touchMonitor.snapshot()
            guard recognizer.shouldConvertClick(
                contacts: snapshot.contacts,
                sampleAge: snapshot.age
            ) else {
                return Unmanaged.passUnretained(event)
            }

            isConvertingCurrentClick = true
            emitter.mouseDown(at: event.location)
            return nil

        case .leftMouseUp:
            guard isConvertingCurrentClick else {
                return Unmanaged.passUnretained(event)
            }

            isConvertingCurrentClick = false
            emitter.mouseUp(at: event.location)
            return nil

        default:
            return Unmanaged.passUnretained(event)
        }
    }
}

import CoreGraphics
import Foundation
import MidClickCore

final class EventTapManager {
    var isEnabled: Bool = true {
        didSet {
            if !isEnabled {
                tapRecognizer.reset()
            }
        }
    }

    var trigger: MiddleClickTrigger = .centerClick {
        didSet {
            if trigger != oldValue {
                tapRecognizer.reset()
            }
        }
    }

    var isRunning: Bool {
        eventTap != nil
    }

    private let touchMonitor: MagicTouchMonitor
    private let physicalRecognizer: PhysicalClickRecognizer
    private let emitter: MiddleClickEmitter

    private var tapRecognizer: TapGestureRecognizer
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isConvertingCurrentClick = false

    init(
        touchMonitor: MagicTouchMonitor,
        physicalRecognizer: PhysicalClickRecognizer = .init(),
        tapRecognizer: TapGestureRecognizer = .init(),
        emitter: MiddleClickEmitter = .init()
    ) {
        self.touchMonitor = touchMonitor
        self.physicalRecognizer = physicalRecognizer
        self.tapRecognizer = tapRecognizer
        self.emitter = emitter
    }

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }

        touchMonitor.setFrameHandler { [weak self] contacts, timestamp in
            DispatchQueue.main.async {
                self?.handleTouchFrame(contacts: contacts, timestamp: timestamp)
            }
        }

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
            touchMonitor.setFrameHandler(nil)
            return false
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            touchMonitor.setFrameHandler(nil)
            return false
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        touchMonitor.setFrameHandler(nil)
        tapRecognizer.reset()

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
            tapRecognizer.cancel()

            guard isEnabled else {
                return Unmanaged.passUnretained(event)
            }

            guard !trigger.isTap else {
                return Unmanaged.passUnretained(event)
            }

            let snapshot = touchMonitor.snapshot()
            guard physicalRecognizer.shouldConvertClick(
                trigger: trigger,
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

    private func handleTouchFrame(contacts: [TouchContact], timestamp: TimeInterval) {
        guard isEnabled, trigger.isTap else {
            tapRecognizer.reset()
            return
        }

        let selectedTrigger = trigger
        let didRecognizeTap = tapRecognizer.processFrame(
            contacts: contacts,
            timestamp: timestamp,
            requiredFingerCount: selectedTrigger.requiredFingerCount
        )

        guard didRecognizeTap, trigger == selectedTrigger, isEnabled else { return }
        guard let event = CGEvent(source: nil) else { return }
        emitter.click(at: event.location)
    }
}

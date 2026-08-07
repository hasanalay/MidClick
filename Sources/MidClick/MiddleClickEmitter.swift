import CoreGraphics

final class MiddleClickEmitter {
    private let source = CGEventSource(stateID: .hidSystemState)

    func mouseDown(at location: CGPoint) {
        post(type: .otherMouseDown, at: location)
    }

    func mouseUp(at location: CGPoint) {
        post(type: .otherMouseUp, at: location)
    }

    func click(at location: CGPoint) {
        mouseDown(at: location)
        mouseUp(at: location)
    }

    private func post(type: CGEventType, at location: CGPoint) {
        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: type,
            mouseCursorPosition: location,
            mouseButton: .center
        ) else {
            return
        }

        event.setIntegerValueField(.mouseEventButtonNumber, value: 2)
        event.post(tap: .cghidEventTap)
    }
}

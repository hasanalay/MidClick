import CoreFoundation
import Foundation
import MidClickCore
import Darwin

private struct MTPoint {
    var x: Float
    var y: Float
}

private struct MTReadout {
    var position: MTPoint
    var velocity: MTPoint
}

private struct MTTouch {
    var frame: Int32
    var timestamp: Double
    var identifier: Int32
    var state: Int32
    var unknown1: Int32
    var unknown2: Int32
    var normalized: MTReadout
    var size: Float
    var unknown3: Int32
    var angle: Float
    var majorAxis: Float
    var minorAxis: Float
    var unknown4: MTReadout
    var unknown5a: Int32
    var unknown5b: Int32
    var unknown6: Float
}

private typealias MTDeviceRef = UnsafeMutableRawPointer
private typealias MTContactCallback = @convention(c) (
    Int32,
    UnsafeMutableRawPointer?,
    Int32,
    Double,
    Int32
) -> Int32
private typealias MTDeviceCreateList = @convention(c) () -> Unmanaged<CFArray>
private typealias MTRegisterContactFrameCallback = @convention(c) (MTDeviceRef, MTContactCallback) -> Void
private typealias MTUnregisterContactFrameCallback = @convention(c) (MTDeviceRef, MTContactCallback) -> Void
private typealias MTDeviceStart = @convention(c) (MTDeviceRef, Int32) -> Void
private typealias MTDeviceStop = @convention(c) (MTDeviceRef) -> Void

private let midClickContactCallback: MTContactCallback = { _, rawTouches, count, _, _ in
    MagicTouchMonitor.shared.consume(rawTouches: rawTouches, count: count)
    return 0
}

final class MagicTouchMonitor {
    enum Status: Equatable {
        case stopped
        case active(deviceCount: Int)
        case unavailable(String)
    }

    struct Snapshot {
        let contacts: [TouchContact]
        let age: TimeInterval
    }

    static let shared = MagicTouchMonitor()

    private let lock = NSLock()
    private var contacts: [TouchContact] = []
    private var lastFrameUptime: TimeInterval = 0

    private var frameworkHandle: UnsafeMutableRawPointer?
    private var deviceList: CFArray?
    private var devices: [MTDeviceRef] = []
    private var unregisterCallback: MTUnregisterContactFrameCallback?
    private var stopDevice: MTDeviceStop?

    private(set) var status: Status = .stopped

    private init() {}

    @discardableResult
    func start() -> Bool {
        guard case .stopped = status else {
            if case .active = status { return true }
            return false
        }

        let path = "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport"
        guard let handle = dlopen(path, RTLD_NOW) else {
            status = .unavailable("MultitouchSupport.framework could not be loaded")
            return false
        }

        frameworkHandle = handle

        guard
            let createList: MTDeviceCreateList = symbol(named: "MTDeviceCreateList", in: handle),
            let register: MTRegisterContactFrameCallback = symbol(named: "MTRegisterContactFrameCallback", in: handle),
            let startDevice: MTDeviceStart = symbol(named: "MTDeviceStart", in: handle)
        else {
            status = .unavailable("Required multitouch symbols are unavailable")
            dlclose(handle)
            frameworkHandle = nil
            return false
        }

        unregisterCallback = symbol(named: "MTUnregisterContactFrameCallback", in: handle)
        stopDevice = symbol(named: "MTDeviceStop", in: handle)

        let list = createList().takeRetainedValue()
        deviceList = list

        let count = CFArrayGetCount(list)
        guard count > 0 else {
            status = .unavailable("No multitouch devices were found")
            return false
        }

        for index in 0..<count {
            guard let rawDevice = CFArrayGetValueAtIndex(list, index) else { continue }
            let device = UnsafeMutableRawPointer(mutating: rawDevice)
            register(device, midClickContactCallback)
            startDevice(device, 0)
            devices.append(device)
        }

        guard !devices.isEmpty else {
            status = .unavailable("No usable multitouch devices were found")
            return false
        }

        status = .active(deviceCount: devices.count)
        return true
    }

    func stop() {
        for device in devices {
            unregisterCallback?(device, midClickContactCallback)
            stopDevice?(device)
        }

        devices.removeAll()
        deviceList = nil

        if let frameworkHandle {
            dlclose(frameworkHandle)
            self.frameworkHandle = nil
        }

        lock.lock()
        contacts = []
        lastFrameUptime = 0
        lock.unlock()

        status = .stopped
    }

    func snapshot() -> Snapshot {
        lock.lock()
        defer { lock.unlock() }

        let age: TimeInterval
        if lastFrameUptime == 0 {
            age = .infinity
        } else {
            age = max(0, ProcessInfo.processInfo.systemUptime - lastFrameUptime)
        }

        return Snapshot(contacts: contacts, age: age)
    }

    fileprivate func consume(rawTouches: UnsafeMutableRawPointer?, count: Int32) {
        let newContacts: [TouchContact]

        if let rawTouches, count > 0 {
            let touches = rawTouches.bindMemory(to: MTTouch.self, capacity: Int(count))
            let buffer = UnsafeBufferPointer(start: touches, count: Int(count))
            newContacts = buffer.map { touch in
                TouchContact(
                    x: Double(touch.normalized.position.x),
                    y: Double(touch.normalized.position.y),
                    size: Double(touch.size)
                )
            }
        } else {
            newContacts = []
        }

        lock.lock()
        contacts = newContacts
        lastFrameUptime = ProcessInfo.processInfo.systemUptime
        lock.unlock()
    }

    private func symbol<T>(named name: String, in handle: UnsafeMutableRawPointer) -> T? {
        guard let pointer = dlsym(handle, name) else { return nil }
        return unsafeBitCast(pointer, to: T.self)
    }
}

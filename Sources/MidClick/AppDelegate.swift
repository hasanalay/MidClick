import AppKit
import MidClickCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let touchMonitor = MagicTouchMonitor.shared
    private lazy var eventTapManager = EventTapManager(touchMonitor: touchMonitor)

    private var statusItem: NSStatusItem?
    private var enabledMenuItem: NSMenuItem?
    private var accessibilityMenuItem: NSMenuItem?
    private var touchStatusMenuItem: NSMenuItem?
    private var statusTimer: Timer?

    private let enabledDefaultsKey = "middleClickEnabled"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if UserDefaults.standard.object(forKey: enabledDefaultsKey) == nil {
            UserDefaults.standard.set(true, forKey: enabledDefaultsKey)
        }
        eventTapManager.isEnabled = UserDefaults.standard.bool(forKey: enabledDefaultsKey)

        configureMenuBar()
        touchMonitor.start()

        if AccessibilityPermission.isGranted {
            _ = eventTapManager.start()
        } else {
            _ = AccessibilityPermission.request()
        }

        refreshMenuState()
        statusTimer = Timer.scheduledTimer(
            timeInterval: 1.5,
            target: self,
            selector: #selector(handleStatusTimer(_:)),
            userInfo: nil,
            repeats: true
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusTimer?.invalidate()
        eventTapManager.stop()
        touchMonitor.stop()
    }

    private func configureMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "computermouse.fill",
            accessibilityDescription: "MidClick"
        )

        let menu = NSMenu()

        let enabled = NSMenuItem(
            title: "Middle Click Enabled",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabled.target = self
        menu.addItem(enabled)
        enabledMenuItem = enabled

        menu.addItem(.separator())

        let accessibility = NSMenuItem(
            title: "Accessibility",
            action: #selector(requestAccessibilityPermission),
            keyEquivalent: ""
        )
        accessibility.target = self
        menu.addItem(accessibility)
        accessibilityMenuItem = accessibility

        let touchStatus = NSMenuItem(title: "Touch Input", action: nil, keyEquivalent: "")
        touchStatus.isEnabled = false
        menu.addItem(touchStatus)
        touchStatusMenuItem = touchStatus

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit MidClick", action: #selector(quitApplication), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
    }

    @objc
    private func handleStatusTimer(_ timer: Timer) {
        refreshRuntimeState()
    }

    private func refreshRuntimeState() {
        if AccessibilityPermission.isGranted, !eventTapManager.isRunning {
            _ = eventTapManager.start()
        }
        refreshMenuState()
    }

    private func refreshMenuState() {
        enabledMenuItem?.state = eventTapManager.isEnabled ? .on : .off

        if AccessibilityPermission.isGranted {
            accessibilityMenuItem?.title = eventTapManager.isRunning
                ? "Accessibility: Granted"
                : "Accessibility: Granted (Restart Input)"
        } else {
            accessibilityMenuItem?.title = "Accessibility: Required…"
        }

        switch touchMonitor.status {
        case .stopped:
            touchStatusMenuItem?.title = "Touch Input: Stopped"
        case .active(let deviceCount):
            touchStatusMenuItem?.title = "Touch Input: Active (\(deviceCount))"
        case .unavailable(let reason):
            touchStatusMenuItem?.title = "Touch Input: Unavailable — \(reason)"
        }
    }

    @objc
    private func toggleEnabled() {
        eventTapManager.isEnabled.toggle()
        UserDefaults.standard.set(eventTapManager.isEnabled, forKey: enabledDefaultsKey)
        refreshMenuState()
    }

    @objc
    private func requestAccessibilityPermission() {
        if AccessibilityPermission.isGranted {
            if !eventTapManager.isRunning {
                _ = eventTapManager.start()
            }
        } else {
            _ = AccessibilityPermission.request()
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
        refreshMenuState()
    }

    @objc
    private func quitApplication() {
        NSApp.terminate(nil)
    }
}

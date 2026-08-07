import AppKit

@MainActor
func runApplication() {
    let appDelegate = AppDelegate()
    let application = NSApplication.shared
    application.delegate = appDelegate
    application.run()
}

MainActor.assumeIsolated {
    runApplication()
}

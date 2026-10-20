import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(_ notification: Notification) {
		NSApp.activate(ignoringOtherApps: true)
	}

	// File ▸ New abrirá el asistente Device Setup (docs/20 §3.4); hasta entonces no se crean documentos vacíos.
	func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }
}

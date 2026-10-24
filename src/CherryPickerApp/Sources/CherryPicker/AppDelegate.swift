import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(_ notification: Notification) {
		Self.migrateDefaults()
		NSApp.activate(ignoringOtherApps: true)
	}

	/// Una vez: copia las preferencias guardadas con el identificador anterior (salida MIDI, canal y nota de audición,
	/// Categories del usuario, campos de Copy Fields…) al de Midnamer (D-011). Open Recent no se puede traer.
	private static func migrateDefaults() {
		let d = UserDefaults.standard
		guard !d.bool(forKey: "migratedFromCherryPicker") else { return }
		for (key, value) in d.persistentDomain(forName: "local.cherrypicker.app") ?? [:] where d.object(forKey: key) == nil {
			d.set(value, forKey: key)
		}
		d.set(true, forKey: "migratedFromCherryPicker")
	}

	// File ▸ New abrirá el asistente Device Setup (docs/20 §3.4); hasta entonces no se crean documentos vacíos.
	func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }
}

// Menú principal (nib MainMenu, docs/20 §3.4), sin las entradas fuera de alcance (Send Feedback, updates, Donate)
// y con el menú Window estándar. New queda para el asistente Device Setup.
import AppKit

enum MainMenu {
	static func build() -> NSMenu {
		let main = NSMenu()

		let app = submenu(main, "CherryPicker")
		app.addItem(withTitle: "About CherryPicker",
		            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
		app.addItem(.separator())
		app.addItem(withTitle: "Hide CherryPicker", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
		let others = app.addItem(withTitle: "Hide Others",
		                         action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
		others.keyEquivalentModifierMask = [.command, .option]
		app.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
		app.addItem(.separator())
		app.addItem(withTitle: "Quit CherryPicker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

		let file = submenu(main, "File")
		file.addItem(withTitle: "Open…", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o")
		let recent = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
		let recentMenu = NSMenu(title: "Open Recent")
		recentMenu.addItem(withTitle: "Clear Menu",
		                   action: #selector(NSDocumentController.clearRecentDocuments(_:)), keyEquivalent: "")
		recent.submenu = recentMenu
		file.addItem(recent)
		file.addItem(.separator())
		file.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
		file.addItem(withTitle: "Save", action: #selector(NSDocument.save(_:)), keyEquivalent: "s")
		let saveAs = file.addItem(withTitle: "Save As…", action: #selector(NSDocument.saveAs(_:)), keyEquivalent: "s")
		saveAs.keyEquivalentModifierMask = [.command, .shift]
		file.addItem(withTitle: "Revert To Saved",
		             action: #selector(NSDocument.revertToSaved(_:)), keyEquivalent: "r")

		let edit = submenu(main, "Edit")
		edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
		let redo = edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
		redo.keyEquivalentModifierMask = [.command, .shift]
		edit.addItem(.separator())
		edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
		edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
		edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
		edit.addItem(withTitle: "Delete", action: #selector(NSText.delete(_:)), keyEquivalent: "")
		edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

		let window = submenu(main, "Window")
		window.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
		window.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
		NSApplication.shared.windowsMenu = window

		let help = submenu(main, "Help")
		NSApplication.shared.helpMenu = help

		return main
	}

	private static func submenu(_ main: NSMenu, _ title: String) -> NSMenu {
		let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
		let menu = NSMenu(title: title)
		item.submenu = menu
		main.addItem(item)
		return menu
	}
}

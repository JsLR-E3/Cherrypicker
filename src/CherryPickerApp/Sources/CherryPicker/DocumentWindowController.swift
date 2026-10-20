// Ventana de documento (nib MainWindow): pestañas en el orden del original, sin Note Lists (D-005),
// y en el pie el botón «Preview».
import AppKit

final class DocumentWindowController: NSWindowController {
	init(document: MidnamDocument) {
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 760, height: 520),
		                      styleMask: [.titled, .closable, .miniaturizable, .resizable],
		                      backing: .buffered, defer: false)
		window.minSize = NSSize(width: 560, height: 360)
		super.init(window: window)
		window.contentViewController = MainTabsViewController(document: document)
		// Al asignar el controlador la ventana toma el tamaño mínimo de su contenido: se vuelve a fijar.
		window.setContentSize(NSSize(width: 760, height: 520))
		window.center()
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }
}

final class MainTabsViewController: NSViewController {
	private let document: MidnamDocument

	init(document: MidnamDocument) {
		self.document = document
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	override func loadView() {
		let tabs = NSTabView()
		for title in ["MIDI", "Device", "Patch Banks", "Controllers", "Categories"] {
			let item = NSTabViewItem(identifier: title)
			item.label = title
			if title == "Patch Banks" {
				let vc = PatchBanksViewController(document: document)
				addChild(vc)
				item.view = vc.view
			} else {
				item.view = Self.pending()
			}
			tabs.addTabViewItem(item)
		}
		tabs.selectTabViewItem(withIdentifier: "Patch Banks")

		let preview = NSButton(title: "Preview", target: self, action: #selector(showPreview(_:)))

		let root = NSView()
		for v in [tabs, preview] as [NSView] {
			v.translatesAutoresizingMaskIntoConstraints = false
			root.addSubview(v)
		}
		NSLayoutConstraint.activate([
			tabs.topAnchor.constraint(equalTo: root.topAnchor, constant: 12),
			tabs.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
			tabs.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
			preview.topAnchor.constraint(equalTo: tabs.bottomAnchor, constant: 8),
			preview.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
			preview.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -12),
		])
		view = root
	}

	/// Pestaña aún sin hacer.
	private static func pending() -> NSView {
		let v = NSView()
		let label = NSTextField(labelWithString: "Not implemented yet")
		label.textColor = .secondaryLabelColor
		label.translatesAutoresizingMaskIntoConstraints = false
		v.addSubview(label)
		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: v.centerXAnchor),
			label.centerYAnchor.constraint(equalTo: v.centerYAnchor),
		])
		return v
	}

	@objc private func showPreview(_ sender: Any?) {
		PreviewWindowController.show(text: document.previewText(), title: document.displayName)
	}
}

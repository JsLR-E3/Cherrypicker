// Ventana de documento (nib MainWindow): pestañas en el orden del original, sin Note Lists (D-005),
// y arriba a la derecha el botón «Preview» (sin «Save Format» ni «XML Filters...», P1).
import AppKit

final class DocumentWindowController: NSWindowController {
	init(document: MidnamDocument) {
		// Alta y estrecha, como el original (EXP-009), con anchura para las columnas.
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 760),
		                      styleMask: [.titled, .closable, .miniaturizable, .resizable],
		                      backing: .buffered, defer: false)
		window.minSize = NSSize(width: 480, height: 400)
		super.init(window: window)
		window.contentViewController = MainTabsViewController(document: document)
		// Al asignar el controlador la ventana toma el tamaño mínimo de su contenido: se vuelve a fijar.
		window.setContentSize(NSSize(width: 560, height: 760))
		placeWindow(window)
		for name in [NSWindow.didMoveNotification, NSWindow.didEndLiveResizeNotification] {
			NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { n in
				guard let w = n.object as? NSWindow else { return }
				UserDefaults.standard.set(NSStringFromRect(w.frame), forKey: Self.frameKey)
			}
		}
	}

	/// Dónde se dejó la última ventana de documento (pantalla incluida; pedido por el usuario, dos pantallas).
	private static let frameKey = "documentWindowFrame"

	/// En el sitio guardado si esa pantalla sigue conectada (en cascada si ya hay otro documento abierto); si no, centrada.
	private func placeWindow(_ window: NSWindow) {
		guard let s = UserDefaults.standard.string(forKey: Self.frameKey) else {
			window.center()
			return
		}
		let frame = NSRectFromString(s)
		guard frame.width > 0, NSScreen.screens.contains(where: { $0.visibleFrame.intersects(frame) }) else {
			window.center()
			return
		}
		window.setFrame(frame, display: false)
		let others = NSApp.windows.filter { $0 !== window && $0.isVisible && $0.windowController is DocumentWindowController }
		if let last = others.last {
			window.setFrameTopLeftPoint(last.cascadeTopLeft(from: NSPoint(x: last.frame.minX, y: last.frame.maxY)))
		}
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
			let vc: NSViewController? = switch title {
			case "Patch Banks": PatchBanksViewController(document: document)
			case "Device": DeviceViewController(document: document)
			case "MIDI": MIDIViewController(document: document)
			case "Categories": CategoriesViewController(document: document)
			default: nil
			}
			if let vc {
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
			preview.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
			preview.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
			tabs.topAnchor.constraint(equalTo: preview.bottomAnchor, constant: 6),
			tabs.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
			tabs.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
			tabs.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -12),
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

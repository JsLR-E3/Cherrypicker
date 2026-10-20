// Ventana «Preview» (nib Preview): el XML exacto que se escribirá al guardar.
import AppKit

final class PreviewWindowController: NSWindowController {
	private static var open: [PreviewWindowController] = []

	static func show(text: String, title: String) {
		let wc = PreviewWindowController(text: text, title: title)
		open.append(wc)
		wc.showWindow(nil)
	}

	private init(text: String, title: String) {
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 560),
		                      styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
		window.title = "Preview — \(title)"
		window.isReleasedWhenClosed = false
		super.init(window: window)

		let scroll = NSTextView.scrollableTextView()
		let tv = scroll.documentView as! NSTextView
		tv.isEditable = false
		tv.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
		tv.string = text
		window.contentView = scroll
		window.center()
		NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window,
		                                       queue: .main) { [weak self] _ in
			PreviewWindowController.open.removeAll { $0 === self }
		}
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }
}

// Help ▸ Midnamer Help (T-036): la guía del README.md (copiada en Resources por tools/empaquetar_app.sh), en una
// ventana de solo lectura. Los bloques los parte HelpText; aquí se les da formato.
import AppKit
import CherryPickerCore

final class HelpWindowController: NSWindowController {
	private static var shared: HelpWindowController?

	@objc static func show(_ sender: Any?) {
		let wc = shared ?? HelpWindowController()
		shared = wc
		wc.showWindow(nil)
	}

	private init() {
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 720),
		                      styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
		window.title = "Midnamer Help"
		window.isReleasedWhenClosed = false
		window.setFrameAutosaveName("Help")
		super.init(window: window)

		let scroll = NSTextView.scrollableTextView()
		let tv = scroll.documentView as! NSTextView
		tv.isEditable = false
		tv.textContainerInset = NSSize(width: 20, height: 16)
		tv.textStorage?.setAttributedString(Self.render(Self.loadGuide()))
		window.contentView = scroll
		if window.frame.origin == .zero { window.center() }
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	private static func loadGuide() -> String {
		guard let url = Bundle.main.url(forResource: "README", withExtension: "md"),
		      let text = try? String(contentsOf: url, encoding: .utf8)
		else { return "## Help not found\nThis copy of Midnamer was built without its guide (README.md)." }
		return HelpText.section(of: text)
	}

	private static func render(_ markdown: String) -> NSAttributedString {
		let out = NSMutableAttributedString()
		let body = NSFont.systemFont(ofSize: 13)
		for block in HelpText.blocks(markdown) {
			let para = NSMutableParagraphStyle()
			let text: String
			var font = body
			switch block {
			case .heading(let level, let t):
				text = t
				font = .boldSystemFont(ofSize: level <= 2 ? 18 : 14)
				para.paragraphSpacingBefore = level <= 2 ? 14 : 8
				para.paragraphSpacing = 4
			case .paragraph(let t):
				text = t
				para.paragraphSpacing = 8
			case .item(let marker, let t):
				text = marker + "\t" + t
				para.headIndent = 22
				para.tabStops = [NSTextTab(textAlignment: .left, location: 22)]
				para.firstLineHeadIndent = marker == "•" ? 8 : 0
				para.paragraphSpacing = 4
			}
			let line = inline(text, font: font)
			line.append(NSAttributedString(string: "\n"))
			line.addAttribute(.paragraphStyle, value: para, range: NSRange(location: 0, length: line.length))
			out.append(line)
		}
		return out
	}

	/// **negrita**, *cursiva* y `código` con el formato en línea de Foundation.
	private static func inline(_ text: String, font: NSFont) -> NSMutableAttributedString {
		let parsed = (try? AttributedString(markdown: text,
		                                    options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
			?? AttributedString(text)
		let out = NSMutableAttributedString()
		for run in parsed.runs {
			var f = font
			let intent = run.inlinePresentationIntent ?? []
			if intent.contains(.code) {
				f = .monospacedSystemFont(ofSize: font.pointSize - 1, weight: .regular)
			} else if intent.contains(.stronglyEmphasized) {
				f = NSFontManager.shared.convert(f, toHaveTrait: .boldFontMask)
			}
			if intent.contains(.emphasized) { f = NSFontManager.shared.convert(f, toHaveTrait: .italicFontMask) }
			out.append(NSAttributedString(string: String(parsed[run.range].characters),
			                              attributes: [.font: f, .foregroundColor: NSColor.labelColor]))
		}
		return out
	}
}

// Documento .midnam: se lee y se escribe con MidnamKit, sin pérdidas (lo que no se edita se reescribe igual).
import AppKit
import MidnamKit

@objc(MidnamDocument)
final class MidnamDocument: NSDocument {
	static let typeName = "org.midi.midnam"

	private(set) var file: XMLDocumentFile?
	private(set) var model: MIDINameDocument?

	// Nada se guarda sin que el usuario lo pida (los .midnam del usuario no se tocan solos).
	override class var autosavesInPlace: Bool { false }

	override func makeWindowControllers() {
		addWindowController(DocumentWindowController(document: self))
	}

	override func read(from data: Data, ofType typeName: String) throws {
		guard let text = String(data: data, encoding: .utf8) else {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadInapplicableStringEncodingError)
		}
		let f = try XMLReader.parse(text)
		model = try MIDINameDocument(element: f.root)
		file = f
	}

	override func data(ofType typeName: String) throws -> Data {
		guard var f = file, let m = model else {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError)
		}
		f.root = m.element
		return Data(XMLWriter.write(f).utf8)
	}

	/// Texto exacto que se escribiría al guardar (ventana Preview).
	func previewText() -> String {
		(try? data(ofType: Self.typeName)).map { String(decoding: $0, as: UTF8.self) } ?? ""
	}
}

/// macOS no tiene un tipo propio para .midnam (lo asocia a texto plano), así que se reconoce por la extensión.
final class MidnamDocumentController: NSDocumentController, NSOpenSavePanelDelegate {
	override func typeForContents(of url: URL) throws -> String {
		url.pathExtension.lowercased() == "midnam" ? MidnamDocument.typeName : try super.typeForContents(of: url)
	}

	override func runModalOpenPanel(_ openPanel: NSOpenPanel, forTypes types: [String]?) -> Int {
		openPanel.delegate = self
		return super.runModalOpenPanel(openPanel, forTypes: nil)
	}

	func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
		url.hasDirectoryPath || url.pathExtension.lowercased() == "midnam"
	}
}

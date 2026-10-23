// Documento .midnam: se lee y se escribe con MidnamKit, sin pérdidas (lo que no se edita se reescribe igual).
import AppKit
import CherryPickerCore
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

	static let modelDidChange = Notification.Name("MidnamDocumentModelDidChange")

	/// Aplica un cambio al modelo con deshacer (copia del modelo anterior; el modelo es un valor). Si `change` lanza un
	/// error, el documento no cambia.
	func edit(_ actionName: String, _ change: (inout MIDINameDocument) throws -> Void) throws {
		guard var m = model else { return }
		try change(&m)
		replaceModel(with: m, actionName: actionName)
	}

	private func replaceModel(with new: MIDINameDocument, actionName: String) {
		guard let old = model, old != new else { return }
		model = new
		undoManager?.registerUndo(withTarget: self) { $0.replaceModel(with: old, actionName: actionName) }
		undoManager?.setActionName(actionName)
		NotificationCenter.default.post(name: Self.modelDidChange, object: self)
	}

	/// Ajustes de audición (pestaña MIDI), por fabricante y modelo del primer dispositivo del fichero.
	lazy var audition: AuditionSettings = {
		let m = model?.masterDeviceNames.first
		return AuditionSettings(manufacturer: m?.manufacturer ?? "", model: m?.models.first ?? "")
	}()

	/// «Audition Ch» del banco: el elegido en Device para su Channel Set o, si no, el más bajo del Channel Set.
	func auditionChannel(for ref: BankRef) -> Int? {
		guard let m = model else { return nil }
		if let set = m.channelSetName(ref), let c = audition.auditionChannel(channelSet: set) { return c }
		return m.defaultAuditionChannel(ref)
	}

	/// Envía el patch al «Device Out» si «Enable MIDI» está activo (D-002: solo CC0/CC32 y Program Change).
	func audition(_ patch: PatchRow, in ref: BankRef) {
		guard audition.enabled, let dest = audition.destination, let ch = auditionChannel(for: ref) else { return }
		do {
			let msgs = try auditionMessages(bankSelect0: patch.bankSelect0, bankSelect32: patch.bankSelect32,
			                                program: patch.program, channel: ch)
			try MIDIOut.shared.send(msgs, to: dest)
		} catch {
			NSSound.beep()
		}
	}

	/// Documento nuevo sin guardar (asistente Device Setup): queda marcado como modificado para que pida guardarlo.
	static func openUntitled(text: String) throws {
		let controller = NSDocumentController.shared
		guard let doc = try controller.makeUntitledDocument(ofType: typeName) as? MidnamDocument else { return }
		try doc.read(from: Data(text.utf8), ofType: typeName)
		doc.updateChangeCount(.changeDone)
		controller.addDocument(doc)
		doc.makeWindowControllers()
		doc.showWindows()
	}

	/// File ▸ Install in DP… (T-024, P3): hoja con confirmación; al terminar, qué se hizo y cómo deshacerlo.
	@objc func installInDP(_ sender: Any?) {
		guard let w = windowControllers.first(where: { $0 is DocumentWindowController })?.window else { return }
		let sheet = InstallSheet(document: self)
		sheet.begin(on: w) { ok in
			guard ok else { return }
			let a = NSAlert()
			a.messageText = "Installed in Digital Performer"
			a.informativeText = sheet.report
			a.beginSheetModal(for: w)
		}
	}

	/// Texto exacto que se escribiría al guardar (ventana Preview).
	func previewText() -> String {
		(try? data(ofType: Self.typeName)).map { String(decoding: $0, as: UTF8.self) } ?? ""
	}
}

/// macOS no tiene un tipo propio para .midnam (lo asocia a texto plano), así que se reconoce por la extensión.
final class MidnamDocumentController: NSDocumentController, NSOpenSavePanelDelegate {
	/// File ▸ New abre el asistente Device Setup (T-023).
	override func newDocument(_ sender: Any?) { SetupWizardController.show() }

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

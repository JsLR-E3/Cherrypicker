// Hojas de la ventana Patch Names (nibs CPAddPatchSheet y CPRenumberSheet; textos literales, docs/20 §3.3).
import AppKit
import CherryPickerCore

/// «New Patches» (CPAddPatchSheet): con + crea `Quantity` patches sin nombre; al pegar o soltar texto, los nombres
/// salen del texto según el delimitador y la cantidad no se edita.
final class NewPatchesSheet: SheetController, NSTextFieldDelegate {
	let startAt = SheetController.field("0", width: 50)
	let startAscii = SheetController.field("001", width: 70)
	let quantity = SheetController.field("1", width: 50)
	let useBankSelects = NSButton(checkboxWithTitle: "Set Bank Selects to Bank values", target: nil, action: nil)
	let delimiter = NSPopUpButton()
	private let text: String?

	var onCommit: ((_ names: [String], _ startAt: Int, _ startAscii: String, _ useBankSelects: Bool) throws -> Void)?

	/// `text`: lo pegado o soltado; nil con +.
	init(text: String?) {
		self.text = text
		for d in PatchDelimiter.allCases { delimiter.addItem(withTitle: d.title) }
		// Valor por defecto de la casilla sin contrastar con el original (deducido).
		useBankSelects.state = .on
		super.init(title: "New Patches", rows: [
			[Self.label("Start At:"), startAt, Self.label("Start Ascii"), startAscii],
			[Self.label("Quantity"), quantity],
			[useBankSelects],
			[Self.label("Patch Delimiter"), delimiter],
		], okTitle: "OK")
		startAt.toolTip = "Program Change number of the first new patch (0–127)"
		startAscii.toolTip = "Label of the first new patch; following patches count up from it"
		quantity.delegate = self
		delimiter.target = self
		delimiter.action = #selector(delimiterChanged(_:))
		if text == nil {
			delimiter.isEnabled = false
		} else {
			quantity.isEditable = false
			quantity.isEnabled = false
			// Si el texto tiene varias líneas, se empieza por End of line; si no, por la primera opción que dé nombres.
			if let d = PatchDelimiter.allCases.first(where: { $0.names(in: text!).count > 1 }) {
				delimiter.selectItem(at: PatchDelimiter.allCases.firstIndex(of: d)!)
			}
		}
		validate()
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	private var selectedDelimiter: PatchDelimiter { PatchDelimiter.allCases[max(0, delimiter.indexOfSelectedItem)] }

	private var names: [String] {
		if let text { return selectedDelimiter.names(in: text) }
		return Array(repeating: "", count: Int(quantity.stringValue.trimmingCharacters(in: .whitespaces)) ?? 0)
	}

	@objc private func delimiterChanged(_ sender: Any?) { validate() }

	func controlTextDidChange(_ obj: Notification) { validate() }

	private func validate() {
		let n = names.count
		if text != nil { quantity.stringValue = String(n) }
		okButton.isEnabled = (1...128).contains(n)
	}

	override func commit() throws {
		let start = startAt.stringValue.trimmingCharacters(in: .whitespaces)
		guard let s = Int(start) else { throw PatchEditError.invalidProgram(start) }
		try onCommit?(names, s, startAscii.stringValue, useBankSelects.state == .on)
	}
}

/// «Renumber Patches» (CPRenumberSheet): Program Change y Ascii desde los valores dados, en todos o en los
/// seleccionados.
final class RenumberSheet: SheetController {
	let midiStart = SheetController.field("0", width: 50)
	let displayStart = SheetController.field("001", width: 70)
	let all = NSButton(radioButtonWithTitle: "All", target: nil, action: nil)
	let selection = NSButton(radioButtonWithTitle: "Selection", target: nil, action: nil)

	var onCommit: ((_ midiStart: Int, _ displayStart: String, _ onlySelection: Bool) throws -> Void)?

	init(hasSelection: Bool) {
		super.init(title: "Renumber Patches", rows: [
			[Self.label("MIDI starts at:"), midiStart],
			[Self.label("Display starts at:"), displayStart],
			[all], [selection],
		], okTitle: "OK")
		for b in [all, selection] {
			b.target = self
			b.action = #selector(radioChanged(_:))
		}
		selection.isEnabled = hasSelection
		all.state = .on
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	@objc private func radioChanged(_ sender: NSButton) {
		all.state = sender === all ? .on : .off
		selection.state = sender === selection ? .on : .off
	}

	override func commit() throws {
		let start = midiStart.stringValue.trimmingCharacters(in: .whitespaces)
		guard let s = Int(start) else { throw PatchEditError.invalidProgram(start) }
		try onCommit?(s, displayStart.stringValue, selection.state == .on)
	}
}

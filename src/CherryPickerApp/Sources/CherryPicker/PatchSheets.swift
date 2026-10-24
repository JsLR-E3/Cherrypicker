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

/// «Copy Fields To Clipboard» (CPPatchExport, CPCopySheet; T-027): campos, su orden (arrastrando en «Field Order»),
/// delimitador, «Quote Names», «Print Bank Name» y «TextEdit Export». [PROPUESTA P19] «All» / «Selection», como en
/// Renumber. Los ajustes se recuerdan.
final class CopyFieldsSheet: SheetController, NSTableViewDataSource, NSTableViewDelegate {
	private static let defaultsKey = "copyFields"
	private static let rowType = NSPasteboard.PasteboardType("local.midnamer.copyfield")

	private let checks = PatchExport.Field.allCases.map { NSButton(checkboxWithTitle: $0.title, target: nil, action: nil) }
	private let orderTable = NSTableView()
	private let delimiter = NSPopUpButton()
	private let quoteNames = NSButton(checkboxWithTitle: "Quote Names", target: nil, action: nil)
	private let printBankName = NSButton(checkboxWithTitle: "Print Bank Name", target: nil, action: nil)
	private let textEdit = NSButton(checkboxWithTitle: "TextEdit Export", target: nil, action: nil)
	private let all = NSButton(radioButtonWithTitle: "All", target: nil, action: nil)
	private let selection = NSButton(radioButtonWithTitle: "Selection", target: nil, action: nil)
	/// Los cuatro campos en el orden elegido; se copian los marcados.
	private var order: [PatchExport.Field]

	var onCommit: ((_ export: PatchExport, _ toTextEdit: Bool, _ onlySelection: Bool) throws -> Void)?

	private struct Saved: Codable {
		var order: [PatchExport.Field]
		var checked: [PatchExport.Field]
		var delimiter: PatchExport.Delimiter
		var quoteNames, printBankName, textEdit: Bool
	}

	init(hasSelection: Bool) {
		let saved = Self.loadSaved()
		order = Self.fullOrder(saved?.order ?? [])
		let scroll = NSScrollView()
		scroll.documentView = orderTable
		var rows: [[NSView]] = checks.map { [$0] }
		rows += [[Self.label("Field Order (Drag to reorder)")], [scroll], [Self.label("Delimiter"), delimiter],
		         [quoteNames], [printBankName], [textEdit], [all], [selection]]
		super.init(title: "Copy Fields To Clipboard", rows: rows, okTitle: "OK")
		// Fuera del init principal: con -O, Swift 6.2 se cuelga compilándolo todo junto (EXP-026).
		setUp(saved: saved, scroll: scroll, hasSelection: hasSelection)
	}

	private static func loadSaved() -> Saved? {
		UserDefaults.standard.data(forKey: defaultsKey).flatMap { try? JSONDecoder().decode(Saved.self, from: $0) }
	}

	/// El orden guardado, completado con los campos que falten.
	private static func fullOrder(_ saved: [PatchExport.Field]) -> [PatchExport.Field] {
		saved + PatchExport.Field.allCases.filter { !saved.contains($0) }
	}

	private func setUp(saved: Saved?, scroll: NSScrollView, hasSelection: Bool) {
		let d = PatchExport.default
		for x in PatchExport.Delimiter.allCases { delimiter.addItem(withTitle: x.title) }
		delimiter.selectItem(withTitle: (saved?.delimiter ?? d.delimiter).title)
		scroll.borderType = .bezelBorder
		scroll.hasVerticalScroller = false
		scroll.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			scroll.widthAnchor.constraint(equalToConstant: 200),
			scroll.heightAnchor.constraint(equalToConstant: 4 * 20 + 4),
		])
		let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("field"))
		col.resizingMask = .autoresizingMask
		orderTable.addTableColumn(col)
		orderTable.headerView = nil
		orderTable.rowHeight = 18
		orderTable.dataSource = self
		orderTable.delegate = self
		orderTable.registerForDraggedTypes([Self.rowType])
		let checked = saved?.checked ?? d.fields
		for (i, f) in PatchExport.Field.allCases.enumerated() {
			checks[i].state = checked.contains(f) ? .on : .off
			checks[i].target = self
			checks[i].action = #selector(fieldsChanged(_:))
		}
		quoteNames.state = (saved?.quoteNames ?? d.quoteNames) ? .on : .off
		printBankName.state = (saved?.printBankName ?? d.printBankName) ? .on : .off
		textEdit.state = (saved?.textEdit ?? false) ? .on : .off
		textEdit.toolTip = "Also open the list in TextEdit"
		for b in [all, selection] {
			b.target = self
			b.action = #selector(radioChanged(_:))
		}
		selection.isEnabled = hasSelection
		all.state = .on
		fieldsChanged(nil)
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	private var checkedFields: [PatchExport.Field] {
		order.filter { f in checks[PatchExport.Field.allCases.firstIndex(of: f)!].state == .on }
	}

	@objc private func fieldsChanged(_ sender: Any?) {
		orderTable.reloadData()
		okButton.isEnabled = !checkedFields.isEmpty
	}

	@objc private func radioChanged(_ sender: NSButton) {
		all.state = sender === all ? .on : .off
		selection.state = sender === selection ? .on : .off
	}

	func numberOfRows(in tableView: NSTableView) -> Int { checkedFields.count }

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		NSTextField(labelWithString: checkedFields[row].title)
	}

	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		let item = NSPasteboardItem()
		item.setString(checkedFields[row].rawValue, forType: Self.rowType)
		return item
	}

	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
	               proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		if dropOperation == .on { tableView.setDropRow(row, dropOperation: .above) }
		return .move
	}

	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
	               dropOperation: NSTableView.DropOperation) -> Bool {
		guard let s = info.draggingPasteboard.pasteboardItems?.first?.string(forType: Self.rowType),
		      let f = PatchExport.Field(rawValue: s) else { return false }
		// La posición se cuenta entre los marcados; el campo se pone delante del que ocupa esa fila.
		let visible = checkedFields
		order.removeAll { $0 == f }
		if row < visible.count, visible[row] != f, let at = order.firstIndex(of: visible[row]) {
			order.insert(f, at: at)
		} else if row < visible.count, visible[row] == f, row + 1 < visible.count, let at = order.firstIndex(of: visible[row + 1]) {
			order.insert(f, at: at)
		} else {
			order.append(f)
		}
		orderTable.reloadData()
		return true
	}

	override func commit() throws {
		let export = PatchExport(fields: checkedFields,
		                         delimiter: PatchExport.Delimiter.allCases[max(0, delimiter.indexOfSelectedItem)],
		                         quoteNames: quoteNames.state == .on, printBankName: printBankName.state == .on)
		let saved = Saved(order: order, checked: export.fields, delimiter: export.delimiter, quoteNames: export.quoteNames,
		                  printBankName: export.printBankName, textEdit: textEdit.state == .on)
		if let data = try? JSONEncoder().encode(saved) { UserDefaults.standard.set(data, forKey: Self.defaultsKey) }
		try onCommit?(export, textEdit.state == .on, selection.state == .on)
	}
}

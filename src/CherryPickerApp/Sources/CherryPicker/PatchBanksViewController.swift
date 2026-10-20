// Pestaña Patch Banks (nib MainWindow, PatchBankVC): tabla de bancos. De momento solo lectura;
// botones (+ / −, Merge, Import, Find, Zap Dups), edición y el botón «P» llegan en las tareas siguientes.
import AppKit
import CherryPickerCore

final class PatchBanksViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
	/// Identificador y cabecera de cada columna, como en el nib; ancho inicial.
	private static let columns: [(id: String, title: String, width: CGFloat)] = [
		("open", "P", 24), ("bs0", "S0", 40), ("bs32", "S32", 40),
		("name", "Patch Bank", 280), ("num", "#", 50), ("channels", "Channel Set", 160),
	]

	private let document: MidnamDocument
	private var rows: [BankRow] = []

	init(document: MidnamDocument) {
		self.document = document
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	override func loadView() {
		rows = document.model.map(BankRows.rows) ?? []

		let table = NSTableView()
		table.usesAlternatingRowBackgroundColors = true
		table.allowsMultipleSelection = true
		table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
		for c in Self.columns {
			let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(c.id))
			col.title = c.title
			col.width = c.width
			table.addTableColumn(col)
		}
		table.dataSource = self
		table.delegate = self

		let scroll = NSScrollView()
		scroll.documentView = table
		scroll.hasVerticalScroller = true
		scroll.borderType = .bezelBorder
		view = scroll
	}

	func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let id = tableColumn?.identifier.rawValue else { return nil }
		let r = rows[row]
		let text: String
		switch id {
		case "open": text = "P"
		case "bs0": text = r.bankSelect0
		case "bs32": text = r.bankSelect32
		case "name": text = r.name
		case "num": text = r.patchCount.map(String.init) ?? "?"
		case "channels": text = r.channelSet
		default: text = ""
		}
		let field = NSTextField(labelWithString: text)
		field.lineBreakMode = .byTruncatingTail
		if id == "open" { field.textColor = .tertiaryLabelColor }
		return field
	}
}

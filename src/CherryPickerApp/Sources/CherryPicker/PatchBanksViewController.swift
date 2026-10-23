// Pestaña Patch Banks (nib MainWindow, PatchBankVC; docs/20 §3.1): tabla de bancos editable.
// Doble clic en el nombre para cambiarlo; doble clic en S0/S32 abre la hoja Bank Selects; el Channel Set se elige en
// su popup; con varios bancos seleccionados, clic en la cabecera S0/S32 o Channel Set los cambia todos (manual); + abre «Add a Single Bank» y − borra los seleccionados; se arrastra para reordenar dentro del Channel Set.
// «P» abre la lista de patches del banco (PatchWindowController).
// «Merge» (con dos o más bancos) abre «Name for Merged Bank»; «Find» abre el Finder; «Zap Dups» borra los patches que
// ya están en los bancos seleccionados (o, sin selección, en un Custom Bank) del mismo Channel Set (T-019).
// Pendiente: Import.
import AppKit
import CherryPickerCore
import MidnamKit

final class PatchBanksViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
	/// Identificador y cabecera de cada columna, como en el nib; ancho inicial.
	private static let columns: [(id: String, title: String, width: CGFloat)] = [
		("open", "P", 24), ("bs0", "S0", 40), ("bs32", "S32", 40),
		("name", "Patch Bank", 200), ("num", "#", 36), ("channels", "Channel Set", 130),
	]
	private static let rowType = NSPasteboard.PasteboardType("local.cherrypicker.bankrow")

	private let document: MidnamDocument
	private var rows: [BankRow] = []
	private let table = NSTableView()
	private let removeButton = NSButton()
	private let mergeButton = NSButton(title: "Merge", target: nil, action: nil)

	init(document: MidnamDocument) {
		self.document = document
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	deinit { NotificationCenter.default.removeObserver(self) }

	override func loadView() {
		table.usesAlternatingRowBackgroundColors = true
		table.allowsMultipleSelection = true
		// Si no, el clic en la cabecera selecciona la columna y quita la selección de filas (cambio múltiple, EXP-010).
		table.allowsColumnSelection = false
		// Solo «Patch Bank» se estira o encoge con la ventana.
		table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
		for c in Self.columns {
			let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(c.id))
			col.title = c.title
			col.width = c.width
			col.resizingMask = c.id == "name" ? [.autoresizingMask, .userResizingMask] : .userResizingMask
			if c.id == "name" { col.minWidth = 80 }
			table.addTableColumn(col)
		}
		table.dataSource = self
		table.delegate = self
		table.target = self
		table.doubleAction = #selector(doubleClick(_:))
		table.registerForDraggedTypes([Self.rowType])
		table.setDraggingSourceOperationMask(.move, forLocal: true)

		let scroll = NSScrollView()
		scroll.documentView = table
		scroll.hasVerticalScroller = true
		scroll.borderType = .bezelBorder

		let add = NSButton(image: NSImage(named: NSImage.addTemplateName)!, target: self, action: #selector(addBank(_:)))
		removeButton.image = NSImage(named: NSImage.removeTemplateName)
		removeButton.bezelStyle = add.bezelStyle
		removeButton.target = self
		removeButton.action = #selector(removeBanks(_:))
		mergeButton.target = self
		mergeButton.action = #selector(mergeBanks(_:))
		let find = NSButton(title: "Find", target: self, action: #selector(find(_:)))
		let zap = NSButton(title: "Zap Dups", target: self, action: #selector(zapDups(_:)))
		for b in [mergeButton, find, zap] { b.controlSize = .small }
		let buttons = NSStackView(views: [add, removeButton, mergeButton, find, zap])
		buttons.spacing = 4
		buttons.setCustomSpacing(12, after: removeButton)

		// Leyenda del original (EXP-009): color del nombre del banco.
		let legend = NSStackView(views: [(BankKind.normal, "Normal"), (.empty, "Empty"), (.mixed, "Mixed")].map {
			let l = NSTextField(labelWithString: "• " + $0.1)
			l.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
			l.textColor = Self.color($0.0)
			return l
		})
		legend.orientation = .vertical
		legend.alignment = .leading
		legend.spacing = 0

		// Como en el original, los botones van encima de la tabla y la leyenda a su derecha.
		let root = NSView()
		for v in [scroll, buttons, legend] as [NSView] {
			v.translatesAutoresizingMaskIntoConstraints = false
			root.addSubview(v)
		}
		NSLayoutConstraint.activate([
			legend.topAnchor.constraint(equalTo: root.topAnchor, constant: 6),
			legend.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
			buttons.centerYAnchor.constraint(equalTo: legend.centerYAnchor),
			buttons.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
			scroll.topAnchor.constraint(equalTo: legend.bottomAnchor, constant: 6),
			scroll.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
			scroll.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
			scroll.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -8),
		])
		view = root

		NotificationCenter.default.addObserver(self, selector: #selector(modelDidChange(_:)),
		                                       name: MidnamDocument.modelDidChange, object: document)
		reload()
	}

	private func reload() {
		rows = document.model.map(BankRows.rows) ?? []
		table.reloadData()
		updateButtons()
	}

	@objc private func modelDidChange(_ n: Notification) {
		let selected = Set(table.selectedRowIndexes.compactMap { rows.indices.contains($0) ? rows[$0].name : nil })
		reload()
		table.selectRowIndexes(IndexSet(rows.indices.filter { selected.contains(rows[$0].name) }), byExtendingSelection: false)
	}

	private func updateButtons() {
		let selected = table.selectedRowIndexes.map { rows[$0].ref }
		removeButton.isEnabled = !selected.isEmpty
		mergeButton.isEnabled = selected.count > 1 && selected.allSatisfy { $0.master == selected[0].master }
	}

	func tableViewSelectionDidChange(_ notification: Notification) { updateButtons() }

	/// Aplica un cambio; si falla, lo explica en una hoja y la tabla vuelve a mostrar el modelo.
	private func edit(_ actionName: String, _ change: (inout MIDINameDocument) throws -> Void) {
		do {
			try document.edit(actionName, change)
		} catch {
			reload()
			if let w = view.window { NSAlert(error: error).beginSheetModal(for: w) }
		}
	}

	// MARK: Celdas

	func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let id = tableColumn?.identifier.rawValue else { return nil }
		let r = rows[row]
		switch id {
		case "name":
			let field = NSTextField(string: r.name)
			field.isBordered = false
			field.drawsBackground = false
			field.lineBreakMode = .byTruncatingTail
			field.textColor = Self.color(r.kind)
			field.delegate = self
			field.tag = row
			return field
		case "channels":
			let sets = document.model?.channelSets(master: r.ref.master) ?? []
			let popup = NSPopUpButton()
			popup.isBordered = false
			popup.controlSize = .small
			for s in sets {
				popup.addItem(withTitle: s.name)
				popup.lastItem?.tag = s.index
			}
			popup.selectItem(withTag: r.ref.set)
			popup.tag = row
			popup.target = self
			popup.action = #selector(channelSetChanged(_:))
			return popup
		case "open":
			// Botón cuadrado del original: abre la lista de patches del banco.
			let b = NSButton(title: "", target: self, action: #selector(openPatches(_:)))
			b.bezelStyle = .smallSquare
			b.tag = row
			b.isEnabled = r.patchCount != nil
			return b
		default:
			let text: String
			switch id {
			case "open": text = "P"
			case "bs0": text = r.bankSelect0
			case "bs32": text = r.bankSelect32
			case "num": text = r.patchCount.map(String.init) ?? "?"
			default: text = ""
			}
			let field = NSTextField(labelWithString: text)
			field.lineBreakMode = .byTruncatingTail
			if id == "open" { field.textColor = .tertiaryLabelColor }
			return field
		}
	}

	static func color(_ kind: BankKind) -> NSColor {
		switch kind {
		case .normal: return .labelColor
		case .empty: return .systemRed
		case .mixed: return .systemBlue
		}
	}

	// Nombre: se aplica al terminar de editar la celda.
	func controlTextDidEndEditing(_ obj: Notification) {
		guard let field = obj.object as? NSTextField, rows.indices.contains(field.tag) else { return }
		let r = rows[field.tag]
		let name = field.stringValue
		if name == r.name { return }
		// Fuera del fin de edición: el cambio recarga la tabla y no debe hacerlo mientras la celda aún edita.
		DispatchQueue.main.async { [weak self] in
			self?.edit("Rename Bank") { try $0.renameBank(r.ref, to: name) }
		}
	}

	/// [PROPUESTA P10] Mientras se edita un nombre: Tab y ↓ pasan al del banco siguiente, ⇧Tab y ↑ al del anterior
	/// (el nombre es la única columna que se escribe; en los extremos, lo de siempre).
	func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
		guard let field = control as? NSTextField, let col = table.tableColumns.firstIndex(where: {
			$0.identifier.rawValue == "name"
		}) else { return false }
		var r = table.row(for: field)
		guard r >= 0 else { return false }
		switch selector {
		case #selector(NSResponder.insertTab(_:)), #selector(NSResponder.moveDown(_:)): r += 1
		case #selector(NSResponder.insertBacktab(_:)), #selector(NSResponder.moveUp(_:)): r -= 1
		default: return false
		}
		guard rows.indices.contains(r) else { return false }
		// Terminar la edición encola el cambio (controlTextDidEndEditing); el nombre siguiente se edita después.
		view.window?.makeFirstResponder(table)
		DispatchQueue.main.async { [weak self] in
			guard let self, self.rows.indices.contains(r) else { return }
			self.table.selectRowIndexes([r], byExtendingSelection: false)
			self.table.scrollRowToVisible(r)
			self.table.editColumn(col, row: r, with: nil, select: true)
		}
		return true
	}

	@objc private func channelSetChanged(_ sender: NSPopUpButton) {
		guard rows.indices.contains(sender.tag) else { return }
		let target = sender.selectedTag()
		// [PROPUESTA] Si la fila forma parte de una selección múltiple, cambian todas las seleccionadas.
		let selected = table.selectedRowIndexes
		let indices = selected.contains(sender.tag) && selected.count > 1 ? Array(selected) : [sender.tag]
		let refs = indices.map { rows[$0].ref }
		guard refs.allSatisfy({ $0.master == refs[0].master }) else { return }
		edit("Change Channel Set") { try $0.moveBanks(refs, toChannelSet: target) }
	}

	@objc private func openPatches(_ sender: NSButton) {
		guard rows.indices.contains(sender.tag) else { return }
		PatchWindowController.show(document: document, bank: rows[sender.tag])
	}

	@objc private func doubleClick(_ sender: Any?) {
		let row = table.clickedRow, col = table.clickedColumn
		guard rows.indices.contains(row), col >= 0 else { return }
		let id = table.tableColumns[col].identifier.rawValue
		switch id {
		case "bs0", "bs32": editBankSelects(rows[row])
		case "name": table.editColumn(col, row: row, with: nil, select: true)
		default: break
		}
	}

	// MARK: Hojas

	private func editBankSelects(_ r: BankRow) { editBankSelects([r]) }

	/// Hoja Bank Selects para uno o varios bancos; muestra los valores del primero.
	private func editBankSelects(_ banks: [BankRow]) {
		guard let w = view.window, let first = banks.first else { return }
		let sheet = BankSelectSheet(bankName: first.name, bs0: first.bankSelect0, bs32: first.bankSelect32)
		let refs = banks.map(\.ref)
		sheet.onCommit = { [weak self] bs0, bs32, apply in
			try self?.document.edit("Bank Selects") { doc in
				for ref in refs { try doc.setBankSelect(ref, bs0: bs0, bs32: bs32, apply: apply) }
			}
		}
		sheet.begin(on: w) { _ in _ = sheet }
	}

	// Cambio múltiple: clic en la cabecera con bancos seleccionados (manual: «Multiple Bank Edits»).
	func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
		let selected = table.selectedRowIndexes.map { rows[$0] }
		guard !selected.isEmpty else { return }
		switch tableColumn.identifier.rawValue {
		case "bs0", "bs32":
			editBankSelects(selected)
		case "channels":
			let master = selected[0].ref.master
			guard selected.allSatisfy({ $0.ref.master == master }), let w = view.window,
			      let sets = document.model?.channelSets(master: master) else { return }
			let sheet = ChannelSetSheet(channelSets: sets, selected: selected[0].ref.set)
			let refs = selected.map(\.ref)
			sheet.onCommit = { [weak self] target in
				try self?.document.edit("Change Channel Set") { try $0.moveBanks(refs, toChannelSet: target) }
			}
			sheet.begin(on: w) { _ in _ = sheet }
		default:
			break
		}
	}

	@objc private func addBank(_ sender: Any?) {
		guard let w = view.window, let model = document.model else { return }
		// El banco nuevo va al MasterDeviceNames y Channel Set de la fila seleccionada, o al primero.
		let selected = table.selectedRow >= 0 ? rows[table.selectedRow].ref : rows.first?.ref
		guard let master = selected?.master ?? model.items.indices.first(where: {
			if case .masterDeviceNames = model.items[$0] { return true }; return false
		}) else { return }
		let sets = model.channelSets(master: master)
		guard !sets.isEmpty else { return }
		let sheet = AddBankSheet(channelSets: sets, selectedSet: selected?.set) { [weak self] name in
			self?.document.model?.isBankNameAvailable(name, master: master) ?? false
		}
		sheet.onCommit = { [weak self] set, name, bs0, bs32 in
			try self?.document.edit("Add Bank") {
				try $0.addBank(name: name, bs0: bs0, bs32: bs32, master: master, set: set)
			}
		}
		sheet.begin(on: w) { _ in _ = sheet }
	}

	/// Merge: «Add» borra los originales; Option-Add los conserva (original, nib MergeSheet).
	@objc private func mergeBanks(_ sender: Any?) {
		let refs = table.selectedRowIndexes.map { rows[$0].ref }
		guard refs.count > 1, let w = view.window, let model = document.model else { return }
		let master = refs[0].master
		let sheet = AddBankSheet(channelSets: model.channelSets(master: master), selectedSet: refs[0].set,
		                         title: "Name for Merged Bank", note: "(Use <Option Add> to keep original banks)") { [weak self] name in
			self?.document.model?.isBankNameAvailable(name, master: master) ?? false
		}
		sheet.onCommit = { [weak self] set, name, bs0, bs32 in
			let keep = NSApp.currentEvent?.modifierFlags.contains(.option) ?? false
			try self?.document.edit("Merge Banks") {
				try $0.mergeBanks(refs, name: name, bs0: bs0, bs32: bs32, set: set, keepOriginals: keep)
			}
		}
		sheet.begin(on: w) { _ in _ = sheet }
	}

	@objc private func find(_ sender: Any?) { FinderWindowController.show(document: document) }

	/// [PROPUESTA P11] Pide confirmación con lo que se borrará de cada banco (el original lo borraba sin más).
	/// [PROPUESTA P12] Con bancos seleccionados, se conservan esos y se borra de todos los demás de su Channel Set.
	@objc private func zapDups(_ sender: Any?) {
		guard let w = view.window, let model = document.model else { return }
		let selected = table.selectedRowIndexes.map { rows[$0].ref }
		let keeping = selected.isEmpty ? nil : selected
		let dups = model.duplicatePatches(keeping: keeping)
		let kept = keeping.map { refs in rows.filter { refs.contains($0.ref) }.map(\.name).joined(separator: ", ") }
		let alert = NSAlert()
		if dups.isEmpty {
			alert.messageText = "No duplicates found."
			alert.informativeText = kept.map { "No patch of \($0) is in another bank of the same channel set." }
				?? "No patch in a bank with bank selects is also in a custom bank of the same channel set."
			alert.beginSheetModal(for: w)
			return
		}
		let perBank = rows.compactMap { r -> String? in
			let n = dups.filter { $0.bank == r.ref }.count
			return n == 0 ? nil : "\(r.name): \(n)"
		}
		alert.messageText = dups.count == 1 ? "Delete 1 duplicate patch?" : "Delete \(dups.count) duplicate patches?"
		alert.informativeText = (kept.map { "Patches that are also in \($0) will be deleted from:" }
			?? "Patches that are also in custom banks of the same channel set will be deleted from:")
			+ "\n" + perBank.joined(separator: "\n")
		alert.addButton(withTitle: "Zap Dups")
		alert.addButton(withTitle: "Cancel")
		alert.beginSheetModal(for: w) { [weak self] response in
			guard response == .alertFirstButtonReturn else { return }
			self?.edit("Zap Dups") { try $0.zapDuplicates(keeping: keeping) }
		}
	}

	@objc private func removeBanks(_ sender: Any?) {
		let refs = table.selectedRowIndexes.map { rows[$0].ref }
		guard !refs.isEmpty else { return }
		edit(refs.count == 1 ? "Delete Bank" : "Delete Banks") { try $0.deleteBanks(refs) }
	}

	// MARK: Arrastrar para reordenar (dentro de su Channel Set, como el original)

	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		let item = NSPasteboardItem()
		item.setString(String(row), forType: Self.rowType)
		return item
	}

	private func draggedRow(_ info: NSDraggingInfo) -> Int? {
		guard (info.draggingSource as? NSTableView) === table,
		      let items = info.draggingPasteboard.pasteboardItems, items.count == 1,
		      let s = items[0].string(forType: Self.rowType), let row = Int(s), rows.indices.contains(row) else { return nil }
		return row
	}

	/// Posición de destino contada entre los bancos del mismo Channel Set; nil si la fila cae en otro.
	private func targetPosition(from row: Int, to dropRow: Int) -> Int? {
		let ref = rows[row].ref
		let same = rows.indices.filter { rows[$0].ref.master == ref.master && rows[$0].ref.set == ref.set }
		guard let first = same.first, let last = same.last, (first...last + 1).contains(dropRow) else { return nil }
		return dropRow - first
	}

	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
	               proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		guard dropOperation == .above, let from = draggedRow(info), targetPosition(from: from, to: row) != nil else {
			return []
		}
		return .move
	}

	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
	               dropOperation: NSTableView.DropOperation) -> Bool {
		guard let from = draggedRow(info), let position = targetPosition(from: from, to: row) else { return false }
		let ref = rows[from].ref
		edit("Move Bank") { try $0.reorderBank(ref, toPosition: position) }
		return true
	}
}

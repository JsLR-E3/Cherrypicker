// Ventana Patch Names (nib PatchWindow; docs/20 §3.2, T-018): la lista de patches de un banco, una ventana por banco,
// abierta con el botón «P» de Patch Banks. Tabla B0 · B32 · # · Patch Name · Ascii editable; clic en una cabecera
// ordena la lista (manual del original); + abre «New Patches» y − (o Supr) borra; «Renumber»; pegar o soltar texto
// abre «New Patches» con los nombres; arrastrar reordena, o copia los patches a la lista de otro banco del mismo
// dispositivo. «Find» filtra la tabla por nombre (deducido: el nib tiene findField y findPatches, sin más detalle) y
// «Count:» cuenta las filas que se ven.
// Pendiente: Copy..., audición (Enable MIDI), arrastrar entre documentos, volcados de GigaStudio/Cakewalk y «n=nombre».
import AppKit
import CherryPickerCore
import MidnamKit

final class PatchWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate,
	NSTextFieldDelegate, NSSearchFieldDelegate, NSMenuItemValidation {
	private static let columns: [(id: String, title: String, width: CGFloat, key: PatchSortKey)] = [
		("bs0", "B0", 40, .bankSelect), ("bs32", "B32", 40, .bankSelect), ("num", "#", 40, .program),
		("name", "Patch Name", 220, .name), ("ascii", "Ascii", 60, .ascii),
	]
	/// Patches arrastrados (también desde el Finder): «documento|dispositivo|banco|posición».
	static let rowType = NSPasteboard.PasteboardType("local.cherrypicker.patchrow")

	static func dragString(document: MidnamDocument, master: Int, bank: String, index: Int) -> String {
		"\(ObjectIdentifier(document).hashValue)|\(master)|\(bank)|\(index)"
	}

	private let midnam: MidnamDocument
	private let master: Int
	/// El banco se sigue por su nombre (único en el dispositivo); `ref` es su posición actual.
	private(set) var bankName: String
	private var ref: BankRef
	private var knownBankNames: Set<String> = []
	/// Todas las filas de la lista y las que se ven con el filtro de Find.
	private var allRows: [PatchRow] = []
	private var rows: [PatchRow] = []
	/// Patches que se seleccionan tras el próximo cambio del modelo (los añadidos, movidos o copiados).
	private var pendingSelection: IndexSet?
	private var sortColumn: String?
	private var sortAscending = true

	private let table = PatchTableView()
	private let removeButton = NSButton()
	private let findField = NSSearchField()
	private let countLabel = NSTextField(labelWithString: "")

	/// Abre la lista del banco, o trae al frente la que ya esté abierta.
	static func show(document: MidnamDocument, bank: BankRow) {
		if let wc = document.windowControllers.first(where: {
			($0 as? PatchWindowController).map { $0.master == bank.ref.master && $0.bankName == bank.name } ?? false
		}) {
			wc.showWindow(nil)
			return
		}
		let wc = PatchWindowController(document: document, bank: bank)
		document.addWindowController(wc)
		wc.showWindow(nil)
	}

	private init(document: MidnamDocument, bank: BankRow) {
		midnam = document
		master = bank.ref.master
		bankName = bank.name
		ref = bank.ref
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 470, height: 560),
		                      styleMask: [.titled, .closable, .miniaturizable, .resizable],
		                      backing: .buffered, defer: false)
		window.minSize = NSSize(width: 400, height: 260)
		super.init(window: window)
		window.delegate = self
		window.contentView = makeContent()
		place(window, near: document)
		NotificationCenter.default.addObserver(self, selector: #selector(modelDidChange(_:)),
		                                       name: MidnamDocument.modelDidChange, object: document)
		reload()
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	/// Junto a la ventana principal del documento, en su pantalla, y en cascada con las demás listas abiertas
	/// (EXP-013: se abría en otra pantalla).
	private func place(_ window: NSWindow, near document: MidnamDocument) {
		guard let main = document.windowControllers.first(where: { $0 is DocumentWindowController })?.window else {
			window.center()
			return
		}
		let open = document.windowControllers.filter { $0 is PatchWindowController }.count
		let step = CGFloat(open % 10) * 22
		window.setFrameTopLeftPoint(NSPoint(x: main.frame.maxX + 8 + step, y: main.frame.maxY - step))
		if let screen = main.screen {
			window.setFrame(window.constrainFrameRect(window.frame, to: screen), display: false)
			// Si no cabe a la derecha, encima de la principal, algo desplazada.
			if window.frame.minX < main.frame.maxX {
				window.setFrameTopLeftPoint(NSPoint(x: main.frame.minX + 40 + step, y: main.frame.maxY - 40 - step))
			}
		}
	}

	deinit { NotificationCenter.default.removeObserver(self) }

	override func windowTitle(forDocumentDisplayName displayName: String) -> String {
		"\(bankName) — \(displayName)"
	}

	// Deshacer con el del documento, como en la ventana principal.
	func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? { midnam.undoManager }

	private func makeContent() -> NSView {
		table.usesAlternatingRowBackgroundColors = true
		table.allowsMultipleSelection = true
		table.allowsColumnSelection = false
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
		table.onDelete = { [weak self] in self?.removePatches(nil) }
		table.target = self
		table.doubleAction = #selector(doubleClick(_:))
		table.registerForDraggedTypes([Self.rowType, .string])
		table.setDraggingSourceOperationMask([.move, .copy], forLocal: true)
		table.setDraggingSourceOperationMask(.copy, forLocal: false)

		let scroll = NSScrollView()
		scroll.documentView = table
		scroll.hasVerticalScroller = true
		scroll.borderType = .bezelBorder

		let renumber = NSButton(title: "Renumber", target: self, action: #selector(renumber(_:)))
		let add = NSButton(image: NSImage(named: NSImage.addTemplateName)!, target: self, action: #selector(addPatches(_:)))
		removeButton.image = NSImage(named: NSImage.removeTemplateName)
		removeButton.bezelStyle = add.bezelStyle
		removeButton.target = self
		removeButton.action = #selector(removePatches(_:))
		let buttons = NSStackView(views: [renumber, add, removeButton])
		buttons.spacing = 4

		findField.placeholderString = "Find"
		findField.delegate = self
		findField.sendsSearchStringImmediately = true
		findField.target = self
		findField.action = #selector(findChanged(_:))
		findField.widthAnchor.constraint(equalToConstant: 150).isActive = true

		let root = NSView()
		for v in [buttons, findField, scroll, countLabel] as [NSView] {
			v.translatesAutoresizingMaskIntoConstraints = false
			root.addSubview(v)
		}
		NSLayoutConstraint.activate([
			buttons.topAnchor.constraint(equalTo: root.topAnchor, constant: 8),
			buttons.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
			findField.centerYAnchor.constraint(equalTo: buttons.centerYAnchor),
			findField.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
			scroll.topAnchor.constraint(equalTo: buttons.bottomAnchor, constant: 8),
			scroll.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
			scroll.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
			countLabel.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 6),
			countLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10),
			countLabel.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -8),
		])
		return root
	}

	// MARK: Modelo

	private func reload() {
		allRows = midnam.model?.patchRows(ref) ?? []
		applyFilter()
	}

	private func applyFilter() {
		let find = findField.stringValue.trimmingCharacters(in: .whitespaces)
		rows = find.isEmpty ? allRows : allRows.filter {
			$0.name.range(of: find, options: [.caseInsensitive, .diacriticInsensitive]) != nil
		}
		table.reloadData()
		countLabel.stringValue = "Count: \(rows.count)"
		updateButtons()
	}

	@objc private func modelDidChange(_ n: Notification) {
		guard let model = midnam.model else { return }
		let banks = BankRows.rows(model).filter { $0.ref.master == master }
		if let b = banks.first(where: { $0.name == bankName }) {
			ref = b.ref
		} else if let b = banks.first(where: { $0.ref == ref }), !knownBankNames.contains(b.name) {
			// Mismo sitio y un nombre que antes no estaba: se ha renombrado.
			bankName = b.name
			synchronizeWindowTitleWithDocumentName()
		} else {
			// El banco ya no existe.
			close()
			return
		}
		knownBankNames = Set(banks.map(\.name))
		let selected = pendingSelection ?? IndexSet(table.selectedRowIndexes.compactMap {
			rows.indices.contains($0) ? rows[$0].index : nil
		})
		pendingSelection = nil
		reload()
		let selectRows = IndexSet(rows.indices.filter { selected.contains(rows[$0].index) })
		table.selectRowIndexes(selectRows, byExtendingSelection: false)
		if let first = selectRows.first { table.scrollRowToVisible(first) }
	}

	override func showWindow(_ sender: Any?) {
		knownBankNames = Set((midnam.model.map(BankRows.rows) ?? []).filter { $0.ref.master == master }.map(\.name))
		super.showWindow(sender)
	}

	private func updateButtons() { removeButton.isEnabled = !table.selectedRowIndexes.isEmpty }

	func tableViewSelectionDidChange(_ notification: Notification) { updateButtons() }

	/// Índices de los patches seleccionados (en la lista, no en la tabla filtrada).
	private var selectedPatches: IndexSet {
		IndexSet(table.selectedRowIndexes.compactMap { rows.indices.contains($0) ? rows[$0].index : nil })
	}

	/// Posición en la lista que corresponde a una fila de la tabla (para insertar delante); el final si no hay fila.
	private func listPosition(forRow row: Int) -> Int {
		rows.indices.contains(row) ? rows[row].index : allRows.count
	}

	private func edit(_ actionName: String, _ change: (inout MIDINameDocument) throws -> Void) {
		do {
			try midnam.edit(actionName, change)
		} catch {
			pendingSelection = nil
			reload()
			if let w = window { NSAlert(error: error).beginSheetModal(for: w) }
		}
	}

	// MARK: Celdas

	func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		guard let id = tableColumn?.identifier.rawValue else { return nil }
		let r = rows[row]
		let text: String
		switch id {
		case "bs0": text = r.bankSelect0
		case "bs32": text = r.bankSelect32
		case "num": text = r.program
		case "name": text = r.name
		default: text = r.ascii
		}
		let field = NSTextField(string: text)
		field.isBordered = false
		field.drawsBackground = false
		field.lineBreakMode = .byTruncatingTail
		field.identifier = NSUserInterfaceItemIdentifier(id)
		field.delegate = self
		field.tag = row
		return field
	}

	func controlTextDidEndEditing(_ obj: Notification) {
		guard let field = obj.object as? NSTextField, field !== findField, rows.indices.contains(field.tag),
		      let id = field.identifier?.rawValue else { return }
		let r = rows[field.tag], ref = ref
		let value = field.stringValue
		let (action, change): (String, (inout MIDINameDocument) throws -> Void)
		switch id {
		case "bs0":
			guard value != r.bankSelect0 else { return }
			(action, change) = ("Bank Selects", { try $0.setPatchBankSelect(ref, at: r.index, bs0: value, bs32: r.bankSelect32) })
		case "bs32":
			guard value != r.bankSelect32 else { return }
			(action, change) = ("Bank Selects", { try $0.setPatchBankSelect(ref, at: r.index, bs0: r.bankSelect0, bs32: value) })
		case "num":
			guard value != r.program else { return }
			(action, change) = ("Program Number", { try $0.setPatchProgram(ref, at: r.index, to: value) })
		case "name":
			guard value != r.name else { return }
			(action, change) = ("Rename Patch", { try $0.renamePatch(ref, at: r.index, to: value) })
		default:
			guard value != r.ascii else { return }
			(action, change) = ("Ascii", { try $0.setPatchAscii(ref, at: r.index, to: value) })
		}
		// Fuera del fin de edición: el cambio recarga la tabla y no debe hacerlo mientras la celda aún edita.
		DispatchQueue.main.async { [weak self] in self?.edit(action, change) }
	}

	/// Doble clic en una celda: editarla (EXP-013; si no, solo se editaba manteniendo el clic).
	@objc private func doubleClick(_ sender: Any?) {
		let row = table.clickedRow, col = table.clickedColumn
		guard rows.indices.contains(row), col >= 0 else { return }
		table.editColumn(col, row: row, with: nil, select: true)
	}

	/// [PROPUESTA P10] Mientras se edita una celda: Tab y ⇧Tab pasan a la siguiente o la anterior, saltando de fila al
	/// llegar al final (si no, Tab iba a los botones); ↑ y ↓, a la misma columna del patch de arriba o de abajo; ← y →,
	/// a la celda de al lado solo con el cursor en el borde del texto o todo el texto seleccionado (si no, mueven el
	/// cursor), sin saltar de fila.
	func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
		guard let field = control as? NSTextField, field !== findField, let id = field.identifier?.rawValue,
		      let col = table.tableColumns.firstIndex(where: { $0.identifier.rawValue == id }) else { return false }
		var r = table.row(for: field), c = col
		guard r >= 0 else { return false }
		switch selector {
		case #selector(NSResponder.insertTab(_:)):
			c += 1
			if c == table.numberOfColumns { c = 0; r += 1 }
		case #selector(NSResponder.insertBacktab(_:)):
			c -= 1
			if c < 0 { c = table.numberOfColumns - 1; r -= 1 }
		case #selector(NSResponder.moveUp(_:)): r -= 1
		case #selector(NSResponder.moveDown(_:)): r += 1
		case #selector(NSResponder.moveLeft(_:)), #selector(NSResponder.moveRight(_:)):
			let sel = textView.selectedRange(), length = (textView.string as NSString).length
			let all = sel.location == 0 && sel.length == length
			if selector == #selector(NSResponder.moveLeft(_:)) {
				guard all || (sel.location == 0 && sel.length == 0), c > 0 else { return false }
				c -= 1
			} else {
				guard all || (sel.location == length && sel.length == 0), c < table.numberOfColumns - 1 else { return false }
				c += 1
			}
		default: return false
		}
		// En el primer o el último patch, Tab y las flechas hacen lo de siempre.
		guard rows.indices.contains(r) else { return false }
		// Terminar la edición encola el cambio (controlTextDidEndEditing); la celda siguiente se edita después.
		window?.makeFirstResponder(table)
		DispatchQueue.main.async { [weak self] in self?.startEditing(row: r, column: c) }
		return true
	}

	private func startEditing(row: Int, column: Int) {
		guard rows.indices.contains(row), column < table.numberOfColumns else { return }
		table.selectRowIndexes([row], byExtendingSelection: false)
		table.scrollRowToVisible(row)
		table.editColumn(column, row: row, with: nil, select: true)
	}

	// Ordenar: clic en la cabecera; otro clic en la misma invierte el orden.
	func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
		let id = tableColumn.identifier.rawValue
		guard let key = Self.columns.first(where: { $0.id == id })?.key else { return }
		sortAscending = sortColumn == id ? !sortAscending : true
		sortColumn = id
		let ref = ref, ascending = sortAscending
		edit("Sort Patches") { try $0.sortPatches(ref, by: key, ascending: ascending) }
		for col in table.tableColumns {
			table.setIndicatorImage(col === tableColumn ? NSImage(named: ascending ? "NSAscendingSortIndicator"
			                                                                       : "NSDescendingSortIndicator") : nil,
			                        in: col)
		}
	}

	// MARK: Find

	func controlTextDidChange(_ obj: Notification) {
		if (obj.object as? NSSearchField) === findField { applyFilter() }
	}

	@objc private func findChanged(_ sender: Any?) { applyFilter() }

	// MARK: Botones y hojas

	@objc private func addPatches(_ sender: Any?) { newPatches(text: nil, before: table.selectedRowIndexes.first) }

	/// Hoja New Patches; los patches se insertan delante de la fila `row` (la seleccionada, EXP-012) o al final.
	private func newPatches(text: String?, before row: Int?) {
		guard let w = window else { return }
		let sheet = NewPatchesSheet(text: text)
		let ref = ref, position = row.map(listPosition(forRow:))
		sheet.onCommit = { [weak self] names, startAt, startAscii, useBS in
			try self?.midnam.edit(text == nil ? "New Patches" : "Paste Patches") { doc in
				let r = try doc.addPatches(ref, names: names, startAt: startAt, startAscii: startAscii,
				                           useBankSelects: useBS, before: position)
				self?.pendingSelection = IndexSet(integersIn: r)
			}
		}
		sheet.begin(on: w) { _ in _ = sheet }
	}

	@objc private func removePatches(_ sender: Any?) {
		let indices = selectedPatches
		guard !indices.isEmpty else { return }
		let ref = ref
		edit(indices.count == 1 ? "Delete Patch" : "Delete Patches") { try $0.deletePatches(ref, at: indices) }
	}

	@objc private func renumber(_ sender: Any?) {
		guard let w = window else { return }
		let indices = selectedPatches, ref = ref
		let sheet = RenumberSheet(hasSelection: !indices.isEmpty)
		sheet.onCommit = { [weak self] midiStart, displayStart, onlySelection in
			try self?.midnam.edit("Renumber Patches") {
				try $0.renumberPatches(ref, indices: onlySelection ? indices : nil, midiStart: midiStart,
				                       displayStart: displayStart)
			}
		}
		sheet.begin(on: w) { _ in _ = sheet }
	}

	// Menú Edit: pegar texto abre New Patches; Delete borra los seleccionados.
	@objc func paste(_ sender: Any?) {
		guard let text = NSPasteboard.general.string(forType: .string) else { return }
		newPatches(text: text, before: table.selectedRowIndexes.first)
	}

	@objc func delete(_ sender: Any?) { removePatches(sender) }

	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		switch menuItem.action {
		case #selector(paste(_:)): return NSPasteboard.general.string(forType: .string) != nil
		case #selector(delete(_:)): return !table.selectedRowIndexes.isEmpty
		default: return true
		}
	}

	// MARK: Arrastrar

	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		let item = NSPasteboardItem()
		item.setString(Self.dragString(document: midnam, master: master, bank: bankName, index: rows[row].index),
		               forType: Self.rowType)
		// Fuera de la app se arrastra el nombre (p. ej. a un editor de texto).
		item.setString(rows[row].name, forType: .string)
		return item
	}

	/// Patches arrastrados (banco y posición), si vienen de listas o del Finder del mismo dispositivo de este documento.
	private func draggedPatches(_ info: NSDraggingInfo) -> [(bankName: String, index: Int)]? {
		guard let items = info.draggingPasteboard.pasteboardItems, !items.isEmpty else { return nil }
		let prefix = "\(ObjectIdentifier(midnam).hashValue)|\(master)|"
		var out: [(bankName: String, index: Int)] = []
		for item in items {
			guard let s = item.string(forType: Self.rowType), s.hasPrefix(prefix), let sep = s.lastIndex(of: "|"),
			      let i = Int(s[s.index(after: sep)...]) else { return nil }
			out.append((String(s[s.index(s.startIndex, offsetBy: prefix.count)..<sep]), i))
		}
		return out
	}

	/// Todos los arrastrados son de esta lista: se reordena en vez de copiar.
	private func isMove(_ dragged: [(bankName: String, index: Int)]) -> Bool {
		dragged.allSatisfy { $0.bankName == bankName }
	}

	private func isOwnRowDrag(_ info: NSDraggingInfo) -> Bool {
		info.draggingPasteboard.pasteboardItems?.first?.string(forType: Self.rowType) != nil
	}

	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
	               proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		if dropOperation == .on { tableView.setDropRow(row, dropOperation: .above) }
		if let dragged = draggedPatches(info) {
			// Con Find activo la tabla no muestra toda la lista: reordenar ahí sería confuso.
			if isMove(dragged) { return rows.count == allRows.count ? .move : [] }
			return .copy
		}
		if isOwnRowDrag(info) { return [] }
		return info.draggingPasteboard.string(forType: .string) != nil ? .copy : []
	}

	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
	               dropOperation: NSTableView.DropOperation) -> Bool {
		let position = listPosition(forRow: row), ref = ref
		if let dragged = draggedPatches(info) {
			if isMove(dragged) {
				let indices = IndexSet(dragged.map(\.index))
				edit("Move Patches") { doc in
					let r = try doc.movePatches(ref, at: indices, before: position)
					pendingSelection = IndexSet(integersIn: r)
				}
				return true
			}
			guard let model = midnam.model else { return false }
			let refs = Dictionary(BankRows.rows(model).filter { $0.ref.master == master }.map { ($0.name, $0.ref) },
			                      uniquingKeysWith: { a, _ in a })
			let sources = dragged.compactMap { d in refs[d.bankName].map { (bank: $0, index: d.index) } }
			guard sources.count == dragged.count else { return false }
			edit("Copy Patches") { doc in
				let r = try doc.copyPatches(sources, to: ref, before: position)
				pendingSelection = IndexSet(integersIn: r)
			}
			return true
		}
		guard !isOwnRowDrag(info), let text = info.draggingPasteboard.string(forType: .string) else { return false }
		// La hoja se abre después de terminar el arrastre.
		DispatchQueue.main.async { [weak self] in self?.newPatches(text: text, before: row) }
		return true
	}
}

/// Tabla que borra los seleccionados con Supr.
final class PatchTableView: NSTableView {
	var onDelete: (() -> Void)?

	override func keyDown(with event: NSEvent) {
		if let c = event.charactersIgnoringModifiers?.unicodeScalars.first,
		   c == UnicodeScalar(NSDeleteCharacter) || c == UnicodeScalar(NSDeleteFunctionKey) {
			onDelete?()
		} else {
			super.keyDown(with: event)
		}
	}
}

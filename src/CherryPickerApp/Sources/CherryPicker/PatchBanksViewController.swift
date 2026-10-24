// Pestaña Patch Banks (nib MainWindow, PatchBankVC; docs/20 §3.1): tabla de bancos editable.
// Doble clic en el nombre para cambiarlo; doble clic en S0/S32 abre la hoja Bank Selects; el Channel Set se elige en
// su popup; con varios bancos seleccionados, clic en la cabecera S0/S32 o Channel Set los cambia todos (manual); + abre «Add a Single Bank» y − borra los seleccionados; se arrastra para reordenar dentro del Channel Set.
// «P» abre la lista de patches del banco (PatchWindowController).
// «Merge» (con dos o más bancos) abre «Name for Merged Bank»; «Find» abre el Finder; «Zap Dups» borra los patches que
// ya están en los bancos seleccionados (o, sin selección, en un Custom Bank) del mismo Channel Set (T-019).
// «Import» abre el «Patchlist Importer» (T-022).
// Arrastrar bancos desde la ventana de otro documento los copia aquí (T-026, P18): van al Channel Set de la fila de
// encima del punto donde se sueltan, con su bank select y sus patches.
// [PROPUESTA P22] Sub-bancos en árbol de D-010 (T-033): «Indent Bank» (⌘→), «Outdent Bank» (⌘←) y «Mark as All
// Patches» en el menú Edit y con clic derecho; la tabla muestra los nombres con «• », «├ » y «└ », como DP, y al editar
// un nombre solo se escribe lo que va detrás del prefijo. Un banco padre se arrastra con sus sub-bancos. Si un nombre
// se repetiría, una hoja propone «nombre (padre)». Al abrir un fichero con sub-bancos «- », ofrece pasarlos a árbol.
import AppKit
import CherryPickerCore
import MidnamKit

final class PatchBanksViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate,
	NSMenuDelegate, NSMenuItemValidation {
	/// Identificador y cabecera de cada columna, como en el nib; ancho inicial.
	private static let columns: [(id: String, title: String, width: CGFloat)] = [
		("open", "P", 24), ("bs0", "S0", 40), ("bs32", "S32", 40),
		("name", "Patch Bank", 120), ("num", "#", 36), ("channels", "Channel Set", 130),
	]
	/// Bancos arrastrados: «documento|dispositivo|banco».
	private static let rowType = NSPasteboard.PasteboardType("local.cherrypicker.bankrow")

	private let document: MidnamDocument
	private var rows: [BankRow] = []
	private let table = NSTableView()
	private let removeButton = NSButton()
	private let mergeButton = NSButton(title: "Merge", target: nil, action: nil)
	/// Ya se ofreció pasar los sub-bancos «- » a árbol.
	private var offeredDashConversion = false

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
		table.registerForDraggedTypes([Self.rowType, PatchWindowController.rowType])
		table.setDraggingSourceOperationMask([.move, .copy], forLocal: true)
		let menu = NSMenu()
		for item in Self.treeMenuItems() {
			item.target = self
			menu.addItem(item)
		}
		menu.delegate = self
		table.menu = menu

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
		let importButton = NSButton(title: "Import", target: self, action: #selector(importLists(_:)))
		for b in [mergeButton, find, zap, importButton] { b.controlSize = .small }
		// Orden de la captura del original (EXP-009): Merge, Zap Dups, Import, Find.
		let buttons = NSStackView(views: [add, removeButton, mergeButton, zap, importButton, find])
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
		// Por el nombre sin prefijo: meter o sacar un sub-banco cambia «├ »/«└ » (D-010).
		func base(_ r: BankRow) -> String { TreeName(parsing: r.name).base }
		let selected = Set(table.selectedRowIndexes.compactMap { rows.indices.contains($0) ? base(rows[$0]) : nil })
		reload()
		table.selectRowIndexes(IndexSet(rows.indices.filter { selected.contains(base(rows[$0])) }), byExtendingSelection: false)
	}

	override func viewDidAppear() {
		super.viewDidAppear()
		offerDashConversion()
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
			let field = BankNameField(string: r.name)
			field.base = TreeName(parsing: r.name).base
			field.isBordered = false
			field.drawsBackground = false
			field.lineBreakMode = .byTruncatingTail
			field.textColor = Self.color(r.kind)
			field.delegate = self
			field.tag = row
			return Self.cell(field)
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
			return Self.cell(popup)
		case "open":
			// Botón cuadrado del original: abre la lista de patches del banco. Pequeño y centrado (T-029: el que
			// llenaba la celda se veía basto).
			let b = NSButton(title: "", target: self, action: #selector(openPatches(_:)))
			b.bezelStyle = .smallSquare
			b.controlSize = .mini
			b.tag = row
			b.isEnabled = r.patchCount != nil
			b.translatesAutoresizingMaskIntoConstraints = false
			let c = NSView()
			c.addSubview(b)
			NSLayoutConstraint.activate([
				b.widthAnchor.constraint(equalToConstant: 13), b.heightAnchor.constraint(equalToConstant: 13),
				b.centerXAnchor.constraint(equalTo: c.centerXAnchor), b.centerYAnchor.constraint(equalTo: c.centerYAnchor),
			])
			return c
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
			return Self.cell(field)
		}
	}

	/// Celda con la vista centrada en vertical, para que el texto de todas las columnas quede a la misma altura
	/// (T-029: el del popup de Channel Set salía más bajo). Un campo de texto queda como `textField` de la celda, que
	/// es el que edita `editColumn`.
	private static func cell(_ v: NSView) -> NSView {
		let c = NSTableCellView()
		if let field = v as? NSTextField { c.textField = field }
		v.translatesAutoresizingMaskIntoConstraints = false
		c.addSubview(v)
		NSLayoutConstraint.activate([
			v.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: 2),
			v.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -2),
			v.centerYAnchor.constraint(equalTo: c.centerYAnchor),
		])
		return c
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
		if name == r.name || name == TreeName(parsing: r.name).base {
			// Sin cambios: la celda vuelve a mostrar el prefijo.
			field.stringValue = r.name
			return
		}
		// Fuera del fin de edición: el cambio recarga la tabla y no debe hacerlo mientras la celda aún edita.
		DispatchQueue.main.async { [weak self] in
			self?.editTree("Rename Bank") { try $0.renameBank(r.ref, keepingTreeTo: name, overrides: $1) }
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
		// [PROPUESTA P22] Un banco padre se lleva sus sub-bancos.
		let refs = document.model?.withTreeChildren(indices.map { rows[$0].ref }) ?? []
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
			let refs = document.model?.withTreeChildren(selected.map(\.ref)) ?? []
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

	/// «Import»: ventana «Patchlist Importer» como hoja (T-022).
	@objc private func importLists(_ sender: Any?) {
		guard let w = view.window else { return }
		let importer = ImportWindowController(document: document)
		importer.begin(on: w) { _ = importer }
	}

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

	// MARK: Arrastrar para reordenar (dentro de su Channel Set, como el original) o copiar desde otro documento

	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		let item = NSPasteboardItem()
		let r = rows[row]
		item.setString("\(PatchWindowController.documentKey(document))|\(r.ref.master)|\(r.name)", forType: Self.rowType)
		return item
	}

	/// Bancos arrastrados: documento de origen, dispositivo y nombres (todos del mismo documento y dispositivo).
	private func draggedBanks(_ info: NSDraggingInfo) -> (document: MidnamDocument, master: Int, names: [String])? {
		guard let items = info.draggingPasteboard.pasteboardItems, !items.isEmpty else { return nil }
		var key: String?, master: Int?
		var names: [String] = []
		for item in items {
			guard let s = item.string(forType: Self.rowType) else { return nil }
			let parts = s.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
			guard parts.count == 3, let m = Int(parts[1]) else { return nil }
			if key == nil { key = String(parts[0]); master = m }
			guard key == String(parts[0]), master == m else { return nil }
			names.append(String(parts[2]))
		}
		guard let key, let master, let doc = PatchWindowController.openDocument(key: key) else { return nil }
		return (doc, master, names)
	}

	/// Un solo banco de esta misma tabla: se reordena.
	private func draggedRow(_ info: NSDraggingInfo) -> Int? {
		guard (info.draggingSource as? NSTableView) === table, let d = draggedBanks(info), d.document === document,
		      d.names.count == 1 else { return nil }
		return rows.firstIndex { $0.ref.master == d.master && $0.name == d.names[0] }
	}

	/// Posición de destino contada entre los bancos del mismo Channel Set; nil si la fila cae en otro.
	private func targetPosition(from row: Int, to dropRow: Int) -> Int? {
		let ref = rows[row].ref
		let same = rows.indices.filter { rows[$0].ref.master == ref.master && rows[$0].ref.set == ref.set }
		guard let first = same.first, let last = same.last, (first...last + 1).contains(dropRow) else { return nil }
		return dropRow - first
	}

	/// [PROPUESTA P22] Como `targetPosition`, pero un banco padre (con sus sub-bancos) solo se suelta entre grupos.
	private func treeTargetPosition(from row: Int, to dropRow: Int) -> Int? {
		guard let p = targetPosition(from: row, to: dropRow), let model = document.model else { return nil }
		let ref = rows[row].ref
		if TreeName(parsing: rows[row].name).isChild { return p }
		return model.isTreeGroupBoundary(master: ref.master, set: ref.set, position: p) ? p : nil
	}

	/// Dónde quedan los bancos soltados desde otro documento: en el Channel Set de la fila de encima, detrás de ella
	/// (arriba del todo, delante del primero).
	private func copyTarget(dropRow: Int) -> (master: Int, set: Int, position: Int)? {
		guard !rows.isEmpty else { return nil }
		let anchor = dropRow > 0 ? rows[min(dropRow, rows.count) - 1].ref : rows[0].ref
		let same = rows.indices.filter { rows[$0].ref.master == anchor.master && rows[$0].ref.set == anchor.set }
		let position = dropRow > 0 ? (same.firstIndex(of: min(dropRow, rows.count) - 1)! + 1) : 0
		return (anchor.master, anchor.set, position)
	}

	/// [PROPUESTA P21] Patches arrastrados desde listas o el Finder de cualquier documento, con su banco resuelto.
	private func draggedPatchSources(_ info: NSDraggingInfo)
		-> (document: MidnamDocument, model: MIDINameDocument, sources: [(bank: BankRef, index: Int)])? {
		guard let d = PatchWindowController.draggedPatches(info.draggingPasteboard), let model = d.document.model
		else { return nil }
		let refs = Dictionary(BankRows.rows(model).filter { $0.ref.master == d.master }.map { ($0.name, $0.ref) },
		                      uniquingKeysWith: { a, _ in a })
		let sources = d.patches.compactMap { p in refs[p.bankName].map { (bank: $0, index: p.index) } }
		guard sources.count == d.patches.count else { return nil }
		return (d.document, model, sources)
	}

	/// Patches soltados encima de un banco (se añaden al final) o entre bancos (banco nuevo en ese punto). Dentro del
	/// mismo documento, solo en su dispositivo; sobre su propio banco, nada (ya están ahí).
	private func validatePatchDrop(_ info: NSDraggingInfo, row: Int, on: Bool) -> NSDragOperation {
		guard let d = draggedPatchSources(info) else { return [] }
		if on {
			guard rows.indices.contains(row), rows[row].patchCount != nil else { return [] }
			let target = rows[row].ref
			if d.document === document,
			   d.sources.contains(where: { $0.bank.master != target.master || $0.bank == target }) { return [] }
			return .copy
		}
		guard let t = copyTarget(dropRow: row) else { return [] }
		if d.document === document, d.sources.contains(where: { $0.bank.master != t.master }) { return [] }
		return .copy
	}

	private func acceptPatchDrop(_ info: NSDraggingInfo, row: Int, on: Bool) -> Bool {
		guard validatePatchDrop(info, row: row, on: on) == .copy, let d = draggedPatchSources(info) else { return false }
		if on {
			let target = rows[row].ref
			edit("Copy Patches") { try $0.copyPatches(d.sources, from: d.model, to: target) }
			return true
		}
		guard let t = copyTarget(dropRow: row) else { return false }
		// La hoja se abre después de terminar el arrastre.
		DispatchQueue.main.async { [weak self] in self?.addBankWithPatches(d.sources, from: d.model, at: t) }
		return true
	}

	/// Hoja «Add a Single Bank» para el banco nuevo con los patches soltados; va al punto donde se soltaron (si se
	/// elige otro Channel Set, al final de ese).
	private func addBankWithPatches(_ sources: [(bank: BankRef, index: Int)], from source: MIDINameDocument,
	                                at t: (master: Int, set: Int, position: Int)) {
		guard let w = view.window, let model = document.model else { return }
		let sheet = AddBankSheet(channelSets: model.channelSets(master: t.master), selectedSet: t.set,
		                         title: "New Bank with Patches",
		                         note: "\(sources.count) patch(es), each keeps its own bank select.") { [weak self] name in
			self?.document.model?.isBankNameAvailable(name, master: t.master) ?? false
		}
		sheet.name.stringValue = model.freeBankName("New Bank", master: t.master)
		sheet.onCommit = { [weak self] set, name, bs0, bs32 in
			try self?.document.edit("New Bank with Patches") {
				let ref = try $0.addBank(name: name, bs0: bs0, bs32: bs32, master: t.master, set: set, withPatches: sources,
				                         from: source, before: set == t.set ? t.position : nil)
				// Soltado en medio de un grupo, pasa a sub-banco (D-010).
				try $0.adoptIntoGroup([ref])
			}
		}
		sheet.begin(on: w) { _ in _ = sheet }
		sheet.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification))
	}

	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
	               proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		if PatchWindowController.draggedPatches(info.draggingPasteboard) != nil {
			return validatePatchDrop(info, row: row, on: dropOperation == .on)
		}
		guard dropOperation == .above else { return [] }
		if let from = draggedRow(info) { return treeTargetPosition(from: from, to: row) != nil ? .move : [] }
		if let d = draggedBanks(info), d.document !== document, copyTarget(dropRow: row) != nil { return .copy }
		return []
	}

	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
	               dropOperation: NSTableView.DropOperation) -> Bool {
		if PatchWindowController.draggedPatches(info.draggingPasteboard) != nil {
			return acceptPatchDrop(info, row: row, on: dropOperation == .on)
		}
		if let from = draggedRow(info) {
			guard let position = treeTargetPosition(from: from, to: row) else { return false }
			let ref = rows[from].ref
			editTree("Move Bank") { try $0.moveBankGroup(ref, toPosition: position, overrides: $1) }
			return true
		}
		guard let d = draggedBanks(info), d.document !== document, let other = d.document.model,
		      let target = copyTarget(dropRow: row) else { return false }
		let byName = Dictionary(BankRows.rows(other).filter { $0.ref.master == d.master }.map { ($0.name, $0.ref) },
		                        uniquingKeysWith: { a, _ in a })
		let refs = d.names.compactMap { byName[$0] }
		guard refs.count == d.names.count else { return false }
		var missing: [String] = []
		edit(refs.count == 1 ? "Copy Bank" : "Copy Banks") {
			let copied = try $0.copyBanks(refs, from: other, master: target.master, set: target.set,
			                              before: target.position)
			try $0.adoptIntoGroup(copied.added)
			missing = copied.missingLists
		}
		// Los patches que usan listas de notas o de controles de su fichero las pierden aquí: se avisa.
		if !missing.isEmpty, let w = view.window {
			let a = NSAlert()
			a.messageText = "Some patches use lists that this document doesn't have"
			a.informativeText = "Not copied: \(missing.joined(separator: ", ")). The patches keep the reference."
			DispatchQueue.main.async { a.beginSheetModal(for: w) }
		}
		return true
	}

	// MARK: Sub-bancos en árbol (D-010, [PROPUESTA P22])

	/// Órdenes del menú Edit y del menú contextual de la tabla (sin destino: van al Patch Banks de la ventana activa).
	static func treeMenuItems() -> [NSMenuItem] {
		// ⌘→ y ⌘←: ⌘] y ⌘[ no salen en el teclado español (ISO), donde «]» y «[» van con ⌥ (prueba del usuario).
		let indent = NSMenuItem(title: "Indent Bank", action: #selector(indentBanks(_:)),
		                        keyEquivalent: String(UnicodeScalar(NSRightArrowFunctionKey)!))
		let outdent = NSMenuItem(title: "Outdent Bank", action: #selector(outdentBanks(_:)),
		                         keyEquivalent: String(UnicodeScalar(NSLeftArrowFunctionKey)!))
		let all = NSMenuItem(title: "Mark as All Patches", action: #selector(markAllPatches(_:)), keyEquivalent: "")
		let dash = NSMenuItem(title: "Convert “- ” Sub-Banks to Tree", action: #selector(convertDashSubBanks(_:)),
		                      keyEquivalent: "")
		return [indent, outdent, all, dash]
	}

	private var selectedRefs: [BankRef] { table.selectedRowIndexes.compactMap { rows.indices.contains($0) ? rows[$0].ref : nil } }

	/// Clic derecho en una fila sin seleccionar: la selecciona (las órdenes actúan sobre la selección).
	func menuNeedsUpdate(_ menu: NSMenu) {
		let r = table.clickedRow
		if r >= 0, !table.selectedRowIndexes.contains(r) { table.selectRowIndexes([r], byExtendingSelection: false) }
	}

	func validateMenuItem(_ item: NSMenuItem) -> Bool {
		guard let model = document.model else { return false }
		// Mientras se edita un nombre, ⌘→ y ⌘← mueven el cursor (el menú desactivado deja pasar la tecla).
		guard view.window?.firstResponder === table else { return false }
		let refs = selectedRefs
		switch item.action {
		case #selector(indentBanks(_:)): return refs.contains { model.canIndent($0) }
		case #selector(outdentBanks(_:)): return refs.contains { model.canOutdent($0) }
		case #selector(markAllPatches(_:)):
			let tops = refs.filter { model.bank($0).map { !TreeName(parsing: $0.name).isChild } ?? false }
			let marked = !tops.isEmpty && tops.allSatisfy { model.bank($0).map { TreeName(parsing: $0.name).isAll } ?? false }
			item.state = marked ? .on : .off
			return !tops.isEmpty
		case #selector(convertDashSubBanks(_:)): return !model.dashSubBanks().isEmpty
		default: return true
		}
	}

	@objc func indentBanks(_ sender: Any?) {
		let refs = selectedRefs
		editTree("Indent Bank") { try $0.indentBanks(refs, overrides: $1) }
	}

	@objc func outdentBanks(_ sender: Any?) {
		let refs = selectedRefs
		editTree("Outdent Bank") { try $0.outdentBanks(refs, overrides: $1) }
	}

	@objc func markAllPatches(_ sender: Any?) {
		let refs = selectedRefs
		editTree("Mark as All Patches") { try $0.toggleAllMark(refs, overrides: $1) }
	}

	@objc func convertDashSubBanks(_ sender: Any?) {
		editTree("Convert Sub-Banks") { try $0.convertDashSubBanks(overrides: $1) }
	}

	/// Al abrir un fichero con sub-bancos «- » (como el SPX2000 del usuario), una vez: ofrece pasarlos a árbol.
	private func offerDashConversion() {
		guard !offeredDashConversion, let w = view.window, let model = document.model else { return }
		offeredDashConversion = true
		let dash = model.dashSubBanks()
		guard !dash.isEmpty else { return }
		let alert = NSAlert()
		alert.messageText = "Show “- ” sub-banks as a tree?"
		alert.informativeText = "\(dash.count) banks start with “- ” under another bank. They can be shown as its "
			+ "sub-banks, with “├ ” and “└ ” on the last one. (Also in Edit > Convert “- ” Sub-Banks to Tree.)"
		alert.addButton(withTitle: "Convert")
		alert.addButton(withTitle: "Not Now")
		alert.beginSheetModal(for: w) { [weak self] response in
			guard response == .alertFirstButtonReturn else { return }
			self?.convertDashSubBanks(nil)
		}
	}

	/// Cambio del árbol: si algún nombre se repetiría, la hoja de nombres propone otros y se repite con ellos.
	private func editTree(_ actionName: String, overrides: [BankRef: String] = [:],
	                      _ change: @escaping (inout MIDINameDocument, [BankRef: String]) throws -> Void) {
		do {
			try document.edit(actionName) { try change(&$0, overrides) }
		} catch BankEditError.treeNameConflicts(let conflicts) {
			reload()
			askNames(conflicts) { [weak self] names in
				self?.editTree(actionName, overrides: overrides.merging(names) { $1 }, change)
			}
		} catch {
			reload()
			if let w = view.window { NSAlert(error: error).beginSheetModal(for: w) }
		}
	}

	/// Hoja con un campo por banco repetido, con la propuesta «nombre (padre)»; Cancel deja todo como estaba.
	private func askNames(_ conflicts: [TreeConflict], then: @escaping ([BankRef: String]) -> Void) {
		guard let w = view.window else { return }
		let alert = NSAlert()
		alert.messageText = conflicts.count == 1 ? "This bank name would be repeated" : "These bank names would be repeated"
		alert.informativeText = "DP shows each bank by the name of its patch list, so names must be unique. "
			+ "Type the new name (without the “├ ” or “└ ”):"
		var fields: [(BankRef, NSTextField)] = []
		let grid = NSGridView(views: conflicts.map { c in
			let label = NSTextField(labelWithString: c.prefix + c.base)
			let prefix = NSTextField(labelWithString: "→ " + c.prefix)
			let field = NSTextField(string: c.proposal)
			field.widthAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
			fields.append((c.ref, field))
			return [label, prefix, field]
		})
		grid.rowSpacing = 6
		grid.columnSpacing = 4
		grid.frame.size = grid.fittingSize
		alert.accessoryView = grid
		alert.addButton(withTitle: "OK")
		alert.addButton(withTitle: "Cancel")
		alert.window.initialFirstResponder = fields.first?.1
		alert.beginSheetModal(for: w) { response in
			guard response == .alertFirstButtonReturn else { return }
			// Fuera de la hoja: si vuelve a chocar, se abre otra.
			let names = Dictionary(fields.map { ($0.0, $0.1.stringValue) }, uniquingKeysWith: { a, _ in a })
			DispatchQueue.main.async { then(names) }
		}
	}
}

/// [PROPUESTA P22] Nombre de banco: al empezar a editarlo se escribe solo lo que va detrás de «• », «├ » o «└ »; la app
/// vuelve a poner el prefijo (D-010).
private final class BankNameField: NSTextField {
	var base = ""

	override func becomeFirstResponder() -> Bool {
		if stringValue != base { stringValue = base }
		return super.becomeFirstResponder()
	}
}

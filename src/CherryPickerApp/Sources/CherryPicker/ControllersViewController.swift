// Pestaña Controllers (nib MainWindow, CPControllerVC; docs/20 §3.1; T-028): tablas «Control Name Lists» (+ / −;
// + crea «Default Control Names» con los controladores estándar) y `Ctl` · `Name` (+ / −; doble clic para editar).
// [PROPUESTA P20] Debajo, «Used by Channel Sets»: qué Channel Sets usan la lista seleccionada.
// DP 11.36 no muestra estos nombres (EXP-027): sirve para otros programas.
import AppKit
import CherryPickerCore
import MidnamKit

final class ControllersViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
	private let document: MidnamDocument
	private let listsTable = NSTableView()
	private let controlsTable = NSTableView()
	private let removeListButton = NSButton()
	private let addControlButton = NSButton()
	private let removeControlButton = NSButton()
	private let usedBy = NSStackView()
	private var lists: [String] = []
	private var controls: [ControlRow] = []

	private var master: Int? {
		document.model.flatMap { m in m.items.indices.first { if case .masterDeviceNames = m.items[$0] { return true }; return false } }
	}
	private var selectedList: String? { lists.indices.contains(listsTable.selectedRow) ? lists[listsTable.selectedRow] : nil }

	init(document: MidnamDocument) {
		self.document = document
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	deinit { NotificationCenter.default.removeObserver(self) }

	override func loadView() {
		let listCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("list"))
		listCol.title = "Control Name Lists"
		listCol.resizingMask = .autoresizingMask
		listsTable.addTableColumn(listCol)
		for (id, title, width) in [("ctl", "Ctl", CGFloat(44)), ("name", "Name", CGFloat(160))] {
			let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
			col.title = title
			col.width = width
			col.resizingMask = id == "name" ? .autoresizingMask : .userResizingMask
			controlsTable.addTableColumn(col)
		}
		for t in [listsTable, controlsTable] {
			t.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
			t.usesAlternatingRowBackgroundColors = true
			t.dataSource = self
			t.delegate = self
			t.target = self
			t.doubleAction = #selector(doubleClick(_:))
		}
		controlsTable.allowsMultipleSelection = true

		let listButtons = Self.plusMinus(add: #selector(addList(_:)), remove: removeListButton,
		                                 removeAction: #selector(removeList(_:)), target: self)
		let controlButtons = Self.plusMinus(add: #selector(addControl(_:)), remove: removeControlButton,
		                                    removeAction: #selector(removeControls(_:)), target: self,
		                                    addButton: addControlButton)
		let usedLabel = NSTextField(labelWithString: "Used by Channel Sets:")
		usedLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
		usedBy.orientation = .vertical
		usedBy.alignment = .leading
		usedBy.spacing = 2

		let left = Self.column(table: listsTable, below: [listButtons, usedLabel, usedBy])
		let right = Self.column(table: controlsTable, below: [controlButtons])
		let root = NSView()
		for v in [left, right] {
			v.translatesAutoresizingMaskIntoConstraints = false
			root.addSubview(v)
		}
		NSLayoutConstraint.activate([
			left.topAnchor.constraint(equalTo: root.topAnchor, constant: 12),
			left.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
			left.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -8),
			right.topAnchor.constraint(equalTo: left.topAnchor),
			right.bottomAnchor.constraint(equalTo: left.bottomAnchor),
			right.leadingAnchor.constraint(equalTo: left.trailingAnchor, constant: 12),
			right.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
			left.widthAnchor.constraint(equalTo: right.widthAnchor),
		])
		view = root

		NotificationCenter.default.addObserver(self, selector: #selector(modelDidChange(_:)),
		                                       name: MidnamDocument.modelDidChange, object: document)
		reload(selecting: nil)
	}

	/// Tabla con scroll y, debajo, lo que se pase (botones, etc.).
	private static func column(table: NSTableView, below: [NSView]) -> NSView {
		let scroll = NSScrollView()
		scroll.documentView = table
		scroll.hasVerticalScroller = true
		scroll.autohidesScrollers = true
		scroll.borderType = .bezelBorder
		let stack = NSStackView(views: below)
		stack.orientation = .vertical
		stack.alignment = .leading
		stack.spacing = 6
		let v = NSView()
		for s in [scroll, stack] {
			s.translatesAutoresizingMaskIntoConstraints = false
			v.addSubview(s)
		}
		NSLayoutConstraint.activate([
			scroll.topAnchor.constraint(equalTo: v.topAnchor),
			scroll.leadingAnchor.constraint(equalTo: v.leadingAnchor),
			scroll.trailingAnchor.constraint(equalTo: v.trailingAnchor),
			stack.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 6),
			stack.leadingAnchor.constraint(equalTo: v.leadingAnchor),
			stack.trailingAnchor.constraint(lessThanOrEqualTo: v.trailingAnchor),
			stack.bottomAnchor.constraint(equalTo: v.bottomAnchor),
		])
		return v
	}

	private static func plusMinus(add: Selector, remove: NSButton, removeAction: Selector, target: AnyObject,
	                              addButton: NSButton = NSButton()) -> NSStackView {
		addButton.image = NSImage(named: NSImage.addTemplateName)
		addButton.bezelStyle = .smallSquare
		addButton.target = target
		addButton.action = add
		remove.image = NSImage(named: NSImage.removeTemplateName)
		remove.bezelStyle = .smallSquare
		remove.target = target
		remove.action = removeAction
		let s = NSStackView(views: [addButton, remove])
		s.spacing = 2
		return s
	}

	@objc private func modelDidChange(_ n: Notification) { reload(selecting: selectedList) }

	private func reload(selecting name: String?) {
		guard let doc = document.model, let master else { return }
		lists = doc.controlListNames(master: master)
		listsTable.reloadData()
		if let i = lists.firstIndex(where: { $0 == name }) ?? (lists.isEmpty ? nil : 0) {
			listsTable.selectRowIndexes([i], byExtendingSelection: false)
		}
		reloadControls()
	}

	private func reloadControls(selecting rows: IndexSet? = nil) {
		let keep = rows ?? controlsTable.selectedRowIndexes
		controls = selectedList.flatMap { l in master.map { document.model?.controlRows(list: l, master: $0) ?? [] } } ?? []
		controlsTable.reloadData()
		controlsTable.selectRowIndexes(IndexSet(keep.filter { $0 < controls.count }), byExtendingSelection: false)
		reloadUsedBy()
		updateButtons()
	}

	/// Una casilla por Channel Set; marcada si usa la lista seleccionada.
	private func reloadUsedBy() {
		usedBy.arrangedSubviews.forEach { $0.removeFromSuperview() }
		guard let doc = document.model, let master, let list = selectedList else { return }
		let using = doc.channelSetsUsing(controlList: list, master: master)
		for s in doc.channelSets(master: master) {
			let b = NSButton(checkboxWithTitle: s.name, target: self, action: #selector(usedByChanged(_:)))
			b.tag = s.index
			b.state = using.contains(s.index) ? .on : .off
			b.controlSize = .small
			usedBy.addArrangedSubview(b)
		}
	}

	private func updateButtons() {
		removeListButton.isEnabled = selectedList != nil
		addControlButton.isEnabled = selectedList != nil
		removeControlButton.isEnabled = !controlsTable.selectedRowIndexes.isEmpty
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		if (notification.object as? NSTableView) === listsTable { reloadControls(selecting: []) } else { updateButtons() }
	}

	/// Aplica un cambio; si falla, lo explica en una hoja y las tablas vuelven a mostrar el modelo.
	private func edit(_ actionName: String, _ change: (inout MIDINameDocument) throws -> Void) {
		do {
			try document.edit(actionName, change)
		} catch {
			if let w = view.window { NSAlert(error: error).beginSheetModal(for: w) }
			reload(selecting: selectedList)
		}
	}

	// MARK: Tablas

	func numberOfRows(in tableView: NSTableView) -> Int { tableView === listsTable ? lists.count : controls.count }

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let id = tableColumn?.identifier.rawValue ?? "list"
		let text = switch id {
		case "ctl": controls[row].type == "7bit" ? controls[row].number : "\(controls[row].number) \(controls[row].type)"
		case "name": controls[row].name
		default: lists[row]
		}
		let field = NSTextField(string: text)
		field.isBordered = false
		field.drawsBackground = false
		field.isEditable = false
		field.lineBreakMode = .byTruncatingTail
		field.delegate = self
		field.identifier = NSUserInterfaceItemIdentifier(id)
		field.tag = row
		if id == "ctl" { field.alignment = .right }
		return field
	}

	@objc private func doubleClick(_ sender: NSTableView) {
		let row = sender.clickedRow, col = max(sender.clickedColumn, 0)
		guard row >= 0, let field = sender.view(atColumn: col, row: row, makeIfNecessary: false) as? NSTextField else { return }
		// Solo los de 7 bits cambian de número (los demás tipos se conservan como vienen).
		if field.identifier?.rawValue == "ctl", controls[row].type != "7bit" { NSSound.beep(); return }
		field.isEditable = true
		view.window?.makeFirstResponder(field)
	}

	func controlTextDidEndEditing(_ obj: Notification) {
		guard let field = obj.object as? NSTextField, field.isEditable, let master else { return }
		field.isEditable = false
		let row = field.tag, text = field.stringValue
		// Fuera del fin de edición: el cambio recarga la tabla.
		DispatchQueue.main.async { [weak self] in
			guard let self else { return }
			switch field.identifier?.rawValue {
			case "list":
				guard self.lists.indices.contains(row), self.lists[row] != text else { return }
				let old = self.lists[row]
				self.edit("Rename Control List") { try $0.renameControlList(old, to: text, master: master) }
				self.reload(selecting: text.trimmingCharacters(in: .whitespaces))
			case "ctl":
				guard let list = self.selectedList, self.controls.indices.contains(row), self.controls[row].number != text else { return }
				var moved: Int?
				self.edit("Change Controller") { moved = try $0.setControlNumber(list: list, at: row, to: text, master: master) }
				// La lista se reordena por número: se sigue al control.
				if let moved {
					self.reloadControls(selecting: [moved])
					self.controlsTable.scrollRowToVisible(moved)
				}
			case "name":
				guard let list = self.selectedList, self.controls.indices.contains(row), self.controls[row].name != text else { return }
				self.edit("Rename Controller") { try $0.renameControl(list: list, at: row, to: text, master: master) }
			default:
				break
			}
		}
	}

	// MARK: Botones

	@objc private func addList(_ sender: Any?) {
		guard let master else { return }
		var name: String?
		edit("Add Control List") { name = try $0.addControlList(master: master) }
		if let name { reload(selecting: name) }
	}

	@objc private func removeList(_ sender: Any?) {
		guard let master, let list = selectedList else { return }
		edit("Delete Control List") { try $0.deleteControlList(list, master: master) }
	}

	@objc private func addControl(_ sender: Any?) {
		guard let master, let list = selectedList else { return }
		var row: Int?
		edit("Add Controller") { row = try $0.addControl(list: list, master: master) }
		guard let row else { return }
		reloadControls(selecting: [row])
		controlsTable.scrollRowToVisible(row)
		if let field = controlsTable.view(atColumn: 1, row: row, makeIfNecessary: true) as? NSTextField {
			field.isEditable = true
			view.window?.makeFirstResponder(field)
		}
	}

	@objc private func removeControls(_ sender: Any?) {
		guard let master, let list = selectedList else { return }
		let rows = controlsTable.selectedRowIndexes
		edit(rows.count == 1 ? "Delete Controller" : "Delete Controllers") {
			try $0.deleteControls(list: list, at: rows, master: master)
		}
		reloadControls(selecting: [])
	}

	@objc private func usedByChanged(_ sender: NSButton) {
		guard let master, let list = selectedList else { return }
		let use = sender.state == .on ? list : nil
		edit(use == nil ? "Stop Using Control List" : "Use Control List") {
			try $0.setControlList(use, forChannelSet: sender.tag, master: master)
		}
	}
}

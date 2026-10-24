// Pestaña Categories (nib MainWindow, CPCategoryController; docs/20 §3.1; T-025): tablas «Categories» y «Bank Names»
// con + / −, «Dup» (copia propia de un juego) y «Add To Banks» (crea en el documento un Custom Bank vacío, sin bank
// select, por cada nombre seleccionado, o por todos si no hay selección). Los juegos GM y E-mu no se editan; los
// propios valen para todos los documentos y se guardan en las preferencias de la app (no en el .midnam).
// Doble clic en un nombre lo cambia.
import AppKit
import CherryPickerCore
import MidnamKit

/// Juegos de categorías de la app, compartidos por todas las ventanas.
final class CategoryStore {
	static let shared = CategoryStore()
	static let didChange = Notification.Name("CategoryStoreDidChange")
	private static let key = "userCategories"

	private(set) var library: CategoryLibrary

	private init() {
		let saved = UserDefaults.standard.data(forKey: Self.key)
			.flatMap { try? JSONDecoder().decode([CategorySet].self, from: $0) } ?? []
		library = CategoryLibrary(user: saved)
	}

	/// Aplica un cambio; si `change` lanza un error, no cambia nada.
	func edit<T>(_ change: (inout CategoryLibrary) throws -> T) throws -> T {
		var lib = library
		let result = try change(&lib)
		if lib != library {
			library = lib
			if let data = try? JSONEncoder().encode(lib.userSets) { UserDefaults.standard.set(data, forKey: Self.key) }
			NotificationCenter.default.post(name: Self.didChange, object: self)
		}
		return result
	}
}

final class CategoriesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
	private let document: MidnamDocument
	private let categoriesTable = NSTableView()
	private let namesTable = NSTableView()
	private let removeCategoryButton = NSButton()
	private let addNameButton = NSButton()
	private let removeNameButton = NSButton()
	private let dupButton = NSButton(title: "Dup", target: nil, action: nil)
	private let addToBanksButton = NSButton(title: "Add To Banks", target: nil, action: nil)

	private var store: CategoryStore { .shared }
	private var sets: [CategorySet] { store.library.sets }
	private var selectedCategory: Int? {
		sets.indices.contains(categoriesTable.selectedRow) ? categoriesTable.selectedRow : nil
	}
	private var names: [String] { selectedCategory.map { sets[$0].bankNames } ?? [] }
	private var isEditable: Bool { selectedCategory.map { !sets[$0].isStandard } ?? false }

	private var master: Int? {
		document.model.flatMap { m in m.items.indices.first { if case .masterDeviceNames = m.items[$0] { return true }; return false } }
	}

	init(document: MidnamDocument) {
		self.document = document
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	deinit { NotificationCenter.default.removeObserver(self) }

	override func loadView() {
		for (table, title) in [(categoriesTable, "Categories"), (namesTable, "Bank Names")] {
			let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(title))
			col.title = title
			col.resizingMask = .autoresizingMask
			table.addTableColumn(col)
			table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
			table.usesAlternatingRowBackgroundColors = true
			table.dataSource = self
			table.delegate = self
			table.target = self
			table.doubleAction = #selector(doubleClick(_:))
		}
		categoriesTable.allowsEmptySelection = false
		namesTable.allowsMultipleSelection = true

		dupButton.target = self
		dupButton.action = #selector(duplicate(_:))
		dupButton.toolTip = "Make your own copy of the selected category"
		addToBanksButton.target = self
		addToBanksButton.action = #selector(addToBanks(_:))
		addToBanksButton.toolTip = "Add an empty custom bank for each selected name (or for all, if none is selected)"
		for b in [dupButton, addToBanksButton] { b.controlSize = .small }

		let catButtons = Self.plusMinus(add: #selector(addCategory(_:)), remove: removeCategoryButton,
		                                removeAction: #selector(removeCategories(_:)), target: self)
		catButtons.addArrangedSubview(dupButton)
		catButtons.setCustomSpacing(10, after: removeCategoryButton)
		let nameButtons = Self.plusMinus(add: #selector(addName(_:)), remove: removeNameButton,
		                                 removeAction: #selector(removeNames(_:)), target: self, addButton: addNameButton)
		nameButtons.addArrangedSubview(addToBanksButton)
		nameButtons.setCustomSpacing(10, after: removeNameButton)

		let left = Self.column(table: categoriesTable, buttons: catButtons)
		let right = Self.column(table: namesTable, buttons: nameButtons)
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

		NotificationCenter.default.addObserver(self, selector: #selector(storeDidChange(_:)),
		                                       name: CategoryStore.didChange, object: nil)
		categoriesTable.reloadData()
		categoriesTable.selectRowIndexes([0], byExtendingSelection: false)
		reloadNames()
	}

	/// Tabla con scroll y botones debajo.
	private static func column(table: NSTableView, buttons: NSView) -> NSView {
		let scroll = NSScrollView()
		scroll.documentView = table
		scroll.hasVerticalScroller = true
		scroll.autohidesScrollers = true
		scroll.borderType = .bezelBorder
		let v = NSView()
		for s in [scroll, buttons] {
			s.translatesAutoresizingMaskIntoConstraints = false
			v.addSubview(s)
		}
		NSLayoutConstraint.activate([
			scroll.topAnchor.constraint(equalTo: v.topAnchor),
			scroll.leadingAnchor.constraint(equalTo: v.leadingAnchor),
			scroll.trailingAnchor.constraint(equalTo: v.trailingAnchor),
			buttons.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 6),
			buttons.leadingAnchor.constraint(equalTo: v.leadingAnchor),
			buttons.bottomAnchor.constraint(equalTo: v.bottomAnchor),
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

	@objc private func storeDidChange(_ n: Notification) {
		let name = selectedCategory.map { sets[$0].name }
		categoriesTable.reloadData()
		let i = sets.firstIndex { $0.name == name } ?? min(categoriesTable.selectedRow, sets.count - 1)
		categoriesTable.selectRowIndexes([max(i, 0)], byExtendingSelection: false)
		reloadNames()
	}

	private func reloadNames(selecting rows: IndexSet = []) {
		namesTable.reloadData()
		namesTable.selectRowIndexes(rows, byExtendingSelection: false)
		updateButtons()
	}

	private func updateButtons() {
		removeCategoryButton.isEnabled = isEditable
		addNameButton.isEnabled = isEditable
		removeNameButton.isEnabled = isEditable && !namesTable.selectedRowIndexes.isEmpty
		dupButton.isEnabled = selectedCategory != nil
		addToBanksButton.isEnabled = !names.isEmpty && master != nil
	}

	func tableViewSelectionDidChange(_ notification: Notification) {
		if (notification.object as? NSTableView) === categoriesTable { reloadNames() } else { updateButtons() }
	}

	/// Aplica un cambio a los juegos; si falla, lo explica en una hoja.
	@discardableResult
	private func edit<T>(_ change: (inout CategoryLibrary) throws -> T) -> T? {
		do {
			return try store.edit(change)
		} catch {
			if let w = view.window { NSAlert(error: error).beginSheetModal(for: w) }
			storeDidChange(Notification(name: CategoryStore.didChange))
			return nil
		}
	}

	// MARK: Tablas

	func numberOfRows(in tableView: NSTableView) -> Int { tableView === categoriesTable ? sets.count : names.count }

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let isCategory = tableView === categoriesTable
		let field = NSTextField(string: isCategory ? sets[row].name : names[row])
		field.isBordered = false
		field.drawsBackground = false
		field.isEditable = false
		field.lineBreakMode = .byTruncatingTail
		field.delegate = self
		field.identifier = NSUserInterfaceItemIdentifier(isCategory ? "category" : "name")
		field.tag = row
		// Los juegos de serie se distinguen: no se editan.
		if isCategory && sets[row].isStandard { field.textColor = .secondaryLabelColor }
		return field
	}

	@objc private func doubleClick(_ sender: NSTableView) {
		let row = sender.clickedRow
		guard row >= 0, isEditable || sender === categoriesTable,
		      let field = sender.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTextField else { return }
		if sender === categoriesTable, sets[row].isStandard { NSSound.beep(); return }
		field.isEditable = true
		view.window?.makeFirstResponder(field)
	}

	func controlTextDidEndEditing(_ obj: Notification) {
		guard let field = obj.object as? NSTextField, field.isEditable else { return }
		field.isEditable = false
		let row = field.tag, text = field.stringValue
		// Fuera del fin de edición: el cambio recarga la tabla.
		DispatchQueue.main.async { [weak self] in
			guard let self else { return }
			if field.identifier?.rawValue == "category" {
				guard self.sets.indices.contains(row) else { return }
				self.edit { try $0.renameCategory(at: row, to: text) }
			} else if let i = self.selectedCategory, self.names.indices.contains(row) {
				self.edit { try $0.renameBankName(at: row, inCategory: i, to: text) }
			}
		}
	}

	// MARK: Botones

	@objc private func addCategory(_ sender: Any?) {
		guard let i = edit({ lib in try lib.addCategory(named: lib.freeName("New Category")) }) else { return }
		select(category: i, editing: true)
	}

	@objc private func duplicate(_ sender: Any?) {
		guard let c = selectedCategory, let i = edit({ $0.duplicateCategory(at: c) }) else { return }
		select(category: i, editing: false)
	}

	@objc private func removeCategories(_ sender: Any?) {
		guard let c = selectedCategory else { return }
		edit { try $0.removeCategories(at: [c]) }
	}

	@objc private func addName(_ sender: Any?) {
		guard let c = selectedCategory,
		      let j = edit({ lib in try lib.addBankName(lib.freeBankName("New Bank", inCategory: c), toCategory: c) })
		else { return }
		reloadNames(selecting: [j])
		namesTable.scrollRowToVisible(j)
		if let field = namesTable.view(atColumn: 0, row: j, makeIfNecessary: true) as? NSTextField {
			field.isEditable = true
			view.window?.makeFirstResponder(field)
		}
	}

	@objc private func removeNames(_ sender: Any?) {
		guard let c = selectedCategory else { return }
		let rows = namesTable.selectedRowIndexes
		edit { try $0.removeBankNames(at: rows, fromCategory: c) }
	}

	private func select(category i: Int, editing: Bool) {
		categoriesTable.selectRowIndexes([i], byExtendingSelection: false)
		categoriesTable.scrollRowToVisible(i)
		reloadNames()
		if editing, let field = categoriesTable.view(atColumn: 0, row: i, makeIfNecessary: true) as? NSTextField {
			field.isEditable = true
			view.window?.makeFirstResponder(field)
		}
	}

	/// «Add To Banks»: con varios Channel Sets pregunta en cuál; al final dice qué nombres ya eran de un banco.
	@objc private func addToBanks(_ sender: Any?) {
		guard let w = view.window, let master, let model = document.model else { return }
		let selected = namesTable.selectedRowIndexes
		let chosen = selected.isEmpty ? names : selected.map { names[$0] }
		let sets = model.channelSets(master: master)
		guard !chosen.isEmpty, !sets.isEmpty else { return }
		let add = { [weak self] (set: Int) in
			guard let self else { return }
			var result: (added: [BankRef], skipped: [String]) = ([], [])
			do {
				try self.document.edit(chosen.count == 1 ? "Add Bank" : "Add Banks") {
					result = try $0.addCustomBanks(named: chosen, master: master, set: set)
				}
			} catch {
				NSAlert(error: error).beginSheetModal(for: w)
				return
			}
			let a = NSAlert()
			a.messageText = result.added.count == 1 ? "1 custom bank added" : "\(result.added.count) custom banks added"
			a.informativeText = result.skipped.isEmpty
				? "They are empty and use each patch's own bank select. Drag patches into them from other patch lists."
				: "Already in the device (bank names must be unique): \(result.skipped.joined(separator: ", "))."
			a.beginSheetModal(for: w)
		}
		if sets.count == 1 { add(sets[0].index); return }
		let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 220, height: 26))
		for s in sets {
			popup.addItem(withTitle: s.name)
			popup.lastItem?.tag = s.index
		}
		let a = NSAlert()
		a.messageText = "Add the banks to which channel set?"
		a.accessoryView = popup
		a.addButton(withTitle: "Add")
		a.addButton(withTitle: "Cancel")
		a.beginSheetModal(for: w) { r in
			guard r == .alertFirstButtonReturn, let tag = popup.selectedItem?.tag else { return }
			DispatchQueue.main.async { add(tag) }
		}
	}
}

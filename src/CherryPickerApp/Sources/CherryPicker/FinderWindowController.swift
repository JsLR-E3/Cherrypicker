// Ventana Finder (nib FoundWindow; docs/20 §3.4, T-019): botón «Find» de Patch Banks. Busca en todos los bancos los
// patches cuyo nombre contiene el texto (manual del original); columnas sin editar. «Add New Bank With Patches» crea un
// banco con los que quedan en la lista, «Remove Duplicates» quita los que suenan igual que uno anterior y − quita los
// seleccionados de la lista (no del fichero). Se arrastran a la lista de un banco (copia).
import AppKit
import CherryPickerCore
import MidnamKit

final class FinderWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate,
	NSSearchFieldDelegate {
	private static let columns: [(id: String, title: String, width: CGFloat)] = [
		("bank", "Patch Bank", 120), ("bs0", "B0", 36), ("bs32", "B32", 36), ("num", "#", 36),
		("name", "Patch Name", 180), ("ascii", "Ascii", 50),
	]

	private let midnam: MidnamDocument
	private let findField = NSSearchField()
	private let table = NSTableView()
	private let countLabel = NSTextField(labelWithString: "")
	private let addButton = NSButton(title: "Add New Bank With Patches", target: nil, action: nil)
	private let removeButton = NSButton()
	private var found: [FoundPatch] = []
	/// Lo que el usuario ha quitado de la lista; se mantiene si el fichero cambia, se olvida con otra búsqueda.
	private var removed: Set<String> = []
	private var dedupe = false

	static func show(document: MidnamDocument) {
		if let wc = document.windowControllers.first(where: { $0 is FinderWindowController }) {
			wc.showWindow(nil)
			return
		}
		let wc = FinderWindowController(document: document)
		document.addWindowController(wc)
		wc.showWindow(nil)
		wc.window?.makeFirstResponder(wc.findField)
	}

	private init(document: MidnamDocument) {
		midnam = document
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 480),
		                      styleMask: [.titled, .closable, .miniaturizable, .resizable],
		                      backing: .buffered, defer: false)
		window.minSize = NSSize(width: 440, height: 240)
		super.init(window: window)
		window.delegate = self
		window.contentView = makeContent()
		window.layoutIfNeeded()
		table.sizeToFit()
		window.center()
		NotificationCenter.default.addObserver(self, selector: #selector(modelDidChange(_:)),
		                                       name: MidnamDocument.modelDidChange, object: document)
		reload()
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	deinit { NotificationCenter.default.removeObserver(self) }

	override func windowTitle(forDocumentDisplayName displayName: String) -> String { "Finder — \(displayName)" }

	func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? { midnam.undoManager }

	private func makeContent() -> NSView {
		table.usesAlternatingRowBackgroundColors = true
		table.allowsMultipleSelection = true
		table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
		for c in Self.columns {
			let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(c.id))
			col.title = c.title
			col.width = c.width
			// Solo «Patch Name» se estira o encoge con la ventana, como en la lista de patches.
			col.resizingMask = c.id == "name" ? [.autoresizingMask, .userResizingMask] : .userResizingMask
			if c.id == "name" { col.minWidth = 80 }
			col.isEditable = false
			table.addTableColumn(col)
		}
		table.dataSource = self
		table.delegate = self
		table.setDraggingSourceOperationMask(.copy, forLocal: true)
		table.setDraggingSourceOperationMask(.copy, forLocal: false)

		let scroll = NSScrollView()
		scroll.documentView = table
		scroll.hasVerticalScroller = true
		scroll.borderType = .bezelBorder

		findField.placeholderString = "Find"
		findField.delegate = self
		findField.sendsSearchStringImmediately = true
		findField.target = self
		findField.action = #selector(findChanged(_:))

		addButton.target = self
		addButton.action = #selector(addBank(_:))
		let dups = NSButton(title: "Remove Duplicates", target: self, action: #selector(removeDuplicates(_:)))
		removeButton.image = NSImage(named: NSImage.removeTemplateName)
		removeButton.bezelStyle = addButton.bezelStyle
		removeButton.target = self
		removeButton.action = #selector(removeRows(_:))
		let buttons = NSStackView(views: [removeButton, dups, addButton])
		buttons.spacing = 8

		let root = NSView()
		for v in [findField, scroll, countLabel, buttons] as [NSView] {
			v.translatesAutoresizingMaskIntoConstraints = false
			root.addSubview(v)
		}
		NSLayoutConstraint.activate([
			findField.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
			findField.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
			findField.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
			scroll.topAnchor.constraint(equalTo: findField.bottomAnchor, constant: 8),
			scroll.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
			scroll.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
			buttons.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 8),
			buttons.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
			buttons.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -10),
			countLabel.centerYAnchor.constraint(equalTo: buttons.centerYAnchor),
			countLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10),
		])
		return root
	}

	/// Identifica una fila aunque cambien las posiciones del fichero.
	private static func key(_ f: FoundPatch) -> String {
		[f.bankName, f.bankSelect0, f.bankSelect32, f.program, f.name, f.ascii].joined(separator: "\u{1f}")
	}

	private func reload() {
		var list = midnam.model?.findPatches(containing: findField.stringValue) ?? []
		list.removeAll { removed.contains(Self.key($0)) }
		if dedupe { list = FoundPatch.removingDuplicates(list) }
		found = list
		table.reloadData()
		countLabel.stringValue = "Count: \(found.count)"
		updateButtons()
	}

	private func updateButtons() {
		addButton.isEnabled = !found.isEmpty
		removeButton.isEnabled = !table.selectedRowIndexes.isEmpty
	}

	@objc private func modelDidChange(_ n: Notification) { reload() }

	// Como en la ventana de patches: además de la acción del campo, cada cambio del texto relanza la búsqueda
	// (EXP-014: con solo la acción no mostraba nada al escribir).
	func controlTextDidChange(_ obj: Notification) {
		if (obj.object as? NSSearchField) === findField { findChanged(nil) }
	}

	@objc private func findChanged(_ sender: Any?) {
		removed = []
		dedupe = false
		reload()
	}

	func tableViewSelectionDidChange(_ notification: Notification) { updateButtons() }

	@objc private func removeRows(_ sender: Any?) {
		for i in table.selectedRowIndexes { removed.insert(Self.key(found[i])) }
		table.deselectAll(nil)
		reload()
	}

	@objc private func removeDuplicates(_ sender: Any?) {
		dedupe = true
		reload()
	}

	@objc private func addBank(_ sender: Any?) {
		guard let w = window, let model = midnam.model, let first = found.first else { return }
		let master = first.bank.master
		let sets = model.channelSets(master: master)
		let sources = found.map { (bank: $0.bank, index: $0.index) }
		let sheet = AddBankSheet(channelSets: sets, selectedSet: first.bank.set) { [weak self] name in
			self?.midnam.model?.isBankNameAvailable(name, master: master) ?? false
		}
		sheet.name.stringValue = findField.stringValue.trimmingCharacters(in: .whitespaces)
		sheet.onCommit = { [weak self] set, name, bs0, bs32 in
			try self?.midnam.edit("Add Bank With Patches") {
				try $0.addBank(name: name, bs0: bs0, bs32: bs32, master: master, set: set, withPatches: sources)
			}
		}
		sheet.begin(on: w) { _ in _ = sheet }
		sheet.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification))
	}

	// MARK: Tabla

	func numberOfRows(in tableView: NSTableView) -> Int { found.count }

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let f = found[row]
		let text: String
		switch tableColumn?.identifier.rawValue {
		case "bank": text = f.bankName
		case "bs0": text = f.bankSelect0
		case "bs32": text = f.bankSelect32
		case "num": text = f.program
		case "name": text = f.name
		case "ascii": text = f.ascii
		default: return nil
		}
		let field = NSTextField(labelWithString: text)
		field.lineBreakMode = .byTruncatingTail
		return field
	}

	/// Mismo formato que las listas de patches: se sueltan en la de cualquier banco del dispositivo (copia).
	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		let f = found[row]
		let item = NSPasteboardItem()
		item.setString(PatchWindowController.dragString(document: midnam, master: f.bank.master, bank: f.bankName,
		                                                 index: f.index), forType: PatchWindowController.rowType)
		item.setString(f.name, forType: .string)
		return item
	}
}

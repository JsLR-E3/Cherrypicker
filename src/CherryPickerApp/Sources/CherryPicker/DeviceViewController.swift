// Pestaña Device (nib MainWindow; docs/20 §3.1; disposición de la captura del original, T-020): «Manufacturer:» y
// «Model:» de solo lectura; caja «Modes» (tabla y + / −) y caja «Channel Sets» del modo seleccionado (tabla, + / −,
// «Active Channels», «Audition Ch:» y el aviso «(Add disabled: No free channels in mode)»). Doble clic en un nombre lo
// cambia. + de Channel Sets abre «New Channel Set»; − de un Channel Set con patches abre «Reassign Banks To».
// Sin «MIDI Initialization… / Send Now» (SysEx, regla 4) ni «Middev Editor...» (docs/20 §2).
import AppKit
import CherryPickerCore
import MidnamKit

final class DeviceViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
	private let document: MidnamDocument
	private let manufacturer = NSTextField(labelWithString: "")
	private let model = NSTextField(labelWithString: "")
	private let modesTable = NSTableView()
	private let setsTable = NSTableView()
	private let removeModeButton = NSButton()
	private let addSetButton = NSButton()
	private let removeSetButton = NSButton()
	private let activeChannels = NSTextField(string: "")
	private let auditionChannel = NSTextField(string: "")
	private let addDisabledNote = NSTextField(labelWithString: "(Add disabled: No free channels in mode)")
	private var modes: [(index: Int, name: String)] = []
	private var sets: [ChannelSetRow] = []

	init(document: MidnamDocument) {
		self.document = document
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	deinit { NotificationCenter.default.removeObserver(self) }

	/// El primer MasterDeviceNames del fichero (los ficheros de CherryPicker y de DP tienen uno).
	private var master: Int? {
		document.model.flatMap { m in m.items.indices.first { if case .masterDeviceNames = m.items[$0] { return true }; return false } }
	}

	private var selectedMode: Int? {
		modes.indices.contains(modesTable.selectedRow) ? modes[modesTable.selectedRow].index : nil
	}

	private var selectedSet: ChannelSetRow? {
		sets.indices.contains(setsTable.selectedRow) ? sets[setsTable.selectedRow] : nil
	}

	override func loadView() {
		for (t, id) in [(modesTable, "mode"), (setsTable, "set")] {
			let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
			col.resizingMask = .autoresizingMask
			t.addTableColumn(col)
			t.headerView = nil
			t.dataSource = self
			t.delegate = self
			t.target = self
			t.doubleAction = #selector(doubleClick(_:))
		}
		for f in [manufacturer, model] {
			f.isSelectable = true
			f.lineBreakMode = .byTruncatingTail
		}
		activeChannels.delegate = self
		activeChannels.placeholderString = "1-7, 9, 11-16"
		activeChannels.toolTip = "Channels of the selected channel set, e.g. 1-7, 9, 11-16"
		auditionChannel.isEditable = false
		auditionChannel.toolTip = "Channel used to audition patches (lowest channel of the set). MIDI audition is not available yet."
		addDisabledNote.font = .systemFont(ofSize: NSFont.smallSystemFontSize)

		let modesBox = Self.box("Modes", table: modesTable, buttons: Self.plusMinus(add: #selector(addMode(_:)), remove: removeModeButton,
		                                                                            removeAction: #selector(removeMode(_:)), target: self))
		let setButtons = Self.plusMinus(add: #selector(addChannelSet(_:)), remove: removeSetButton,
		                                removeAction: #selector(removeChannelSet(_:)), target: self, addButton: addSetButton)
		setButtons.addArrangedSubview(addDisabledNote)
		let setsBox = Self.box("Channel Sets", table: setsTable, buttons: setButtons)
		// A la derecha de la tabla de Channel Sets, como en el original.
		let fields = NSGridView(views: [
			[NSTextField(labelWithString: "Active Channels")],
			[activeChannels],
			[NSTextField(labelWithString: "Audition Ch:")],
			[auditionChannel],
		])
		fields.rowSpacing = 4
		activeChannels.widthAnchor.constraint(equalToConstant: 110).isActive = true
		auditionChannel.widthAnchor.constraint(equalToConstant: 36).isActive = true
		fields.translatesAutoresizingMaskIntoConstraints = false
		setsBox.contentView?.addSubview(fields)

		let names = NSGridView(views: [[NSTextField(labelWithString: "Manufacturer:"), manufacturer,
		                                NSTextField(labelWithString: "Model:"), model]])
		names.columnSpacing = 6
		let root = NSView()
		for v in [names, modesBox, setsBox] as [NSView] {
			v.translatesAutoresizingMaskIntoConstraints = false
			root.addSubview(v)
		}
		let setsScroll = setsTable.enclosingScrollView!
		let modesScroll = modesTable.enclosingScrollView!
		NSLayoutConstraint.activate([
			modesScroll.trailingAnchor.constraint(equalTo: modesBox.contentView!.trailingAnchor, constant: -8),
			names.topAnchor.constraint(equalTo: root.topAnchor, constant: 12),
			names.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
			names.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -12),
			modesBox.topAnchor.constraint(equalTo: names.bottomAnchor, constant: 14),
			modesBox.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
			modesBox.widthAnchor.constraint(equalToConstant: 170),
			modesBox.heightAnchor.constraint(equalToConstant: 170),
			setsBox.topAnchor.constraint(equalTo: modesBox.topAnchor),
			setsBox.leadingAnchor.constraint(equalTo: modesBox.trailingAnchor, constant: 8),
			setsBox.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
			setsBox.heightAnchor.constraint(equalTo: modesBox.heightAnchor),
			setsScroll.trailingAnchor.constraint(equalTo: fields.leadingAnchor, constant: -8),
			fields.topAnchor.constraint(equalTo: setsScroll.topAnchor),
			fields.trailingAnchor.constraint(equalTo: setsBox.contentView!.trailingAnchor, constant: -8),
		])
		view = root

		NotificationCenter.default.addObserver(self, selector: #selector(modelDidChange(_:)),
		                                       name: MidnamDocument.modelDidChange, object: document)
		reload()
		if !modes.isEmpty { modesTable.selectRowIndexes([0], byExtendingSelection: false) }
	}

	/// Caja con título, tabla con scroll y botones debajo (cajas «Modes» y «Channel Sets» del original).
	private static func box(_ title: String, table: NSTableView, buttons: NSView) -> NSBox {
		let box = NSBox()
		box.title = title
		let content = NSView()
		box.contentView = content
		let scroll = NSScrollView()
		scroll.documentView = table
		scroll.hasVerticalScroller = true
		scroll.borderType = .bezelBorder
		for v in [scroll, buttons] {
			v.translatesAutoresizingMaskIntoConstraints = false
			content.addSubview(v)
		}
		NSLayoutConstraint.activate([
			scroll.topAnchor.constraint(equalTo: content.topAnchor, constant: 6),
			scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 8),
			scroll.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -8),
			scroll.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
			buttons.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 6),
			buttons.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 8),
			buttons.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -8),
		])
		return box
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

	private func reload() {
		guard let doc = document.model, let master else { return }
		let names = doc.deviceNames(master: master)
		manufacturer.stringValue = names.manufacturer
		model.stringValue = names.model
		let modeName = selectedMode.flatMap { i in modes.first { $0.index == i }?.name }
		let setName = selectedSet?.name
		modes = doc.modes(master: master)
		modesTable.reloadData()
		let m = modes.firstIndex { $0.name == modeName } ?? (modes.isEmpty ? nil : 0)
		if let m { modesTable.selectRowIndexes([m], byExtendingSelection: false) }
		reloadSets(selecting: setName)
	}

	private func reloadSets(selecting name: String? = nil) {
		guard let doc = document.model, let master, let mode = selectedMode else {
			sets = []
			setsTable.reloadData()
			updateControls()
			return
		}
		sets = doc.channelSets(master: master, mode: mode)
		setsTable.reloadData()
		let s = sets.firstIndex { $0.name == name } ?? (sets.isEmpty ? nil : 0)
		if let s { setsTable.selectRowIndexes([s], byExtendingSelection: false) }
		updateControls()
	}

	private func updateControls() {
		let free = (master.flatMap { m in selectedMode.map { document.model?.freeChannels(master: m, mode: $0) ?? [] } }) ?? []
		addSetButton.isEnabled = !free.isEmpty
		addDisabledNote.isHidden = !free.isEmpty || selectedMode == nil
		removeModeButton.isEnabled = selectedMode != nil && modes.count > 1
		removeSetButton.isEnabled = selectedSet != nil && sets.count > 1
		activeChannels.isEnabled = selectedSet != nil
		activeChannels.stringValue = selectedSet?.channelsText ?? ""
		auditionChannel.stringValue = selectedSet?.auditionChannel.map(String.init) ?? ""
	}

	@objc private func modelDidChange(_ n: Notification) { reload() }

	func tableViewSelectionDidChange(_ notification: Notification) {
		if (notification.object as? NSTableView) === modesTable { reloadSets() } else { updateControls() }
	}

	/// Aplica un cambio; si falla, lo explica en una hoja y se vuelve a mostrar el modelo.
	private func edit(_ actionName: String, _ change: (inout MIDINameDocument) throws -> Void) {
		do {
			try document.edit(actionName, change)
		} catch {
			reload()
			if let w = view.window { NSAlert(error: error).beginSheetModal(for: w) }
		}
	}

	// MARK: Tablas

	func numberOfRows(in tableView: NSTableView) -> Int { tableView === modesTable ? modes.count : sets.count }

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let field = NSTextField(string: tableView === modesTable ? modes[row].name : sets[row].name)
		field.isBordered = false
		field.drawsBackground = false
		field.isEditable = false
		field.lineBreakMode = .byTruncatingTail
		field.delegate = self
		field.identifier = NSUserInterfaceItemIdentifier(tableView === modesTable ? "mode" : "set")
		field.tag = row
		return field
	}

	@objc private func doubleClick(_ sender: NSTableView) {
		let row = sender.clickedRow
		guard row >= 0, let field = sender.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTextField else { return }
		field.isEditable = true
		view.window?.makeFirstResponder(field)
	}

	func controlTextDidEndEditing(_ obj: Notification) {
		guard let field = obj.object as? NSTextField, let master else { return }
		let text = field.stringValue
		if field === activeChannels {
			guard let mode = selectedMode, let set = selectedSet, text != set.channelsText else { return }
			DispatchQueue.main.async { [weak self] in
				self?.edit("Active Channels") { try $0.setActiveChannels(master: master, mode: mode, set: set.index, text: text) }
			}
			return
		}
		field.isEditable = false
		let row = field.tag
		// Fuera del fin de edición: el cambio recarga la tabla.
		if field.identifier?.rawValue == "mode", modes.indices.contains(row), modes[row].name != text {
			let mode = modes[row].index
			DispatchQueue.main.async { [weak self] in
				self?.edit("Rename Mode") { try $0.renameMode(master: master, mode: mode, to: text) }
			}
		} else if field.identifier?.rawValue == "set", sets.indices.contains(row), sets[row].name != text {
			let set = sets[row].index
			DispatchQueue.main.async { [weak self] in
				self?.edit("Rename Channel Set") { try $0.renameChannelSet(master: master, set: set, to: text) }
			}
		}
	}

	// MARK: Botones

	@objc private func addMode(_ sender: Any?) {
		guard let master else { return }
		var new: Int?
		edit("Add Mode") { new = try $0.addMode(master: master) }
		if let new, let row = modes.firstIndex(where: { $0.index == new }) {
			modesTable.selectRowIndexes([row], byExtendingSelection: false)
		}
	}

	@objc private func removeMode(_ sender: Any?) {
		guard let master, let mode = selectedMode, let w = view.window, let doc = document.model else { return }
		let lost = doc.banksLostWithMode(master: master, mode: mode)
		let delete = { [weak self] in self?.edit("Delete Mode") { try $0.deleteMode(master: master, mode: mode) } }
		if lost.isEmpty { delete(); return }
		let alert = NSAlert()
		alert.messageText = "Delete mode “\(modes.first { $0.index == mode }?.name ?? "")”?"
		alert.informativeText = "Its channel sets and these banks will be deleted: \(lost.joined(separator: ", "))."
		alert.addButton(withTitle: "Delete")
		alert.addButton(withTitle: "Cancel")
		alert.beginSheetModal(for: w) { if $0 == .alertFirstButtonReturn { delete() } }
	}

	@objc private func addChannelSet(_ sender: Any?) {
		guard let master, let mode = selectedMode, let w = view.window, let doc = document.model else { return }
		let free = doc.freeChannels(master: master, mode: mode)
		let sheet = NewChannelSetSheet(name: doc.newChannelSetName(master: master), free: free)
		sheet.onCommit = { [weak self] name, channels in
			try self?.document.edit("Add Channel Set") {
				try $0.addChannelSet(master: master, mode: mode, name: name, channels: channels)
			}
			self?.reloadSets(selecting: name.trimmingCharacters(in: .whitespaces))
		}
		sheet.begin(on: w) { _ in _ = sheet }
	}

	@objc private func removeChannelSet(_ sender: Any?) {
		guard let master, let mode = selectedMode, let set = selectedSet, let w = view.window,
		      let doc = document.model else { return }
		guard doc.channelSetHasPatches(master: master, set: set.index) else {
			edit("Delete Channel Set") { try $0.deleteChannelSet(master: master, mode: mode, set: set.index) }
			return
		}
		let targets = doc.channelSets(master: master).filter { $0.index != set.index }
		let sheet = ReassignBanksSheet(channelSets: targets, preferred: sets.first { $0.index != set.index }?.index)
		sheet.onCommit = { [weak self] target in
			try self?.document.edit("Delete Channel Set") {
				try $0.deleteChannelSet(master: master, mode: mode, set: set.index, reassignTo: target)
			}
		}
		sheet.begin(on: w) { _ in _ = sheet }
	}
}

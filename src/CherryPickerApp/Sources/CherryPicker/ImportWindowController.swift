// Ventana «Patchlist Importer» (nib ImportBrowser; docs/20 §3.4; T-022), con el botón «Import» de Patch Banks.
// Izquierda, «Files You Can Import From»: los `.midnam` de la carpeta (por defecto la de DP del fabricante del
// documento; «Set midnam folder…» elige otra y se recuerda), con su «Type» (fabricante y modelo). Derecha, «Available
// Patch Lists» del fichero elegido, con «#» y «Select Destination Bank»: «-» (no se importa), el banco del mismo
// nombre si lo hay (manual), otro banco del documento o «Add as New Bank» ([PROPUESTA P14]). Las columnas se ajustan a
// su texto más largo; con scroll horizontal si no caben. «Import» lo aplica de una vez.
// Los ficheros se leen solo para listarlos; no se modifican.
import AppKit
import CherryPickerCore
import MidnamKit

final class ImportWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
	private enum Destination: Equatable {
		case none
		case newBank
		case bank(String)
	}

	private let midnam: MidnamDocument
	private let filesTable = NSTableView()
	private let listsTable = NSTableView()
	private let progress = NSProgressIndicator()
	private let progressLabel = NSTextField(labelWithString: "")
	private let importButton = NSButton(title: "Import", target: nil, action: nil)
	private var files: [(url: URL, type: String)] = []
	private var source: MIDINameDocument?
	private var lists: [ImportableList] = []
	private var destinations: [Destination] = []
	private var completion: (() -> Void)?

	private static let folderKey = "importFolder"

	init(document: MidnamDocument) {
		midnam = document
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 820, height: 380), styleMask: [.titled, .resizable],
		                      backing: .buffered, defer: false)
		window.title = "Patchlist Importer"
		window.minSize = NSSize(width: 600, height: 280)
		super.init(window: window)
		window.contentView = makeContent()
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	func begin(on parent: NSWindow, completion: @escaping () -> Void) {
		self.completion = completion
		parent.beginSheet(window!)
		scan(folder: Self.defaultFolder(for: midnam))
	}

	/// La carpeta recordada o, si no, la de DP del fabricante del documento (o la del propio documento).
	private static func defaultFolder(for doc: MidnamDocument) -> URL? {
		if let p = UserDefaults.standard.string(forKey: folderKey), FileManager.default.fileExists(atPath: p) {
			return URL(fileURLWithPath: p)
		}
		if let maker = doc.model?.masterDeviceNames.first?.manufacturer {
			let dp = URL(fileURLWithPath: "/Library/Audio/MIDI Devices/MOTU").appendingPathComponent(maker)
			if FileManager.default.fileExists(atPath: dp.path) { return dp }
		}
		return doc.fileURL?.deletingLastPathComponent()
	}

	private func makeContent() -> NSView {
		func column(_ table: NSTableView, _ id: String, _ title: String, _ width: CGFloat) {
			let c = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
			c.title = title
			c.width = width
			c.resizingMask = .userResizingMask
			table.addTableColumn(c)
		}
		column(filesTable, "midnam", "Files You Can Import From", 130)
		column(filesTable, "type", "Type", 120)
		column(listsTable, "name", "Available Patch Lists", 180)
		column(listsTable, "count", "#", 40)
		column(listsTable, "destination", "Select Destination Bank", 170)
		for t in [filesTable, listsTable] {
			t.dataSource = self
			t.delegate = self
			t.usesAlternatingRowBackgroundColors = true
			t.columnAutoresizingStyle = .noColumnAutoresizing
		}
		listsTable.selectionHighlightStyle = .none

		let scrolls = [filesTable, listsTable].map { t -> NSScrollView in
			let s = NSScrollView()
			s.documentView = t
			s.hasVerticalScroller = true
			s.hasHorizontalScroller = true
			s.autohidesScrollers = true
			s.borderType = .bezelBorder
			return s
		}
		let setFolder = NSButton(title: "Set midnam folder…", target: self, action: #selector(setFolder(_:)))
		let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
		cancel.keyEquivalent = "\u{1b}"
		importButton.target = self
		importButton.action = #selector(doImport(_:))
		importButton.keyEquivalent = "\r"
		progress.style = .spinning
		progress.controlSize = .small
		progress.isDisplayedWhenStopped = false

		let root = NSView()
		for v in scrolls + [setFolder, progress, progressLabel, cancel, importButton] as [NSView] {
			v.translatesAutoresizingMaskIntoConstraints = false
			root.addSubview(v)
		}
		NSLayoutConstraint.activate([
			scrolls[0].topAnchor.constraint(equalTo: root.topAnchor, constant: 12),
			scrolls[0].leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
			scrolls[0].widthAnchor.constraint(equalTo: root.widthAnchor, multiplier: 0.36),
			scrolls[1].topAnchor.constraint(equalTo: scrolls[0].topAnchor),
			scrolls[1].leadingAnchor.constraint(equalTo: scrolls[0].trailingAnchor, constant: 8),
			scrolls[1].trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
			scrolls[1].bottomAnchor.constraint(equalTo: scrolls[0].bottomAnchor),
			setFolder.topAnchor.constraint(equalTo: scrolls[0].bottomAnchor, constant: 10),
			setFolder.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
			setFolder.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -12),
			progress.centerYAnchor.constraint(equalTo: setFolder.centerYAnchor),
			progress.leadingAnchor.constraint(equalTo: setFolder.trailingAnchor, constant: 12),
			progressLabel.centerYAnchor.constraint(equalTo: setFolder.centerYAnchor),
			progressLabel.leadingAnchor.constraint(equalTo: progress.trailingAnchor, constant: 6),
			progressLabel.trailingAnchor.constraint(lessThanOrEqualTo: cancel.leadingAnchor, constant: -8),
			importButton.centerYAnchor.constraint(equalTo: setFolder.centerYAnchor),
			importButton.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
			cancel.centerYAnchor.constraint(equalTo: setFolder.centerYAnchor),
			cancel.trailingAnchor.constraint(equalTo: importButton.leadingAnchor, constant: -8),
		])
		progressLabel.textColor = .secondaryLabelColor
		progressLabel.lineBreakMode = .byTruncatingMiddle
		updateImportButton()
		return root
	}

	// MARK: Ficheros

	/// Lista los `.midnam` de la carpeta (y subcarpetas) en segundo plano, leyendo solo su fabricante y modelo.
	private func scan(folder: URL?) {
		files = []
		source = nil
		lists = []
		filesTable.reloadData()
		listsTable.reloadData()
		guard let folder else {
			progressLabel.stringValue = "Choose a folder with “Set midnam folder…”."
			return
		}
		progress.startAnimation(nil)
		progressLabel.stringValue = "Searching for compatible files..."
		let own = midnam.fileURL?.standardizedFileURL
		DispatchQueue.global(qos: .userInitiated).async {
			var found: [(URL, String)] = []
			let e = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)
			while let url = e?.nextObject() as? URL {
				guard url.pathExtension.lowercased() == "midnam", url.standardizedFileURL != own,
				      let doc = Self.read(url) else { continue }
				found.append((url, doc.deviceDescription))
			}
			found.sort { $0.0.lastPathComponent.localizedStandardCompare($1.0.lastPathComponent) == .orderedAscending }
			DispatchQueue.main.async { [weak self] in
				guard let self else { return }
				self.files = found
				self.filesTable.reloadData()
				self.fitColumns(self.filesTable)
				self.progress.stopAnimation(nil)
				self.progressLabel.stringValue = "\(found.count) file\(found.count == 1 ? "" : "s") in \(folder.path)"
			}
		}
	}

	private static func read(_ url: URL) -> MIDINameDocument? {
		guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8),
		      let f = try? XMLReader.parse(text) else { return nil }
		return try? MIDINameDocument(element: f.root)
	}

	@objc private func setFolder(_ sender: Any?) {
		guard let w = window else { return }
		let panel = NSOpenPanel()
		panel.canChooseDirectories = true
		panel.canChooseFiles = false
		panel.directoryURL = Self.defaultFolder(for: midnam)
		panel.beginSheetModal(for: w) { [weak self] r in
			guard r == .OK, let url = panel.url else { return }
			UserDefaults.standard.set(url.path, forKey: Self.folderKey)
			self?.scan(folder: url)
		}
	}

	private func selectFile(_ row: Int) {
		guard files.indices.contains(row), let doc = Self.read(files[row].url), let model = midnam.model else {
			source = nil
			lists = []
			listsTable.reloadData()
			updateImportButton()
			return
		}
		source = doc
		lists = doc.importableLists()
		let master = Self.master(of: model)
		destinations = lists.map { l in
			master.flatMap { model.proposedImportDestination(l, master: $0) }.flatMap { model.bank($0)?.name }.map(Destination.bank)
				?? .none
		}
		listsTable.reloadData()
		fitColumns(listsTable)
		updateImportButton()
	}

	/// Cada columna al ancho de su texto más largo (cabecera incluida; EXP-019: se cortaban los nombres).
	private func fitColumns(_ table: NSTableView) {
		let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
		func width(_ s: String) -> CGFloat { (s as NSString).size(withAttributes: [.font: font]).width }
		for col in table.tableColumns {
			let texts: [String]
			switch col.identifier.rawValue {
			case "midnam": texts = files.map(\.url.lastPathComponent)
			case "type": texts = files.map(\.type)
			case "name": texts = lists.map(\.name)
			case "count": texts = lists.map { String($0.count) }
			default: texts = ["Add as New Bank"] + (midnam.model.map { BankRows.rows($0).map(\.name) } ?? [])
			}
			let extra: CGFloat = col.identifier.rawValue == "destination" ? 40 : 16
			col.width = max(width(col.title) + 16, (texts.map(width).max() ?? 0) + extra)
		}
	}

	private static func master(of doc: MIDINameDocument) -> Int? {
		doc.items.indices.first { if case .masterDeviceNames = doc.items[$0] { return true }; return false }
	}

	// MARK: Tablas

	func numberOfRows(in tableView: NSTableView) -> Int { tableView === filesTable ? files.count : lists.count }

	func tableViewSelectionDidChange(_ notification: Notification) {
		if (notification.object as? NSTableView) === filesTable { selectFile(filesTable.selectedRow) }
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let id = tableColumn?.identifier.rawValue
		if tableView === filesTable {
			let f = NSTextField(labelWithString: id == "type" ? files[row].type : files[row].url.lastPathComponent)
			f.lineBreakMode = .byTruncatingTail
			f.toolTip = files[row].url.path
			return f
		}
		let l = lists[row]
		switch id {
		case "name":
			let f = NSTextField(labelWithString: l.name)
			f.lineBreakMode = .byTruncatingTail
			return f
		case "count":
			return NSTextField(labelWithString: String(l.count))
		default:
			let popup = NSPopUpButton()
			popup.isBordered = false
			popup.controlSize = .small
			// «Add as New Bank» y no «New Bank»: un banco puede llamarse así (P13; EXP-019). Los bancos van por su
			// nombre en `representedObject`, no por el título.
			popup.addItem(withTitle: "-")
			popup.addItem(withTitle: "Add as New Bank")
			popup.menu?.addItem(.separator())
			let banks = midnam.model.map { m in BankRows.rows(m).filter { $0.ref.master == Self.master(of: m) }.map(\.name) } ?? []
			for b in banks {
				popup.addItem(withTitle: b)
				popup.lastItem?.representedObject = b
			}
			switch destinations[row] {
			case .none: popup.selectItem(at: 0)
			case .newBank: popup.selectItem(at: 1)
			case .bank(let n): popup.selectItem(at: popup.itemArray.firstIndex { $0.representedObject as? String == n } ?? 0)
			}
			popup.tag = row
			popup.target = self
			popup.action = #selector(destinationChanged(_:))
			return popup
		}
	}

	@objc private func destinationChanged(_ sender: NSPopUpButton) {
		guard destinations.indices.contains(sender.tag) else { return }
		switch sender.indexOfSelectedItem {
		case 0: destinations[sender.tag] = .none
		case 1: destinations[sender.tag] = .newBank
		default: destinations[sender.tag] = (sender.selectedItem?.representedObject as? String).map(Destination.bank) ?? .none
		}
		updateImportButton()
	}

	private func updateImportButton() {
		importButton.isEnabled = source != nil && destinations.contains { $0 != .none }
	}

	// MARK: Botones

	@objc private func doImport(_ sender: Any?) {
		guard let source, let model = midnam.model, let master = Self.master(of: model) else { return }
		let jobs = zip(lists, destinations).filter { $0.1 != .none }
		do {
			try midnam.edit("Import") { doc in
				let sets = doc.channelSets(master: master)
				for (list, dest) in jobs {
					switch dest {
					case .none: break
					case .bank(let name):
						guard let ref = BankRows.rows(doc).first(where: { $0.ref.master == master && $0.name == name })?.ref
						else { throw BankEditError.notFound }
						try doc.importList(list, from: source, into: ref)
					case .newBank:
						// En el Channel Set del mismo nombre que el de origen, o en el primero.
						let srcSet = source.channelSetName(list.bank)
						guard let set = sets.first(where: { $0.name == srcSet })?.index ?? sets.first?.index else {
							throw BankEditError.notFound
						}
						try doc.importListAsNewBank(list, from: source, master: master, set: set)
					}
				}
			}
		} catch {
			NSAlert(error: error).beginSheetModal(for: window!)
			return
		}
		close(sender)
	}

	@objc private func cancel(_ sender: Any?) { close(sender) }

	private func close(_ sender: Any?) {
		guard let w = window else { return }
		w.sheetParent?.endSheet(w)
		completion?()
		completion = nil
	}
}

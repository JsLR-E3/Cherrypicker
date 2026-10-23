// Asistente «Device Setup» (nib SetupWizard; docs/20 §3.4; T-023), con File ▸ New. Pasos del original:
// 1) «Manufacturer:» / «Model:» con autocompletado desde los `.middev` de /Library/Audio/MIDI Devices y aviso de
// coincidencia sin mayúsculas; 2) si el modelo está en un `.middev` (DP lo necesita, EXP-006; aquí no se escribe:
// regla 3); 3) «Do all patch banks play on all channels?» y, si no, cuántos grupos; 4) tabla «Name» / «Uses Channels»;
// 5) «Setup Finished» y «Go», que abre el documento nuevo sin guardar. Sin «Launch AudioMIDI Setup» (EXP-006).
import AppKit
import CherryPickerCore
import MidnamKit

final class SetupWizardController: NSWindowController, NSComboBoxDelegate, NSTableViewDataSource, NSTableViewDelegate,
	NSTextFieldDelegate {
	private static var current: SetupWizardController?

	private let steps = NSTabView()
	private let nextButton = NSButton(title: "Next", target: nil, action: nil)
	private let manufacturer = NSComboBox()
	private let model = NSComboBox()
	private let closeMatchLabel = NSTextField(labelWithString: "")
	private let middevLabel = NSTextField(wrappingLabelWithString: "")
	private let yes = NSButton(radioButtonWithTitle: "Yes", target: nil, action: nil)
	private let no = NSButton(radioButtonWithTitle: "No", target: nil, action: nil)
	private let numSets = NSTextField(string: "2")
	private let setsTable = NSTableView()
	private var specs: [ChannelSetSpec] = []
	/// Fabricante y modelo de cada `.middev` encontrado, con su fichero.
	private var entries: [(manufacturer: String, model: String, file: URL)] = []

	static func show() {
		if let c = current {
			c.showWindow(nil)
			return
		}
		let c = SetupWizardController()
		current = c
		c.showWindow(nil)
	}

	private init() {
		let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 360), styleMask: [.titled, .closable],
		                      backing: .buffered, defer: false)
		window.title = "Device Setup"
		super.init(window: window)
		loadMiddevs()
		window.contentView = makeContent()
		window.center()
		NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
			SetupWizardController.current = nil
		}
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	/// Lee (sin modificarlos) los `.middev` de la carpeta de dispositivos MIDI.
	private func loadMiddevs() {
		let root = URL(fileURLWithPath: "/Library/Audio/MIDI Devices")
		let e = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
		while let url = e?.nextObject() as? URL {
			guard url.pathExtension.lowercased() == "middev", let data = try? Data(contentsOf: url),
			      let text = String(data: data, encoding: .utf8) else { continue }
			entries += middevEntries(text).map { ($0.manufacturer, $0.model, url) }
		}
	}

	private var manufacturers: [String] {
		Array(Set(entries.map(\.manufacturer))).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
	}

	private func models(of maker: String) -> [String] {
		Array(Set(entries.filter { $0.manufacturer == maker }.map(\.model))).sorted {
			$0.localizedStandardCompare($1) == .orderedAscending
		}
	}

	// MARK: Pasos

	private func makeContent() -> NSView {
		steps.tabViewType = .noTabsNoBorder
		for (i, v) in [stepDevice(), stepMiddev(), stepChannels(), stepSets(), stepFinished()].enumerated() {
			let item = NSTabViewItem(identifier: i)
			item.view = v
			steps.addTabViewItem(item)
		}
		let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
		cancel.keyEquivalent = "\u{1b}"
		nextButton.target = self
		nextButton.action = #selector(next(_:))
		nextButton.keyEquivalent = "\r"
		let root = NSView()
		for v in [steps, cancel, nextButton] as [NSView] {
			v.translatesAutoresizingMaskIntoConstraints = false
			root.addSubview(v)
		}
		NSLayoutConstraint.activate([
			steps.topAnchor.constraint(equalTo: root.topAnchor, constant: 16),
			steps.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 20),
			steps.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
			nextButton.topAnchor.constraint(equalTo: steps.bottomAnchor, constant: 12),
			nextButton.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
			nextButton.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -16),
			cancel.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor),
			cancel.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -8),
			root.widthAnchor.constraint(equalToConstant: 520),
			root.heightAnchor.constraint(equalToConstant: 360),
		])
		updateNext()
		return root
	}

	private static func stack(_ views: [NSView]) -> NSView {
		let s = NSStackView(views: views)
		s.orientation = .vertical
		s.alignment = .leading
		s.spacing = 10
		let v = NSView()
		s.translatesAutoresizingMaskIntoConstraints = false
		v.addSubview(s)
		NSLayoutConstraint.activate([
			s.topAnchor.constraint(equalTo: v.topAnchor),
			s.leadingAnchor.constraint(equalTo: v.leadingAnchor),
			s.trailingAnchor.constraint(lessThanOrEqualTo: v.trailingAnchor),
		])
		return v
	}

	private static func note(_ s: String) -> NSTextField {
		let l = NSTextField(wrappingLabelWithString: s)
		l.textColor = .secondaryLabelColor
		l.preferredMaxLayoutWidth = 470
		return l
	}

	private func stepDevice() -> NSView {
		for c in [manufacturer, model] {
			c.completes = true
			c.delegate = self
			c.widthAnchor.constraint(equalToConstant: 260).isActive = true
		}
		manufacturer.addItems(withObjectValues: manufacturers)
		closeMatchLabel.textColor = .systemOrange
		let grid = NSGridView(views: [[NSTextField(labelWithString: "Manufacturer:"), manufacturer],
		                              [NSTextField(labelWithString: "Model:"), model]])
		grid.column(at: 0).xPlacement = .trailing
		grid.rowSpacing = 8
		return Self.stack([grid, closeMatchLabel,
		                   Self.note("Type or select entry from list. Use <tab> <return> or <enter> to set.")])
	}

	private func stepMiddev() -> NSView {
		middevLabel.preferredMaxLayoutWidth = 470
		return Self.stack([middevLabel])
	}

	private func stepChannels() -> NSView {
		for b in [yes, no] {
			b.target = self
			b.action = #selector(radio(_:))
		}
		yes.state = .on
		numSets.widthAnchor.constraint(equalToConstant: 40).isActive = true
		numSets.delegate = self
		let count = NSStackView(views: [NSTextField(labelWithString: "How many distinct sets of channels are there?"), numSets])
		return Self.stack([
			NSTextField(labelWithString: "Do all patch banks play on all channels?"),
			NSStackView(views: [yes, no]),
			Self.note("Some synths reserve special channels for specific uses. For example, Roland often uses channel 10 for drums."),
			count,
			Self.note("Roland often uses 2 sets: 1) channel 10 for drums; 2) channels 1-9, 11-16 for everything else."),
		])
	}

	private func stepSets() -> NSView {
		for (id, title, w) in [("name", "Name", 200.0), ("channels", "Uses Channels", 220.0)] {
			let c = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
			c.title = title
			c.width = w
			setsTable.addTableColumn(c)
		}
		setsTable.dataSource = self
		setsTable.delegate = self
		let scroll = NSScrollView()
		scroll.documentView = setsTable
		scroll.hasVerticalScroller = true
		scroll.borderType = .bezelBorder
		scroll.heightAnchor.constraint(equalToConstant: 130).isActive = true
		scroll.widthAnchor.constraint(equalToConstant: 470).isActive = true
		return Self.stack([
			Self.note("Enter a name in the table below for each 'kind' of patch bank that plays on special channels (eg: Drums). Enter the special channels for each one: individual channel numbers or ranges separated by commas, e.g. 1-9, 11-16 or 3, 7, 12-14."),
			scroll,
		])
	}

	private func stepFinished() -> NSView {
		let title = NSTextField(labelWithString: "Setup Finished")
		title.font = .boldSystemFont(ofSize: NSFont.systemFontSize + 2)
		return Self.stack([title, NSTextField(labelWithString: "Press \"Go\" to start adding banks and patches.")])
	}

	private var stepIndex: Int { steps.selectedTabViewItem.map { steps.indexOfTabViewItem($0) } ?? 0 }

	private var allChannels: Bool { yes.state == .on }

	private func updateNext() {
		nextButton.title = stepIndex == 4 ? "Go" : "Next"
		switch stepIndex {
		case 0:
			let m = manufacturer.stringValue.trimmingCharacters(in: .whitespaces)
			let mo = model.stringValue.trimmingCharacters(in: .whitespaces)
			nextButton.isEnabled = !m.isEmpty && !mo.isEmpty
		case 2:
			numSets.isEnabled = !allChannels
			nextButton.isEnabled = allChannels || (Int(numSets.stringValue).map { (2...16).contains($0) } ?? false)
		default:
			nextButton.isEnabled = true
		}
	}

	@objc private func radio(_ sender: NSButton) {
		yes.state = sender === yes ? .on : .off
		no.state = sender === no ? .on : .off
		updateNext()
	}

	@objc private func next(_ sender: Any?) {
		switch stepIndex {
		case 0:
			showMiddevStep()
			steps.selectTabViewItem(at: 1)
		case 1:
			steps.selectTabViewItem(at: 2)
		case 2:
			if allChannels {
				specs = []
				steps.selectTabViewItem(at: 4)
			} else {
				let n = Int(numSets.stringValue) ?? 2
				if specs.count != n { specs = defaultChannelSets(count: n) }
				setsTable.reloadData()
				steps.selectTabViewItem(at: 3)
			}
		case 3:
			view(endEditing: true)
			do {
				_ = try MidnamFile.newDevice(manufacturer: "x", model: "x", sets: specs)
			} catch {
				NSAlert(error: error).beginSheetModal(for: window!)
				return
			}
			steps.selectTabViewItem(at: 4)
		default:
			go()
			return
		}
		updateNext()
	}

	private func view(endEditing: Bool) { window?.makeFirstResponder(nil) }

	private func showMiddevStep() {
		let m = manufacturer.stringValue.trimmingCharacters(in: .whitespaces)
		let mo = model.stringValue.trimmingCharacters(in: .whitespaces)
		if let e = entries.first(where: { $0.manufacturer == m && $0.model == mo }) {
			middevLabel.stringValue = "“\(m) \(mo)” is in the middev file:\n\(e.file.path)\n\nDigital Performer will show the patch names for this model."
		} else {
			middevLabel.stringValue = "There is no middev entry for “\(m) \(mo)” yet.\n\nDigital Performer only shows patch names for models that are in a middev file. CherryPicker does not change the MIDI Devices folder by itself: the entry has to be added before using the file in Digital Performer."
		}
	}

	// MARK: Paso 1

	func comboBoxSelectionDidChange(_ notification: Notification) {
		DispatchQueue.main.async { [weak self] in self?.deviceChanged() }
	}

	func controlTextDidChange(_ obj: Notification) {
		if obj.object as? NSTextField === numSets { updateNext() } else { deviceChanged() }
	}

	private func deviceChanged() {
		let m = manufacturer.stringValue.trimmingCharacters(in: .whitespaces)
		let models = models(of: m)
		if (model.objectValues as? [String]) != models {
			model.removeAllItems()
			model.addItems(withObjectValues: models)
		}
		let match = closeMatch(m, in: manufacturers).map { "Manufacturer: \($0)" }
			?? closeMatch(model.stringValue, in: models).map { "Model: \($0)" }
		closeMatchLabel.stringValue = match.map { "CherryPicker found a close match (cases were different) — \($0)" } ?? ""
		updateNext()
	}

	// MARK: Paso 4

	func numberOfRows(in tableView: NSTableView) -> Int { specs.count }

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let id = tableColumn?.identifier.rawValue ?? ""
		let f = NSTextField(string: id == "name" ? specs[row].name : specs[row].channels)
		f.isBordered = false
		f.drawsBackground = false
		f.identifier = NSUserInterfaceItemIdentifier(id)
		f.tag = row
		f.target = self
		f.action = #selector(cellEdited(_:))
		return f
	}

	@objc private func cellEdited(_ sender: NSTextField) {
		guard specs.indices.contains(sender.tag) else { return }
		if sender.identifier?.rawValue == "name" { specs[sender.tag].name = sender.stringValue }
		else { specs[sender.tag].channels = sender.stringValue }
	}

	// MARK: Botones

	@objc private func cancel(_ sender: Any?) { close() }

	private func go() {
		do {
			let file = try MidnamFile.newDevice(manufacturer: manufacturer.stringValue, model: model.stringValue, sets: specs)
			try MidnamDocument.openUntitled(text: file.text())
			close()
		} catch {
			NSAlert(error: error).beginSheetModal(for: window!)
		}
	}
}

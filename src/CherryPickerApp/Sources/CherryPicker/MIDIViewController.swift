// Pestaña MIDI (nib MainWindow; docs/20 §3.1; disposición de la captura del original, T-021): caja «MIDI Connections»
// con «Device Out» (destinos de CoreMIDI; «None» = no se envía) y «Enable MIDI» (desactivado al abrir, P5). Sin
// «Controller In»: el thru del teclado queda fuera por ahora (docs/20 §7.3). Debajo, «Test Note» (D-008, P16): nota
// que se toca tras el cambio de programa, para módulos de sonido; desactivada por defecto y recordada por dispositivo.
import AppKit
import CherryPickerCore
import CoreMIDI

final class MIDIViewController: NSViewController, NSTextFieldDelegate {
	private let document: MidnamDocument
	private let deviceOut = NSPopUpButton()
	private let enable = NSButton(checkboxWithTitle: "Enable MIDI", target: nil, action: nil)
	private let testNote = NSButton(checkboxWithTitle: "Test Note", target: nil, action: nil)
	private let noteField = NSTextField(string: "")
	private let noteName = NSTextField(labelWithString: "")
	private let velocityField = NSTextField(string: "")
	private let lengthField = NSTextField(string: "")

	init(document: MidnamDocument) {
		self.document = document
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	deinit { NotificationCenter.default.removeObserver(self) }

	override func loadView() {
		deviceOut.autoenablesItems = false
		deviceOut.target = self
		deviceOut.action = #selector(deviceOutChanged(_:))
		deviceOut.toolTip = "Device that receives the bank select and program change of the selected patch"
		enable.target = self
		enable.action = #selector(enableChanged(_:))
		enable.toolTip = "Send bank select and program change when a patch is selected"

		testNote.target = self
		testNote.action = #selector(testNoteChanged(_:))
		testNote.toolTip = "Also play a note after the program change (for sound modules; off for effects units)"
		noteField.toolTip = "Note number (60 = C3)"
		velocityField.toolTip = "Velocity (1–127)"
		lengthField.toolTip = "Length in milliseconds"
		for f in [noteField, velocityField, lengthField] {
			f.delegate = self
			f.alignment = .right
			f.widthAnchor.constraint(equalToConstant: 48).isActive = true
		}
		noteName.textColor = .secondaryLabelColor
		let note = NSStackView(views: [noteField, noteName])
		note.spacing = 6

		let grid = NSGridView(views: [
			[NSTextField(labelWithString: "Device Out"), deviceOut], [NSView(), enable],
			[NSView(), testNote], [NSTextField(labelWithString: "Note"), note],
			[NSTextField(labelWithString: "Velocity"), velocityField], [NSTextField(labelWithString: "Length (ms)"), lengthField],
		])
		grid.rowSpacing = 10
		grid.row(at: 2).topPadding = 8
		grid.column(at: 0).xPlacement = .trailing
		deviceOut.widthAnchor.constraint(equalToConstant: 200).isActive = true
		let box = NSBox()
		box.title = "MIDI Connections"
		let content = NSView()
		box.contentView = content
		grid.translatesAutoresizingMaskIntoConstraints = false
		content.addSubview(grid)
		let root = NSView()
		box.translatesAutoresizingMaskIntoConstraints = false
		root.addSubview(box)
		NSLayoutConstraint.activate([
			grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 10),
			grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
			grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
			grid.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12),
			box.topAnchor.constraint(equalTo: root.topAnchor, constant: 24),
			box.centerXAnchor.constraint(equalTo: root.centerXAnchor),
		])
		view = root

		NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: MIDIOut.destinationsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: AuditionSettings.didChange,
		                                       object: document.audition)
		refresh()
	}

	@objc private func refresh() {
		let settings = document.audition
		deviceOut.removeAllItems()
		deviceOut.addItem(withTitle: "None")
		deviceOut.lastItem?.tag = 0
		var found = false
		for d in MIDIOut.shared.destinations {
			deviceOut.addItem(withTitle: d.name)
			deviceOut.lastItem?.representedObject = d.id
			if d.id == settings.destination {
				deviceOut.select(deviceOut.lastItem)
				found = true
			}
		}
		// Un destino recordado que no está conectado se muestra, pero no se puede usar.
		if let id = settings.destination, !found {
			deviceOut.addItem(withTitle: "(not connected)")
			deviceOut.lastItem?.representedObject = id
			deviceOut.lastItem?.isEnabled = false
			deviceOut.select(deviceOut.lastItem)
		}
		if settings.destination == nil { deviceOut.selectItem(at: 0) }
		enable.state = settings.enabled ? .on : .off
		testNote.state = settings.testNoteEnabled ? .on : .off
		let n = settings.testNote
		noteField.integerValue = n.note
		noteName.stringValue = TestNote.name(n.note)
		velocityField.integerValue = n.velocity
		lengthField.integerValue = n.length
		for f in [noteField, velocityField, lengthField] { f.isEnabled = settings.testNoteEnabled }
	}

	@objc private func testNoteChanged(_ sender: NSButton) {
		document.audition.testNoteEnabled = sender.state == .on
	}

	/// Valores fuera de rango: aviso sonoro y se vuelve al anterior.
	func controlTextDidEndEditing(_ obj: Notification) {
		guard let field = obj.object as? NSTextField else { return }
		var n = document.audition.testNote
		let v = Int(field.stringValue.trimmingCharacters(in: .whitespaces))
		switch field {
		case noteField: if let v, (0...127).contains(v) { n.note = v } else { NSSound.beep() }
		case velocityField: if let v, (1...127).contains(v) { n.velocity = v } else { NSSound.beep() }
		case lengthField: if let v, TestNote.lengths.contains(v) { n.length = v } else { NSSound.beep() }
		default: return
		}
		if n != document.audition.testNote { document.audition.testNote = n } else { refresh() }
	}

	@objc private func deviceOutChanged(_ sender: NSPopUpButton) {
		document.audition.destination = sender.selectedItem?.representedObject as? MIDIUniqueID
	}

	@objc private func enableChanged(_ sender: NSButton) {
		document.audition.enabled = sender.state == .on
		if sender.state == .off { document.endTestNote() }
	}
}

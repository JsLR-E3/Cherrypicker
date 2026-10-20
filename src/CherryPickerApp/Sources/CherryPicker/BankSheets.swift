// Hojas de la pestaña Patch Banks (nibs BankSheet y BankSelectSheet; textos literales, docs/20 §3.3).
import AppKit
import CherryPickerCore

/// Ventana de hoja con una rejilla de filas y los botones de pie (el último, el botón por defecto).
class SheetController: NSWindowController {
	private var completion: ((Bool) -> Void)?
	let okButton: NSButton

	init(title: String, rows: [[NSView]], okTitle: String) {
		let window = NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: false)
		okButton = NSButton(title: okTitle, target: nil, action: nil)
		super.init(window: window)

		let box = NSBox()
		box.title = title
		if title.isEmpty { box.titlePosition = .noTitle }
		let grid = NSGridView(views: rows)
		grid.rowSpacing = 8
		grid.columnSpacing = 8
		grid.column(at: 0).xPlacement = .trailing
		for (i, r) in rows.enumerated() where r.count == 1 {
			grid.mergeCells(inHorizontalRange: NSRange(location: 0, length: grid.numberOfColumns),
			                verticalRange: NSRange(location: i, length: 1))
			grid.cell(atColumnIndex: 0, rowIndex: i).xPlacement = .leading
		}
		// La rejilla va dentro de la vista de contenido de la caja (bajo su título), no sobre la caja.
		let content = NSView()
		box.contentView = content
		grid.translatesAutoresizingMaskIntoConstraints = false
		content.addSubview(grid)
		NSLayoutConstraint.activate([
			grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
			grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
			grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 8),
			grid.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12),
		])

		let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
		cancel.keyEquivalent = "\u{1b}"
		okButton.target = self
		okButton.action = #selector(ok(_:))
		okButton.keyEquivalent = "\r"
		let buttons = NSStackView(views: [cancel, okButton])

		let root = NSView()
		for v in [box, buttons] as [NSView] {
			v.translatesAutoresizingMaskIntoConstraints = false
			root.addSubview(v)
		}
		NSLayoutConstraint.activate([
			box.topAnchor.constraint(equalTo: root.topAnchor, constant: 16),
			box.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
			box.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
			buttons.topAnchor.constraint(equalTo: box.bottomAnchor, constant: 12),
			buttons.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
			buttons.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -16),
			root.widthAnchor.constraint(greaterThanOrEqualToConstant: 380),
		])
		window.contentView = root
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	func begin(on parent: NSWindow, completion: @escaping (Bool) -> Void) {
		self.completion = completion
		parent.beginSheet(window!)
	}

	/// Comprobación antes de cerrar con OK; si lanza, se muestra el error y la hoja sigue abierta.
	func commit() throws {}

	@objc func ok(_ sender: Any?) {
		do {
			try commit()
		} catch {
			NSAlert(error: error).beginSheetModal(for: window!)
			return
		}
		finish(true)
	}

	@objc func cancel(_ sender: Any?) { finish(false) }

	private func finish(_ ok: Bool) {
		guard let w = window else { return }
		w.sheetParent?.endSheet(w)
		completion?(ok)
		completion = nil
	}

	static func label(_ s: String) -> NSTextField { NSTextField(labelWithString: s) }

	static func field(_ s: String, width: CGFloat) -> NSTextField {
		let f = NSTextField(string: s)
		f.widthAnchor.constraint(equalToConstant: width).isActive = true
		return f
	}
}

/// «Add a Single Bank» (BankSheet): Channel Set, Name, B Sel0, B Sel32; «Add» solo con un nombre válido.
final class AddBankSheet: SheetController, NSTextFieldDelegate {
	let channelSet = NSPopUpButton()
	let name = SheetController.field("", width: 240)
	let bs0 = SheetController.field("-", width: 50)
	let bs32 = SheetController.field("-", width: 50)
	private let isNameAvailable: (String) -> Bool

	/// Lo que se añadirá: se lee al cerrar con «Add».
	var onCommit: ((_ setIndex: Int, _ name: String, _ bs0: String, _ bs32: String) throws -> Void)?

	init(channelSets: [(index: Int, name: String)], selectedSet: Int?, isNameAvailable: @escaping (String) -> Bool) {
		self.isNameAvailable = isNameAvailable
		for s in channelSets {
			channelSet.addItem(withTitle: s.name)
			channelSet.lastItem?.tag = s.index
		}
		if let sel = selectedSet { channelSet.selectItem(withTag: sel) }
		channelSet.toolTip = "Set of channels that the new bank will play on"
		name.toolTip = "Name must be entered and unique"
		bs0.toolTip = "Bank Select 0 value, or '-' if not used"
		bs32.toolTip = "Bank Select 32 value, or '-' if not used"
		// Orden del original (EXP-009): Name; B Sel0 y B Sel32 en una fila; Channel Set.
		super.init(title: "Add a Single Bank", rows: [
			[Self.label("Name"), name],
			[Self.label("B Sel0"), bs0, Self.label("B Sel32"), bs32],
			[Self.label("Channel Set"), channelSet],
		], okTitle: "Add")
		okButton.toolTip = "Enabled if there is a valid bank name"
		name.delegate = self
		validate()
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	func controlTextDidChange(_ obj: Notification) { validate() }

	private func validate() {
		let n = name.stringValue.trimmingCharacters(in: .whitespaces)
		okButton.isEnabled = !n.isEmpty && isNameAvailable(n)
	}

	override func commit() throws {
		try onCommit?(channelSet.selectedTag(), name.stringValue, bs0.stringValue, bs32.stringValue)
	}
}

/// Hoja para elegir el Channel Set de varios bancos (clic en la cabecera «Channel Set»). El manual del original solo
/// dice que «cae una hoja» con un popup; su aspecto no se ha visto (deducido).
final class ChannelSetSheet: SheetController {
	let channelSet = NSPopUpButton()
	var onCommit: ((_ setIndex: Int) throws -> Void)?

	init(channelSets: [(index: Int, name: String)], selected: Int?) {
		for s in channelSets {
			channelSet.addItem(withTitle: s.name)
			channelSet.lastItem?.tag = s.index
		}
		if let selected { channelSet.selectItem(withTag: selected) }
		super.init(title: "", rows: [[Self.label("Channel Set"), channelSet]], okTitle: "OK")
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	override func commit() throws { try onCommit?(channelSet.selectedTag()) }
}

/// Hoja «Bank Selects» (BankSelectSheet): valores nuevos y cómo afectan a los patches del banco.
final class BankSelectSheet: SheetController {
	let bs0 = SheetController.field("", width: 50)
	let bs32 = SheetController.field("", width: 50)
	private let radios: [(NSButton, BankSelectApply)] = BankSelectSheet.options.map {
		(NSButton(radioButtonWithTitle: $0.0, target: nil, action: nil), $0.1)
	}

	var onCommit: ((_ bs0: String, _ bs32: String, _ apply: BankSelectApply) throws -> Void)?

	private static let options: [(String, BankSelectApply)] = [
		("Apply to all patches", .allPatches),
		("Apply ONLY to patches without Bank Selects", .patchesWithoutBankSelects),
		("Apply Only to patches with Bank Selects", .patchesWithBankSelects),
	]

	init(bankName: String, bs0 current0: String, bs32 current32: String) {
		let buttons = radios.map(\.0)
		// Orden del original (EXP-009): valores arriba, opciones debajo; sin título.
		var rows: [[NSView]] = [[Self.label("B Sel 0"), bs0, Self.label("B Sel 32"), bs32]]
		for b in buttons { rows.append([b]) }
		super.init(title: "", rows: rows, okTitle: "OK")
		for b in buttons {
			b.target = self
			b.action = #selector(radioChanged(_:))
		}
		buttons[0].state = .on
		bs0.stringValue = current0
		bs32.stringValue = current32
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	@objc private func radioChanged(_ sender: NSButton) {
		for (b, _) in radios { b.state = b === sender ? .on : .off }
	}

	override func commit() throws {
		let apply = radios.first { $0.0.state == .on }?.1 ?? .allPatches
		try onCommit?(bs0.stringValue, bs32.stringValue, apply)
	}
}

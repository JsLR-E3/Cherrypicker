// Hoja «Install in DP…» (File ▸ Install in DP…, [PROPUESTA P3], T-024). Dice adónde se copiará el fichero, deja
// cambiar su nombre (el que DP muestra en *Master Names*) y, si el modelo no está en ningún `.middev`, ofrece añadirlo
// al de la app (marcado). Nada se escribe hasta pulsar «Install» (regla 3). Si se sustituye un fichero, antes se
// guarda una copia en ~/Library/Application Support/CherryPicker/Backups/; al terminar se explica cómo deshacerlo.
import AppKit
import CherryPickerCore

/// Fabricantes y modelos declarados en los `.middev` de /Library/Audio/MIDI Devices (solo se leen).
enum MiddevIndex {
	static func load() -> [(manufacturer: String, model: String, file: URL)] {
		var out: [(String, String, URL)] = []
		let e = FileManager.default.enumerator(at: URL(fileURLWithPath: "/Library/Audio/MIDI Devices"),
		                                       includingPropertiesForKeys: nil)
		while let url = e?.nextObject() as? URL {
			guard url.pathExtension.lowercased() == "middev", let data = try? Data(contentsOf: url),
			      let text = String(data: data, encoding: .utf8) else { continue }
			out += middevEntries(text).map { ($0.manufacturer, $0.model, url) }
		}
		return out
	}
}

final class InstallSheet: SheetController {
	private let midnam: MidnamDocument
	private let manufacturer: String
	private let model: String
	private let name: NSTextField
	private let addMiddev = NSButton(checkboxWithTitle: "", target: nil, action: nil)
	private let listed: URL?
	/// Lo que se ha hecho, para el aviso final.
	private(set) var report = ""

	init(document: MidnamDocument) {
		midnam = document
		let m = document.model?.masterDeviceNames.first
		let maker = m?.manufacturer ?? "", device = m?.models.first ?? ""
		manufacturer = maker
		model = device
		listed = MiddevIndex.load().first { $0.manufacturer == maker && $0.model == device }?.file
		// Sin guardar, el modelo (EXP-022: «Untitled» no dice nada en Master Names).
		let base = document.fileURL?.deletingPathExtension().lastPathComponent ?? device
		name = Self.field(base, width: 260)
		name.toolTip = "Name shown in DP's Master Names"
		let folder = InstallInDP.folder(manufacturer: maker)
		var rows: [[NSView]] = [
			[Self.label("Manufacturer:"), Self.label(maker)],
			[Self.label("Model:"), Self.label(device)],
			[Self.label("Folder:"), Self.wrapping(folder.path)],
			[Self.label("File name:"), name],
		]
		if let listed {
			rows.append([Self.wrapping("“\(device)” is already in \(listed.lastPathComponent): DP lists it.")])
		} else {
			// Título corto y explicación aparte: un título largo ensanchaba la hoja (EXP-022).
			addMiddev.title = "Add the model to the device lists"
			addMiddev.state = .on
			rows.append([addMiddev])
			rows.append([Self.wrapping("Writes it in \(InstallInDP.middevName(manufacturer: maker)), in the same folder. Without it, DP still uses the file if you type the manufacturer and model exactly in Audio MIDI Setup.")])
		}
		rows.append([Self.wrapping("After installing, restart DP or choose the file again in Master Names (MIDI Device Properties ▸ Patches).")])
		super.init(title: "Install in Digital Performer", rows: rows, okTitle: "Install")
		okButton.isEnabled = !maker.isEmpty && !device.isEmpty
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	private static func wrapping(_ s: String) -> NSTextField {
		let l = NSTextField(wrappingLabelWithString: s)
		l.preferredMaxLayoutWidth = 400
		l.textColor = .secondaryLabelColor
		return l
	}

	override func commit() throws {
		let fm = FileManager.default
		let folder = InstallInDP.folder(manufacturer: manufacturer)
		let target = folder.appendingPathComponent(InstallInDP.midnamName(name.stringValue))
		let data = try midnam.data(ofType: MidnamDocument.typeName)
		if fm.fileExists(atPath: target.path), !confirmReplace(target) { throw CancelError() }
		try fm.createDirectory(at: folder, withIntermediateDirectories: true)
		var done: [String] = []
		var undo: [String] = []
		if let backup = try backupIfExists(target) {
			done.append("Previous file saved to \(backup.path)")
			undo.append("copy it back to \(folder.path)")
		} else {
			undo.append("delete \(target.lastPathComponent)")
		}
		try data.write(to: target, options: .atomic)
		done.insert("Installed \(target.path)", at: 0)
		if listed == nil, addMiddev.state == .on {
			let middev = folder.appendingPathComponent(InstallInDP.middevName(manufacturer: manufacturer))
			let old = fm.fileExists(atPath: middev.path) ? try String(contentsOf: middev, encoding: .utf8) : nil
			if let backup = try backupIfExists(middev) {
				undo.append("copy \(backup.path) back")
			} else {
				undo.append("delete \(middev.lastPathComponent)")
			}
			try InstallInDP.middev(adding: manufacturer, model: model, to: old).write(to: middev, atomically: true, encoding: .utf8)
			done.append("Added “\(manufacturer) \(model)” to \(middev.path)")
		}
		report = done.joined(separator: "\n") + "\n\nTo undo: " + undo.joined(separator: "; ") + "."
	}

	private struct CancelError: LocalizedError {
		var errorDescription: String? { "The file was not installed." }
	}

	private func confirmReplace(_ url: URL) -> Bool {
		let a = NSAlert()
		a.messageText = "Replace “\(url.lastPathComponent)”?"
		a.informativeText = "There is already a file with this name in \(url.deletingLastPathComponent().path). A copy of it will be kept in CherryPicker's Backups folder."
		a.addButton(withTitle: "Replace")
		a.addButton(withTitle: "Cancel")
		return a.runModal() == .alertFirstButtonReturn
	}

	/// Copia el fichero (si existe) a ~/Library/Application Support/CherryPicker/Backups/<fecha>/.
	private func backupIfExists(_ url: URL) throws -> URL? {
		let fm = FileManager.default
		guard fm.fileExists(atPath: url.path) else { return nil }
		let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
		let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
			.appendingPathComponent("CherryPicker/Backups/\(stamp)", isDirectory: true)
		try fm.createDirectory(at: dir, withIntermediateDirectories: true)
		let copy = dir.appendingPathComponent(url.lastPathComponent)
		try fm.copyItem(at: url, to: copy)
		return copy
	}
}

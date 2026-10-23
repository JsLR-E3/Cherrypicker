// Asistente «Device Setup» (File ▸ New; nib SetupWizard; docs/20 §3.4 y §4 flujo 1; T-023): fabricante y modelo
// (autocompletados con los `.middev`), si todos los bancos suenan en todos los canales y, si no, los grupos de canales
// con su nombre. Crea un documento con un modo «Mode 1», un Channel Set por grupo y un banco vacío en cada uno (P13).
// DOCTYPE de la 1.0 con la URL de midi.org (D-003). El `.middev` no se escribe aquí (regla 3).
import Foundation
import MidnamKit

/// Un grupo de canales del paso 4 («Name» / «Uses Channels»).
public struct ChannelSetSpec: Equatable, Sendable {
	public var name: String
	public var channels: String

	public init(name: String, channels: String) {
		self.name = name
		self.channels = channels
	}
}

public enum NewDeviceError: LocalizedError, Equatable {
	case emptyManufacturer
	case emptyModel
	case emptySetName
	case duplicateSetName(String)
	case noChannels(String)
	case overlapping([Int])

	public var errorDescription: String? {
		switch self {
		case .emptyManufacturer: return "A manufacturer must be entered."
		case .emptyModel: return "A model must be entered."
		case .emptySetName: return "Each set of channels needs a name."
		case .duplicateSetName(let n): return "There are two sets named “\(n)”. Names must be unique."
		case .noChannels(let n): return "“\(n)” must use at least one channel."
		case .overlapping(let c): return "Channel\(c.count == 1 ? "" : "s") \(formatChannels(c)) \(c.count == 1 ? "is" : "are") used by more than one set."
		}
	}
}

/// Valores iniciales del paso 4 para `count` grupos (con 2, el ejemplo de Roland del original: «Drums» en el 10).
public func defaultChannelSets(count: Int) -> [ChannelSetSpec] {
	switch count {
	case ...1: return [ChannelSetSpec(name: "Presets", channels: "1-16")]
	case 2: return [ChannelSetSpec(name: "Presets", channels: "1-9, 11-16"), ChannelSetSpec(name: "Drums", channels: "10")]
	default:
		return [ChannelSetSpec(name: "Presets", channels: "1-9, 11-16"), ChannelSetSpec(name: "Drums", channels: "10")]
			+ (3...min(count, 16)).map { ChannelSetSpec(name: "Set \($0)", channels: "") }
	}
}

public extension MidnamFile {
	/// Fichero nuevo del asistente. `sets` vacío = todos los bancos en todos los canales («Presets», 1-16).
	static func newDevice(manufacturer: String, model: String, sets: [ChannelSetSpec]) throws -> MidnamFile {
		let maker = manufacturer.trimmingCharacters(in: .whitespaces)
		let name = model.trimmingCharacters(in: .whitespaces)
		guard !maker.isEmpty else { throw NewDeviceError.emptyManufacturer }
		guard !name.isEmpty else { throw NewDeviceError.emptyModel }
		let specs = sets.isEmpty ? defaultChannelSets(count: 1) : sets
		var parsed: [(String, [Int])] = []
		var used: [Int: Int] = [:]
		for s in specs {
			let n = s.name.trimmingCharacters(in: .whitespaces)
			guard !n.isEmpty else { throw NewDeviceError.emptySetName }
			if parsed.contains(where: { $0.0 == n }) { throw NewDeviceError.duplicateSetName(n) }
			let ch = try parseChannels(s.channels)
			guard !ch.isEmpty else { throw NewDeviceError.noChannels(n) }
			for c in ch { used[c, default: 0] += 1 }
			parsed.append((n, ch))
		}
		let twice = used.filter { $0.value > 1 }.keys.sorted()
		if !twice.isEmpty { throw NewDeviceError.overlapping(twice) }

		var file = try MidnamFile(text: skeleton)
		// En `items` va primero `Author`: el MasterDeviceNames es el segundo.
		let master = 1
		try file.document.modifyMaster(master) { m in
			for i in m.items.indices {
				if case .manufacturer = m.items[i] { m.items[i] = .manufacturer(maker) }
				if case .model = m.items[i] { m.items[i] = .model(name) }
			}
		}
		// El esqueleto tiene un modo y un Channel Set «Presets» con los 16 canales; se ajusta al primer grupo y se
		// añaden los demás con la lógica de la pestaña Device.
		let mode = file.document.modes(master: master)[0].index
		let first = file.document.channelSets(master: master)[0].index
		try file.document.renameChannelSet(master: master, set: first, to: parsed[0].0)
		try file.document.setActiveChannels(master: master, mode: mode, set: first, text: formatChannels(parsed[0].1))
		for (n, ch) in parsed.dropFirst() {
			try file.document.addChannelSet(master: master, mode: mode, name: n, channels: formatChannels(ch))
		}
		return file
	}

	/// Un modo con un Channel Set de los 16 canales y un banco vacío (P13), en el estilo de CherryPicker.
	private static var skeleton: String {
		let assigns = (1...16).map { "\t\t\t\t<ChannelNameSetAssign Channel=\"\($0)\" NameSet=\"Presets\" />" }.joined(separator: "\n")
		let channels = (1...16).map { "\t\t\t\t<AvailableChannel Channel=\"\($0)\" Available=\"true\" />" }.joined(separator: "\n")
		return """
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE MIDINameDocument PUBLIC "-//MIDI Manufacturers Association//DTD MIDINameDocument 1.0//EN" "http://www.midi.org/dtds/MIDINameDocument10.dtd">

		<MIDINameDocument>
			<Author>CherryPicker</Author>
			<MasterDeviceNames>
				<Manufacturer>M</Manufacturer>
				<Model>M</Model>
				<CustomDeviceMode Name="Mode 1" >
					<ChannelNameSetAssignments>
		\(assigns)
					</ChannelNameSetAssignments>
				</CustomDeviceMode>
				<ChannelNameSet Name="Presets" >
					<AvailableForChannels>
		\(channels)
					</AvailableForChannels>
					<PatchBank Name="New Bank" >
						<UsesPatchNameList Name="New Bank" />
					</PatchBank>
				</ChannelNameSet>
				<PatchNameList Name="New Bank" >
				</PatchNameList>
			</MasterDeviceNames>
		</MIDINameDocument>

		"""
	}
}

/// Fabricantes y modelos de un `.middev` (`MIDIDeviceType Manufacturer= Model=`), para autocompletar el paso 1.
public func middevEntries(_ text: String) -> [(manufacturer: String, model: String)] {
	guard let f = try? XMLReader.parse(text) else { return [] }
	var out: [(String, String)] = []
	func walk(_ e: MidnamKit.XMLElement) {
		if e.name == "MIDIDeviceType" {
			let m = e.attributes.first { $0.name == "Manufacturer" }?.value
			let n = e.attributes.first { $0.name == "Model" }?.value
			if let m, let n { out.append((m, n)) }
		}
		e.elements.forEach(walk)
	}
	walk(f.root)
	return out
}

/// Paso 1: un nombre que coincide con uno conocido salvo mayúsculas («CherryPicker found a close match (cases were
/// different)»). nil si coincide exactamente o no hay ninguno parecido.
public func closeMatch(_ name: String, in known: [String]) -> String? {
	let t = name.trimmingCharacters(in: .whitespaces)
	if known.contains(t) { return nil }
	return known.first { $0.caseInsensitiveCompare(t) == .orderedSame }
}

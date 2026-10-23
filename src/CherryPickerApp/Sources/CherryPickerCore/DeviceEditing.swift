// Pestaña Device (nib MainWindow; docs/20 §3.1 y §3.3; manual del original, «Modes» y «Channel Sets»; T-020).
// Un modo (`CustomDeviceMode`) reparte sus 16 canales entre Channel Sets con `ChannelNameSetAssign`; cada
// `ChannelNameSet` repite sus canales en `AvailableForChannels` (los 16, true/false). Los canales sin asignar de un
// modo están libres: el + de Channel Sets solo se puede usar si queda alguno (manual).
// Reglas propias: nombres de modo y de Channel Set únicos (el original los repetía, EXP-012) y un Channel Set nuevo
// lleva un banco vacío (la DTD exige `PatchBank+`; el original los dejaba vacíos y el fichero no validaba; P13).
import Foundation
import MidnamKit

public struct ChannelSetRow: Equatable, Sendable {
	/// Índice en `MasterDeviceNames.items`.
	public var index: Int
	public var name: String
	/// Canales asignados al Channel Set en el modo, ordenados.
	public var channels: [Int]
	/// «Active Channels» en el formato del manual: «1-7, 9, 11-16».
	public var channelsText: String { formatChannels(channels) }
	/// «Audition Ch»: el original usa el canal más bajo del Channel Set (manual); aún no se guarda (T-020).
	public var auditionChannel: Int? { channels.first }
}

public enum DeviceEditError: LocalizedError, Equatable {
	case notFound
	case emptyName
	case duplicateModeName(String)
	case duplicateChannelSetName(String)
	case invalidChannels(String)
	case noChannels
	case channelsInUse([Int])
	case noFreeChannels
	case lastMode
	case lastChannelSetInMode(String)
	case reassignTargetNeeded

	public var errorDescription: String? {
		switch self {
		case .notFound: return "The mode or channel set no longer exists."
		case .emptyName: return "A name must be entered."
		case .duplicateModeName(let n): return "There is already a mode named “\(n)”."
		case .duplicateChannelSetName(let n): return "There is already a channel set named “\(n)”."
		case .invalidChannels(let t): return "“\(t)” is not a valid list of channels. Use numbers from 1 to 16, e.g. 1-7, 9, 11-16."
		case .noChannels: return "A channel set must use at least one channel."
		case .channelsInUse(let c): return "Channel\(c.count == 1 ? "" : "s") \(formatChannels(c)) \(c.count == 1 ? "is" : "are") used by another channel set in this mode. Remove \(c.count == 1 ? "it" : "them") there first."
		case .noFreeChannels: return "No free channels in mode."
		case .lastMode: return "The device must keep at least one mode."
		case .lastChannelSetInMode(let n): return "The channel set “\(n)” is the only one in this mode."
		case .reassignTargetNeeded: return "Choose a channel set for the banks of the deleted one."
		}
	}
}

/// «1-7, 9, 11-16» → [1…7, 9, 11…16]. Admite espacios y rangos al revés; error si algo no es un canal 1–16.
public func parseChannels(_ text: String) throws -> [Int] {
	var out = Set<Int>()
	for part in text.split(separator: ",") {
		let p = part.trimmingCharacters(in: .whitespaces)
		if p.isEmpty { continue }
		let ends = p.split(separator: "-", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
		guard (1...2).contains(ends.count), let a = Int(ends[0]), let b = Int(ends.last!), (1...16).contains(a),
		      (1...16).contains(b) else { throw DeviceEditError.invalidChannels(text) }
		out.formUnion(min(a, b)...max(a, b))
	}
	return out.sorted()
}

/// [1…7, 9, 11…16] → «1-7, 9, 11-16».
public func formatChannels(_ channels: [Int]) -> String {
	var parts: [String] = []
	var run: [Int] = []
	func flush() {
		guard let f = run.first, let l = run.last else { return }
		parts.append(f == l ? "\(f)" : "\(f)-\(l)")
		run = []
	}
	for c in Set(channels).sorted() {
		if let l = run.last, c != l + 1 { flush() }
		run.append(c)
	}
	flush()
	return parts.joined(separator: ", ")
}

public extension MIDINameDocument {
	/// «Manufacturer:» y «Model:» (solo lectura; varios modelos se muestran juntos).
	func deviceNames(master: Int) -> (manufacturer: String, model: String) {
		guard let m = masterAt(master) else { return ("", "") }
		return (m.manufacturer ?? "", m.models.joined(separator: ", "))
	}

	/// Modos: índice en `MasterDeviceNames.items` y nombre.
	func modes(master: Int) -> [(index: Int, name: String)] {
		guard let m = masterAt(master) else { return [] }
		return m.items.indices.compactMap { i in
			if case .customDeviceMode(let d) = m.items[i] { return (i, d.name) }
			return nil
		}
	}

	/// Channel Sets del modo, en el orden del fichero, con sus canales en ese modo.
	func channelSets(master: Int, mode: Int) -> [ChannelSetRow] {
		guard let m = masterAt(master), let d = m.modeAt(mode) else { return [] }
		let assigned = d.assignedChannels
		return channelSets(master: master).compactMap { s in
			let ch = assigned.filter { $0.value == s.name }.keys.sorted()
			return ch.isEmpty ? nil : ChannelSetRow(index: s.index, name: s.name, channels: ch)
		}
	}

	/// Canales del modo que no usa ningún Channel Set.
	func freeChannels(master: Int, mode: Int) -> [Int] {
		guard let d = masterAt(master)?.modeAt(mode) else { return [] }
		let used = Set(d.assignedChannels.keys)
		return (1...16).filter { !used.contains($0) }
	}

	mutating func renameMode(master: Int, mode: Int, to newName: String) throws {
		let name = newName.trimmingCharacters(in: .whitespaces)
		guard !name.isEmpty else { throw DeviceEditError.emptyName }
		try modifyMaster(master) { m in
			guard var d = m.modeAt(mode) else { throw DeviceEditError.notFound }
			if d.name == name { return }
			if m.customDeviceModes.contains(where: { $0.name == name }) { throw DeviceEditError.duplicateModeName(name) }
			d.name = name
			m.items[mode] = .customDeviceMode(d)
		}
	}

	/// Cambia el nombre del Channel Set y el de sus asignaciones en todos los modos.
	mutating func renameChannelSet(master: Int, set: Int, to newName: String) throws {
		let name = newName.trimmingCharacters(in: .whitespaces)
		guard !name.isEmpty else { throw DeviceEditError.emptyName }
		try modifyMaster(master) { m in
			guard var s = m.setAt(set) else { throw DeviceEditError.notFound }
			if s.name == name { return }
			if m.channelNameSets.contains(where: { $0.name == name }) { throw DeviceEditError.duplicateChannelSetName(name) }
			let old = s.name
			s.name = name
			m.items[set] = .channelNameSet(s)
			for i in m.items.indices {
				guard case .customDeviceMode(var d) = m.items[i] else { continue }
				d.modifyAssigns { list in
					for k in list.indices where list[k].nameSet == old { list[k].nameSet = name }
				}
				m.items[i] = .customDeviceMode(d)
			}
		}
	}

	/// + de Modes: «New Mode» con un Channel Set «New Channel Set» de los 16 canales y su banco vacío (manual, P13).
	/// Devuelve el índice del modo.
	@discardableResult
	mutating func addMode(master: Int) throws -> Int {
		var modeIndex = 0
		try modifyMaster(master) { m in
			let modeName = m.unique("New Mode", taken: m.customDeviceModes.map(\.name))
			let setName = m.unique("New Channel Set", taken: m.channelNameSets.map(\.name))
			let mode = CustomDeviceMode(name: modeName, items: [.channelNameSetAssignments([])])
			let at = (m.items.lastIndex { if case .customDeviceMode = $0 { return true }; return false }).map { $0 + 1 }
				?? m.items.firstIndex { if case .channelNameSet = $0 { return true }; return false } ?? m.items.endIndex
			m.items.insert(.customDeviceMode(mode), at: at)
			modeIndex = at
			try m.insertChannelSet(named: setName, channels: Array(1...16), inMode: at)
		}
		return modeIndex
	}

	/// − de Modes: borra el modo y los Channel Sets que solo usaba él, con sus bancos y las listas que se queden sin uso.
	mutating func deleteMode(master: Int, mode: Int) throws {
		try modifyMaster(master) { m in
			guard let d = m.modeAt(mode) else { throw DeviceEditError.notFound }
			if m.customDeviceModes.count < 2 { throw DeviceEditError.lastMode }
			let mine = Set(d.assignedChannels.values)
			let others = Set(m.items.indices.filter { $0 != mode }.compactMap { m.modeAt($0) }.flatMap { $0.assignedChannels.values })
			let doomed = mine.subtracting(others)
			var lists: [String] = []
			for case .channelNameSet(let s) in m.items where doomed.contains(s.name) {
				lists += s.patchBanks.compactMap(\.usedListName)
			}
			m.items.remove(at: mode)
			m.items.removeAll { if case .channelNameSet(let s) = $0 { return doomed.contains(s.name) }; return false }
			for l in lists where m.listUsers(l) == 0 {
				if let li = m.listIndex(named: l) { m.items.remove(at: li) }
			}
		}
	}

	/// + de Channel Sets: «New Channel Set» con todos los canales libres del modo y un banco vacío (P13).
	/// Devuelve su índice en `MasterDeviceNames.items`.
	@discardableResult
	mutating func addChannelSet(master: Int, mode: Int) throws -> Int {
		let free = freeChannels(master: master, mode: mode)
		guard !free.isEmpty else { throw DeviceEditError.noFreeChannels }
		var index = 0
		try modifyMaster(master) { m in
			guard m.modeAt(mode) != nil else { throw DeviceEditError.notFound }
			let name = m.unique("New Channel Set", taken: m.channelNameSets.map(\.name))
			index = try m.insertChannelSet(named: name, channels: free, inMode: mode)
		}
		return index
	}

	/// − de Channel Sets: quita el Channel Set del modo; sus canales quedan libres. Si ningún otro modo lo usa, se borra
	/// y sus bancos pasan al final de `reassignTo` (hoja «Reassign Banks To»), o se borran si es nil y están vacíos.
	mutating func deleteChannelSet(master: Int, mode: Int, set: Int, reassignTo target: Int? = nil) throws {
		try modifyMaster(master) { m in
			guard var d = m.modeAt(mode), let s = m.setAt(set) else { throw DeviceEditError.notFound }
			let inMode = Set(d.assignedChannels.values)
			guard inMode.contains(s.name) else { throw DeviceEditError.notFound }
			if inMode.count < 2 { throw DeviceEditError.lastChannelSetInMode(s.name) }
			d.modifyAssigns { $0.removeAll { $0.nameSet == s.name } }
			m.items[mode] = .customDeviceMode(d)
			let usedElsewhere = m.customDeviceModes.contains { $0.assignedChannels.values.contains(s.name) }
			if usedElsewhere { return }
			let banks = s.patchBanks
			if let target {
				guard target != set, m.setAt(target) != nil else { throw DeviceEditError.notFound }
				try m.modifySet(target) { t in for b in banks { _ = t.insertBankAtEnd(b) } }
			} else if banks.contains(where: { b in
				b.usedListName.flatMap { m.listIndex(named: $0) }.map { li -> Bool in
					if case .patchNameList(let l) = m.items[li] { return !l.patches.isEmpty }
					return false
				} ?? true
			}) {
				throw DeviceEditError.reassignTargetNeeded
			}
			m.items.remove(at: set)
			if target == nil {
				for l in banks.compactMap(\.usedListName) where m.listUsers(l) == 0 {
					if let li = m.listIndex(named: l) { m.items.remove(at: li) }
				}
			}
		}
	}

	/// «Active Channels»: canales del Channel Set en el modo. No puede quitar canales a otro Channel Set del modo.
	mutating func setActiveChannels(master: Int, mode: Int, set: Int, text: String) throws {
		let channels = try parseChannels(text)
		guard !channels.isEmpty else { throw DeviceEditError.noChannels }
		try modifyMaster(master) { m in
			guard var d = m.modeAt(mode), var s = m.setAt(set) else { throw DeviceEditError.notFound }
			let assigned = d.assignedChannels
			let taken = channels.filter { assigned[$0] != nil && assigned[$0] != s.name }
			if !taken.isEmpty { throw DeviceEditError.channelsInUse(taken) }
			d.modifyAssigns { list in
				list.removeAll { $0.nameSet == s.name }
				list += channels.map { ChannelNameSetAssign(channel: String($0), nameSet: s.name) }
				list.sort { (Int($0.channel) ?? 0) < (Int($1.channel) ?? 0) }
			}
			m.items[mode] = .customDeviceMode(d)
			s.setAvailableChannels(channels)
			m.items[set] = .channelNameSet(s)
		}
	}
}

// MARK: - Ayudantes

extension MasterDeviceNames {
	func modeAt(_ i: Int) -> CustomDeviceMode? {
		guard items.indices.contains(i), case .customDeviceMode(let d) = items[i] else { return nil }
		return d
	}

	func unique(_ base: String, taken: [String]) -> String {
		var name = base, n = 2
		while taken.contains(name) { name = "\(base) \(n)"; n += 1 }
		return name
	}

	/// Inserta un Channel Set detrás del último, con un banco vacío «New Bank» y su lista, y le asigna `channels` en el
	/// modo `mode`. Devuelve su índice.
	@discardableResult
	mutating func insertChannelSet(named name: String, channels: [Int], inMode mode: Int) throws -> Int {
		let bankName = unique("New Bank", taken: bankRefs(master: 0).map(\.bank.name))
		let listName = unique(bankName, taken: patchNameLists.compactMap(\.name))
		var set = ChannelNameSet(name: name, items: [
			.availableForChannels([]),
			.patchBank(PatchBank(name: bankName, items: [.usesPatchNameList(listName)])),
		])
		set.setAvailableChannels(channels)
		let at = (items.lastIndex { if case .channelNameSet = $0 { return true }; return false }).map { $0 + 1 }
			?? items.firstIndex { if case .patchNameList = $0 { return true }; return false } ?? items.endIndex
		items.insert(.channelNameSet(set), at: at)
		let listAt = (items.lastIndex { if case .patchNameList = $0 { return true }; return false }).map { $0 + 1 } ?? items.endIndex
		items.insert(.patchNameList(PatchNameList(name: listName, items: [])), at: listAt)
		// El modo va delante de los Channel Sets: su índice no cambia.
		guard var d = modeAt(mode) else { throw DeviceEditError.notFound }
		d.modifyAssigns { list in
			list += channels.map { ChannelNameSetAssign(channel: String($0), nameSet: name) }
			list.sort { (Int($0.channel) ?? 0) < (Int($1.channel) ?? 0) }
		}
		items[mode] = .customDeviceMode(d)
		return at
	}
}

extension CustomDeviceMode {
	/// Canal → Channel Set asignado.
	var assignedChannels: [Int: String] {
		var out: [Int: String] = [:]
		for case .channelNameSetAssignments(let list) in items {
			for a in list { if let c = Int(a.channel) { out[c] = a.nameSet } }
		}
		return out
	}

	mutating func modifyAssigns(_ body: (inout [ChannelNameSetAssign]) -> Void) {
		if let i = items.firstIndex(where: { if case .channelNameSetAssignments = $0 { return true }; return false }),
		   case .channelNameSetAssignments(var list) = items[i] {
			body(&list)
			items[i] = .channelNameSetAssignments(list)
		} else {
			var list: [ChannelNameSetAssign] = []
			body(&list)
			items.insert(.channelNameSetAssignments(list), at: 0)
		}
	}
}

extension ChannelNameSet {
	/// `AvailableForChannels` con los 16 canales (true los de `channels`), como los ficheros de CherryPicker.
	mutating func setAvailableChannels(_ channels: [Int]) {
		let list = (1...16).map { AvailableChannel(channel: String($0), available: channels.contains($0)) }
		if let i = items.firstIndex(where: { if case .availableForChannels = $0 { return true }; return false }) {
			items[i] = .availableForChannels(list)
		} else {
			items.insert(.availableForChannels(list), at: 0)
		}
	}
}

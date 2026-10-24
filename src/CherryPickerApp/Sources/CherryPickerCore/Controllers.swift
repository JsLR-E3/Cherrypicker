// Pestaña Controllers (nib MainWindow, CPControllerVC; docs/20 §3.1; T-028): listas de controles con nombre
// (`ControlNameList`) del dispositivo, con sus controles `Ctl` · `Name`; + crea «Default Control Names» con los
// controladores estándar. [PROPUESTA P20] Cada Channel Set puede usar una lista (`UsesControlNameList`).
// DP 11.36 no muestra estos nombres (EXP-006, EXP-027): la pestaña es sencilla, para otros programas.
// Solo se editan las listas del dispositivo; las que van dentro de un Channel Set se conservan tal cual.
// Al añadir un control o cambiar su número, la lista se ordena por número (pedido por el usuario, 2026-10-24).
import Foundation
import MidnamKit

public enum ControlEditError: LocalizedError, Equatable {
	case notFound
	case emptyName
	case duplicateList(String)
	case invalidNumber(String)
	case duplicateNumber(Int)
	case inlineList(String)

	public var errorDescription: String? {
		switch self {
		case .notFound: return "The control name list no longer exists."
		case .emptyName: return "A name must be entered."
		case .duplicateList(let n): return "There is already a control name list named “\(n)”."
		case .invalidNumber(let v): return "“\(v)” is not a valid controller number. Use a number from 0 to 127."
		case .duplicateNumber(let n): return "Controller \(n) is already in this list."
		case .inlineList(let s): return "The channel set “\(s)” has its own control list inside it; it can't use another one."
		}
	}
}

/// Una fila de la tabla `Ctl` · `Name`.
public struct ControlRow: Equatable, Sendable {
	public var number: String
	public var name: String
	/// 7bit (o sin tipo), 14bit, RPN o NRPN.
	public var type: String
}

/// Controladores con nombre de la especificación MIDI 1.0 (textos propios; D-007).
public let standardControlNames: [(Int, String)] = [
	(1, "Modulation"), (2, "Breath"), (4, "Foot Pedal"), (5, "Portamento Time"), (6, "Data Entry"),
	(7, "Volume"), (8, "Balance"), (10, "Pan"), (11, "Expression"), (12, "Effect Control 1"),
	(13, "Effect Control 2"), (16, "General Purpose 1"), (17, "General Purpose 2"), (18, "General Purpose 3"),
	(19, "General Purpose 4"), (64, "Sustain Pedal"), (65, "Portamento On/Off"), (66, "Sostenuto"),
	(67, "Soft Pedal"), (68, "Legato"), (69, "Hold 2"), (70, "Sound Variation"), (71, "Resonance"),
	(72, "Release Time"), (73, "Attack Time"), (74, "Cutoff"), (75, "Decay Time"), (76, "Vibrato Rate"),
	(77, "Vibrato Depth"), (78, "Vibrato Delay"), (79, "Sound Controller 10"), (80, "General Purpose 5"),
	(81, "General Purpose 6"), (82, "General Purpose 7"), (83, "General Purpose 8"), (84, "Portamento Control"),
	(91, "Reverb Send"), (92, "Tremolo Depth"), (93, "Chorus Send"), (94, "Detune Depth"), (95, "Phaser Depth"),
]

public extension MIDINameDocument {
	/// Nombres de las listas de controles del dispositivo, en orden.
	func controlListNames(master: Int) -> [String] {
		masterAt(master)?.items.compactMap { if case .controlNameList(let l) = $0 { return l.name }; return nil } ?? []
	}

	func controlRows(list: String, master: Int) -> [ControlRow] {
		guard let l = masterAt(master)?.controlList(named: list) else { return [] }
		return l.items.compactMap {
			guard case .control(let c) = $0 else { return nil }
			return ControlRow(number: c.number, name: c.name, type: c.type ?? "7bit")
		}
	}

	/// + en Control Name Lists: «Default Control Names» (o «… 2») con los controladores estándar. Devuelve su nombre.
	@discardableResult
	mutating func addControlList(master: Int) throws -> String {
		guard let m = masterAt(master) else { throw ControlEditError.notFound }
		var name = "Default Control Names", n = 2
		while m.controlList(named: name) != nil { name = "Default Control Names \(n)"; n += 1 }
		let list = ControlNameList(name: name, items: standardControlNames.map {
			.control(Control(number: String($0.0), name: $0.1))
		})
		try modifyMaster(master) { m in
			// Junto a las otras listas del dispositivo (detrás de la última), como en los ficheros de ejemplo.
			let last = m.items.lastIndex {
				switch $0 {
				case .patchNameList, .controlNameList: return true
				default: return false
				}
			}
			m.items.insert(.controlNameList(list), at: last.map { $0 + 1 } ?? m.items.endIndex)
		}
		return name
	}

	/// − en Control Name Lists: borra la lista y quita su uso de los Channel Sets y de los patches.
	mutating func deleteControlList(_ name: String, master: Int) throws {
		try modifyMaster(master) { m in
			guard m.controlList(named: name) != nil else { throw ControlEditError.notFound }
			m.items.removeAll { if case .controlNameList(let l) = $0 { return l.name == name }; return false }
			m.replaceControlListUses(of: name, with: nil)
		}
	}

	mutating func renameControlList(_ name: String, to newName: String, master: Int) throws {
		let t = newName.trimmingCharacters(in: .whitespaces)
		guard !t.isEmpty else { throw ControlEditError.emptyName }
		if t == name { return }
		try modifyMaster(master) { m in
			guard m.controlList(named: t) == nil else { throw ControlEditError.duplicateList(t) }
			try m.modifyControlList(name) { $0.name = t }
			m.replaceControlListUses(of: name, with: t)
		}
	}

	/// + en `Ctl` · `Name`: control «New Control» con el primer número libre tras el último; la lista queda
	/// ordenada por número. Devuelve su posición.
	@discardableResult
	mutating func addControl(list: String, master: Int) throws -> Int {
		let used = Set(controlRows(list: list, master: master).compactMap { Int($0.number) })
		let start = (controlRows(list: list, master: master).last.flatMap { Int($0.number) } ?? -1) + 1
		guard let free = (Array(start...127) + Array(0..<min(start, 128))).first(where: { !used.contains($0) }) else {
			throw ControlEditError.duplicateNumber(127)
		}
		var position = 0
		try modifyMaster(master) { m in
			try m.modifyControlList(list) { l in
				l.items.append(.control(Control(number: String(free), name: "New Control")))
			}
		}
		try modifyControls(list: list, master: master) { controls in
			controls.sortByNumber()
			position = controls.firstIndex { $0.number == String(free) && ($0.type ?? "7bit") == "7bit" } ?? 0
		}
		return position
	}

	mutating func deleteControls(list: String, at indexes: IndexSet, master: Int) throws {
		try modifyControls(list: list, master: master) { controls in
			for i in indexes.sorted(by: >) where controls.indices.contains(i) { controls.remove(at: i) }
		}
	}

	/// Cambia el número del control `index`; la lista queda ordenada por número. Devuelve su nueva posición.
	@discardableResult
	mutating func setControlNumber(list: String, at index: Int, to text: String, master: Int) throws -> Int {
		let t = text.trimmingCharacters(in: .whitespaces)
		guard let n = Int(t), (0...127).contains(n) else { throw ControlEditError.invalidNumber(text) }
		var position = index
		try modifyControls(list: list, master: master) { controls in
			guard controls.indices.contains(index) else { throw ControlEditError.notFound }
			if controls[index].number == String(n) { return }
			let type = controls[index].type ?? "7bit"
			guard !controls.contains(where: { Int($0.number) == n && ($0.type ?? "7bit") == type })
			else { throw ControlEditError.duplicateNumber(n) }
			controls[index].number = String(n)
			controls.sortByNumber()
			position = controls.firstIndex { $0.number == String(n) && ($0.type ?? "7bit") == type } ?? index
		}
		return position
	}

	mutating func renameControl(list: String, at index: Int, to name: String, master: Int) throws {
		let t = name.trimmingCharacters(in: .whitespaces)
		guard !t.isEmpty else { throw ControlEditError.emptyName }
		try modifyControls(list: list, master: master) { controls in
			guard controls.indices.contains(index) else { throw ControlEditError.notFound }
			controls[index].name = t
		}
	}

	/// Channel Sets que usan la lista (`UsesControlNameList`).
	func channelSetsUsing(controlList name: String, master: Int) -> Set<Int> {
		guard let m = masterAt(master) else { return [] }
		return Set(m.items.indices.filter { i in
			m.setAt(i)?.items.contains { if case .usesControlNameList(let n) = $0 { return n == name }; return false } ?? false
		})
	}

	/// [PROPUESTA P20] El Channel Set `set` usa la lista `name` (nil: ninguna). Sustituye la que usara.
	mutating func setControlList(_ name: String?, forChannelSet set: Int, master: Int) throws {
		try modifyMaster(master) { m in
			try m.modifySet(set) { s in
				if s.items.contains(where: { if case .controlNameList = $0 { return true }; return false }) {
					throw ControlEditError.inlineList(s.name)
				}
				s.items.removeAll { if case .usesControlNameList = $0 { return true }; return false }
				guard let name else { return }
				// DTD 1.0: AvailableForChannels, listas de notas, listas de controles y después los PatchBank.
				let at = s.items.firstIndex {
					switch $0 {
					case .availableForChannels, .usesNoteNameList: return false
					case .other(let e): return e.name != "NoteNameList" && e.name != "AvailableForChannels"
					default: return true
					}
				} ?? s.items.endIndex
				s.items.insert(.usesControlNameList(name), at: at)
			}
		}
	}

	private mutating func modifyControls(list: String, master: Int, _ body: (inout [Control]) throws -> Void) throws {
		try modifyMaster(master) { m in
			try m.modifyControlList(list) { l in
				var controls = l.items.compactMap { if case .control(let c) = $0 { return c }; return nil }
				let others = l.items.filter { if case .control = $0 { return false }; return true }
				try body(&controls)
				l.items = controls.map { .control($0) } + others
			}
		}
	}
}

extension Array where Element == Control {
	/// Por número (estable: con el mismo número, como estaban; los de otros tipos o sin número válido, al final).
	mutating func sortByNumber() {
		self = enumerated().sorted { a, b in
			let x = Int(a.element.number) ?? Int.max, y = Int(b.element.number) ?? Int.max
			return x != y ? x < y : a.offset < b.offset
		}.map(\.element)
	}
}

extension MasterDeviceNames {
	func controlList(named name: String) -> ControlNameList? {
		for case .controlNameList(let l) in items where l.name == name { return l }
		return nil
	}

	mutating func modifyControlList(_ name: String, _ body: (inout ControlNameList) throws -> Void) throws {
		guard let i = items.firstIndex(where: { if case .controlNameList(let l) = $0 { return l.name == name }; return false }),
		      case .controlNameList(var l) = items[i] else { throw ControlEditError.notFound }
		try body(&l)
		items[i] = .controlNameList(l)
	}

	/// Cambia (o quita, con nil) los `UsesControlNameList` que nombran la lista, en Channel Sets y patches.
	mutating func replaceControlListUses(of name: String, with newName: String?) {
		for i in items.indices {
			switch items[i] {
			case .channelNameSet(var s):
				s.items = s.items.compactMap {
					guard case .usesControlNameList(let n) = $0, n == name else { return $0 }
					return newName.map { .usesControlNameList($0) }
				}
				items[i] = .channelNameSet(s)
			case .patchNameList(var l):
				l.modifyPatches { p in
					p.items = p.items.compactMap {
						guard case .usesControlNameList(let n) = $0, n == name else { return $0 }
						return newName.map { .usesControlNameList($0) }
					}
				}
				items[i] = .patchNameList(l)
			default:
				break
			}
		}
	}
}

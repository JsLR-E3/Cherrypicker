// Edición de bancos (pestaña Patch Banks, docs/20 §3.1 y §3.3; T-016). Operaciones sobre el modelo de MidnamKit,
// sin interfaz: la app hace una copia del documento antes de cada una para deshacer.
// Restricciones de la DTD 1.0: un ChannelNameSet necesita al menos un PatchBank; MIDICommands y PatchMIDICommands
// no pueden quedar vacíos. Nombres de banco únicos dentro de cada MasterDeviceNames (como el original).
import Foundation
import MidnamKit

/// Posición de un banco: índice en `MIDINameDocument.items`, en `MasterDeviceNames.items` y en `ChannelNameSet.items`.
public struct BankRef: Hashable, Sendable {
	public var master: Int
	public var set: Int
	public var item: Int

	public init(master: Int, set: Int, item: Int) {
		self.master = master
		self.set = set
		self.item = item
	}
}

/// Opciones de la hoja Bank Selects (nib BankSelectSheet), contrastadas con CherryPicker 3 (EXP-009): «con bank
/// select» es un patch con CC0/CC32 propios en `PatchMIDICommands`; «sin», uno cuyo `PatchMIDICommands` solo lleva el
/// Program Change (así marca el original el «-» de un patch). Los de forma corta (`ProgramChange="n"`) heredan el banco.
public enum BankSelectApply: Sendable {
	/// «Apply to all patches»: el banco toma los valores y los patches pierden los suyos (forma corta, heredan).
	case allPatches
	/// «Apply ONLY to patches without Bank Selects»: el banco y los patches «sin» reciben los valores como propios.
	/// Los de forma corta no se tocan (heredan los nuevos; el original no se ha observado con ellos).
	case patchesWithoutBankSelects
	/// «Apply Only to patches with Bank Selects»: cambia el banco y también los patches que tienen los suyos.
	case patchesWithBankSelects
}

public enum BankEditError: LocalizedError, Equatable {
	case notFound
	case emptyName
	case duplicateName(String)
	case invalidBankSelect(String)
	case lastBankInChannelSet(String)
	/// Nombres que se repetirían al recalcular el árbol de D-010, con su propuesta (BankTree.swift).
	case treeNameConflicts([TreeConflict])

	// Textos en inglés, como la interfaz (D-005, P7).
	public var errorDescription: String? {
		switch self {
		case .notFound: return "The bank no longer exists."
		case .emptyName: return "A bank name must be entered."
		case .duplicateName(let n): return "There is already a bank named “\(n)”. Bank names must be unique."
		case .invalidBankSelect(let v): return "“\(v)” is not a valid bank select. Use a number from 0 to 127, or '-' if not used."
		case .lastBankInChannelSet(let s): return "The channel set “\(s)” must keep at least one bank."
		case .treeNameConflicts(let c):
			return "Bank names must be unique: " + c.map { "“\($0.prefix)\($0.base)”" }.joined(separator: ", ")
		}
	}
}

public extension BankRef {
	/// Normaliza un valor de bank select: «-» (no se usa) o 0–127.
	static func normalizeBankSelect(_ text: String) throws -> String {
		let t = text.trimmingCharacters(in: .whitespaces)
		// Borrar el valor es dejarlo sin bank select (EXP-013).
		if t == "-" || t.isEmpty { return "-" }
		guard let n = Int(t), (0...127).contains(n) else { throw BankEditError.invalidBankSelect(text) }
		return String(n)
	}
}

public extension MIDINameDocument {
	/// Channel Sets del MasterDeviceNames `master`: índice en sus `items` y nombre.
	func channelSets(master: Int) -> [(index: Int, name: String)] {
		guard let m = masterAt(master) else { return [] }
		return m.items.indices.compactMap { i in
			if case .channelNameSet(let s) = m.items[i] { return (i, s.name) }
			return nil
		}
	}

	func bank(_ ref: BankRef) -> PatchBank? {
		guard let s = masterAt(ref.master)?.setAt(ref.set), s.items.indices.contains(ref.item),
		      case .patchBank(let b) = s.items[ref.item] else { return nil }
		return b
	}

	/// ¿Se puede usar `name` como nombre de banco en ese MasterDeviceNames? (`except`: el banco que se renombra).
	func isBankNameAvailable(_ name: String, master: Int, except: BankRef? = nil) -> Bool {
		guard let m = masterAt(master) else { return false }
		return !m.bankRefs(master: master).contains { $0.ref != except && $0.bank.name == name }
	}

	/// Cambia el nombre del banco. Si su lista solo la usa él y el nombre está libre entre las listas, la lista pasa a
	/// llamarse igual (P2: DP muestra el nombre de la lista en el menú de presets, EXP-006).
	mutating func renameBank(_ ref: BankRef, to newName: String) throws {
		let name = newName.trimmingCharacters(in: .whitespaces)
		guard !name.isEmpty else { throw BankEditError.emptyName }
		guard var bank = bank(ref) else { throw BankEditError.notFound }
		if bank.name == name { return }
		guard isBankNameAvailable(name, master: ref.master, except: ref) else { throw BankEditError.duplicateName(name) }
		try modifyMaster(ref.master) { m in
			if let listName = bank.usedListName, m.listUsers(listName) == 1, m.listIndex(named: name) == nil,
			   let li = m.listIndex(named: listName), case .patchNameList(var list) = m.items[li] {
				list.name = name
				m.items[li] = .patchNameList(list)
				bank.usedListName = name
			}
			bank.name = name
			try m.replaceBank(ref, with: bank)
		}
	}

	/// Valores de la hoja Bank Selects: «-» quita ese controlador.
	mutating func setBankSelect(_ ref: BankRef, bs0: String, bs32: String, apply: BankSelectApply) throws {
		let v0 = try BankRef.normalizeBankSelect(bs0), v32 = try BankRef.normalizeBankSelect(bs32)
		guard var bank = bank(ref) else { throw BankEditError.notFound }
		bank.setBankLevelSelect(bs0: v0, bs32: v32)
		try modifyMaster(ref.master) { m in
			try m.replaceBank(ref, with: bank)
			let change: (inout Patch) -> Void
			switch apply {
			case .allPatches: change = { $0.setOwnBankSelect(bs0: "-", bs32: "-") }
			case .patchesWithoutBankSelects:
				change = { if $0.hasExplicitCommandsWithoutBankSelect { $0.setOwnBankSelect(bs0: v0, bs32: v32) } }
			case .patchesWithBankSelects:
				change = { if $0.hasOwnBankSelect { $0.setOwnBankSelect(bs0: v0, bs32: v32) } }
			}
			try m.modifyPatches(of: ref, change)
		}
	}

	/// Añade un banco vacío al final del Channel Set `set`, con su propia lista (P2: mismo nombre que el banco).
	@discardableResult
	mutating func addBank(name newName: String, bs0: String, bs32: String, master: Int, set: Int) throws -> BankRef {
		let name = newName.trimmingCharacters(in: .whitespaces)
		guard !name.isEmpty else { throw BankEditError.emptyName }
		let v0 = try BankRef.normalizeBankSelect(bs0), v32 = try BankRef.normalizeBankSelect(bs32)
		guard masterAt(master)?.setAt(set) != nil else { throw BankEditError.notFound }
		guard isBankNameAvailable(name, master: master) else { throw BankEditError.duplicateName(name) }
		var ref = BankRef(master: master, set: set, item: 0)
		try modifyMaster(master) { m in
			var listName = name, n = 2
			while m.listIndex(named: listName) != nil { listName = "\(name) \(n)"; n += 1 }
			var bank = PatchBank(name: name, items: [.usesPatchNameList(listName)])
			bank.setBankLevelSelect(bs0: v0, bs32: v32)
			let insertAt = (m.items.lastIndex { if case .patchNameList = $0 { return true }; return false }).map { $0 + 1 }
			m.items.insert(.patchNameList(PatchNameList(name: listName, items: [])), at: insertAt ?? m.items.endIndex)
			// La lista va detrás de los ChannelNameSet: el índice del juego no cambia.
			try m.modifySet(set) { s in
				ref.item = s.insertBankAtEnd(bank)
			}
		}
		return ref
	}

	/// Borra bancos (de cualquier Channel Set) y las listas que solo usaban ellos.
	mutating func deleteBanks(_ refs: [BankRef]) throws {
		for master in Set(refs.map(\.master)) {
			try modifyMaster(master) { m in
				let mine = refs.filter { $0.master == master }
				var lists: [String] = []
				for setIndex in Set(mine.map(\.set)) {
					let items = mine.filter { $0.set == setIndex }.map(\.item)
					try m.modifySet(setIndex) { s in
						if s.bankCount - items.count < 1 { throw BankEditError.lastBankInChannelSet(s.name) }
						for i in items.sorted(by: >) {
							guard s.items.indices.contains(i), case .patchBank(let b) = s.items[i] else {
								throw BankEditError.notFound
							}
							if let l = b.usedListName { lists.append(l) }
							s.items.remove(at: i)
						}
					}
				}
				for l in lists where m.listUsers(l) == 0 {
					if let li = m.listIndex(named: l) { m.items.remove(at: li) }
				}
			}
		}
	}

	/// Lleva el banco a otro Channel Set del mismo MasterDeviceNames (al final). Devuelve su nueva posición.
	@discardableResult
	mutating func moveBank(_ ref: BankRef, toChannelSet target: Int) throws -> BankRef {
		if target == ref.set { return ref }
		guard let bank = bank(ref) else { throw BankEditError.notFound }
		var newRef = BankRef(master: ref.master, set: target, item: 0)
		try modifyMaster(ref.master) { m in
			try m.modifySet(ref.set) { s in
				if s.bankCount < 2 { throw BankEditError.lastBankInChannelSet(s.name) }
				s.items.remove(at: ref.item)
			}
			try m.modifySet(target) { s in newRef.item = s.insertBankAtEnd(bank) }
		}
		return newRef
	}

	/// Lleva varios bancos (del mismo MasterDeviceNames) al final de otro Channel Set, en el orden de la tabla
	/// (cambio múltiple desde la cabecera «Channel Set», manual del original). Los que ya están en él no se mueven.
	mutating func moveBanks(_ refs: [BankRef], toChannelSet target: Int) throws {
		guard let master = refs.first?.master else { return }
		guard refs.allSatisfy({ $0.master == master }) else { throw BankEditError.notFound }
		let moving = refs.filter { $0.set != target }.sorted { ($0.set, $0.item) < ($1.set, $1.item) }
		if moving.isEmpty { return }
		try modifyMaster(master) { m in
			guard m.setAt(target) != nil else { throw BankEditError.notFound }
			var banks: [PatchBank] = []
			for r in moving {
				guard let s = m.setAt(r.set), s.items.indices.contains(r.item), case .patchBank(let b) = s.items[r.item]
				else { throw BankEditError.notFound }
				banks.append(b)
			}
			for setIndex in Set(moving.map(\.set)) {
				let items = moving.filter { $0.set == setIndex }.map(\.item)
				try m.modifySet(setIndex) { s in
					if s.bankCount - items.count < 1 { throw BankEditError.lastBankInChannelSet(s.name) }
					for i in items.sorted(by: >) { s.items.remove(at: i) }
				}
			}
			try m.modifySet(target) { s in
				for b in banks { _ = s.insertBankAtEnd(b) }
			}
		}
	}

	/// Cambia el orden de un banco dentro de su Channel Set: `position` cuenta solo bancos (0 = el primero) y es la
	/// posición antes de quitarlo, como la de una fila de destino al arrastrar.
	@discardableResult
	mutating func reorderBank(_ ref: BankRef, toPosition position: Int) throws -> BankRef {
		var newRef = ref
		try modifyMaster(ref.master) { m in
			try m.modifySet(ref.set) { s in
				guard s.items.indices.contains(ref.item), case .patchBank = s.items[ref.item] else {
					throw BankEditError.notFound
				}
				let banks = s.bankItemIndices
				let from = banks.firstIndex(of: ref.item)!
				var to = max(0, min(position, banks.count))
				if to > from { to -= 1 }
				if to == from { return }
				let item = s.items.remove(at: ref.item)
				let rest = s.bankItemIndices
				let at = to < rest.count ? rest[to] : rest.last! + 1
				s.items.insert(item, at: at)
				newRef.item = at
			}
		}
		return newRef
	}
}

// MARK: - Ayudantes

extension MIDINameDocument {
	func masterAt(_ i: Int) -> MasterDeviceNames? {
		guard items.indices.contains(i), case .masterDeviceNames(let m) = items[i] else { return nil }
		return m
	}

	mutating func modifyMaster(_ i: Int, _ body: (inout MasterDeviceNames) throws -> Void) throws {
		guard var m = masterAt(i) else { throw BankEditError.notFound }
		try body(&m)
		items[i] = .masterDeviceNames(m)
	}
}

extension MasterDeviceNames {
	func setAt(_ i: Int) -> ChannelNameSet? {
		guard items.indices.contains(i), case .channelNameSet(let s) = items[i] else { return nil }
		return s
	}

	mutating func modifySet(_ i: Int, _ body: (inout ChannelNameSet) throws -> Void) throws {
		guard var s = setAt(i) else { throw BankEditError.notFound }
		try body(&s)
		items[i] = .channelNameSet(s)
	}

	func bankRefs(master: Int) -> [(ref: BankRef, bank: PatchBank)] {
		var out: [(BankRef, PatchBank)] = []
		for (si, item) in items.enumerated() {
			guard case .channelNameSet(let s) = item else { continue }
			for (bi, b) in s.items.enumerated() {
				if case .patchBank(let bank) = b { out.append((BankRef(master: master, set: si, item: bi), bank)) }
			}
		}
		return out
	}

	/// Bancos que citan la lista `name` con `UsesPatchNameList`.
	func listUsers(_ name: String) -> Int {
		bankRefs(master: 0).filter { $0.bank.usedListName == name }.count
	}

	func listIndex(named name: String) -> Int? {
		items.firstIndex { if case .patchNameList(let l) = $0 { return l.name == name }; return false }
	}

	mutating func replaceBank(_ ref: BankRef, with bank: PatchBank) throws {
		try modifySet(ref.set) { s in
			guard s.items.indices.contains(ref.item), case .patchBank = s.items[ref.item] else {
				throw BankEditError.notFound
			}
			s.items[ref.item] = .patchBank(bank)
		}
	}

	/// Aplica `change` a cada patch de la lista del banco (en línea o citada).
	mutating func modifyPatches(of ref: BankRef, _ change: (inout Patch) -> Void) throws {
		guard let s = setAt(ref.set), s.items.indices.contains(ref.item), case .patchBank(var bank) = s.items[ref.item]
		else { throw BankEditError.notFound }
		if let n = bank.usedListName {
			guard let li = listIndex(named: n), case .patchNameList(var list) = items[li] else { return }
			list.modifyPatches(change)
			items[li] = .patchNameList(list)
		} else if let i = bank.items.firstIndex(where: { if case .patchNameList = $0 { return true }; return false }),
		          case .patchNameList(var list) = bank.items[i] {
			list.modifyPatches(change)
			bank.items[i] = .patchNameList(list)
			try replaceBank(ref, with: bank)
		}
	}
}

extension ChannelNameSet {
	var bankItemIndices: [Int] {
		items.indices.filter { if case .patchBank = items[$0] { return true }; return false }
	}

	var bankCount: Int { bankItemIndices.count }

	/// Inserta detrás del último banco y devuelve su índice.
	mutating func insertBankAtEnd(_ bank: PatchBank) -> Int {
		let at = (bankItemIndices.last ?? items.endIndex - 1) + 1
		items.insert(.patchBank(bank), at: at)
		return at
	}
}

extension PatchBank {
	var usedListName: String? {
		get {
			for case .usesPatchNameList(let n) in items { return n }
			return nil
		}
		set {
			guard let newValue, let i = items.firstIndex(where: {
				if case .usesPatchNameList = $0 { return true }; return false
			}) else { return }
			items[i] = .usesPatchNameList(newValue)
		}
	}

	/// CC0/CC32 del banco; «-» quita ese controlador; sin comandos, el elemento desaparece (la DTD no lo admite vacío).
	mutating func setBankLevelSelect(bs0: String, bs32: String) {
		let i = items.firstIndex { if case .midiCommands = $0 { return true }; return false }
		var others: [MIDICommand] = []
		if let i, case .midiCommands(let cmds) = items[i] { others = cmds.filter { !$0.isBankSelect } }
		let cmds = MIDICommand.bankSelect(bs0: bs0, bs32: bs32) + others
		switch (i, cmds.isEmpty) {
		case (let i?, true): items.remove(at: i)
		case (let i?, false): items[i] = .midiCommands(cmds)
		case (nil, false): items.insert(.midiCommands(cmds), at: 0)
		case (nil, true): break
		}
	}
}

extension PatchNameList {
	mutating func modifyPatches(_ change: (inout Patch) -> Void) {
		for i in items.indices {
			if case .patch(var p) = items[i] {
				change(&p)
				items[i] = .patch(p)
			}
		}
	}
}

extension Patch {
	var hasOwnBankSelect: Bool {
		for case .patchMIDICommands(let cmds) in items where cmds.contains(where: \.isBankSelect) { return true }
		return false
	}

	/// `PatchMIDICommands` sin CC0/CC32: el «-» de un patch en CherryPicker (EXP-009).
	var hasExplicitCommandsWithoutBankSelect: Bool {
		for case .patchMIDICommands(let cmds) in items where !cmds.contains(where: \.isBankSelect) { return true }
		return false
	}

	/// Bank select propio del patch. Sin bank select propio, si solo queda el Program Change vuelve a la forma corta
	/// (`ProgramChange="n"`); con él, el Program Change va dentro de `PatchMIDICommands` (forma de CherryPicker, EXP-001).
	mutating func setOwnBankSelect(bs0: String, bs32: String) {
		let i = items.firstIndex { if case .patchMIDICommands = $0 { return true }; return false }
		var others: [MIDICommand] = []
		if let i, case .patchMIDICommands(let cmds) = items[i] { others = cmds.filter { !$0.isBankSelect } }
		let own = MIDICommand.bankSelect(bs0: bs0, bs32: bs32)
		var cmds: [MIDICommand]
		if own.isEmpty {
			if others.count == 1, case .programChange(let n) = others[0], programChange == nil {
				programChange = n
				cmds = []
			} else {
				cmds = others
			}
		} else {
			cmds = own + others
			if let pc = programChange, !others.contains(where: { if case .programChange = $0 { return true }; return false }) {
				cmds.append(.programChange(number: pc))
				programChange = nil
			}
		}
		switch (i, cmds.isEmpty) {
		case (let i?, true): items.remove(at: i)
		case (let i?, false): items[i] = .patchMIDICommands(cmds)
		case (nil, false): items.insert(.patchMIDICommands(cmds), at: 0)
		case (nil, true): break
		}
	}
}

extension MIDICommand {
	var isBankSelect: Bool {
		if case .controlChange(let c, _) = self { return c == "0" || c == "32" }
		return false
	}

	static func bankSelect(bs0: String, bs32: String) -> [MIDICommand] {
		var out: [MIDICommand] = []
		if bs0 != "-" { out.append(.controlChange(control: "0", value: bs0)) }
		if bs32 != "-" { out.append(.controlChange(control: "32", value: bs32)) }
		return out
	}
}

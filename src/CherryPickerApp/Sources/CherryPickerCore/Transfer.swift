// Arrastrar bancos y patches entre documentos (manual del original: «you can drag any number of banks or patches or
// notelists from one patch file into another»; docs/20 §3.1 y §3.2; T-026, P18). Siempre se copia: el documento de
// origen no cambia. Cada patch sigue sonando con el bank select que tenía (como al arrastrar entre listas, P9).
import Foundation
import MidnamKit

public extension MIDINameDocument {
	/// Copias de los patches `sources` del documento `source` (banco y posición) delante del patch `position` de
	/// `target` (nil: al final), en ese orden.
	@discardableResult
	mutating func copyPatches(_ sources: [(bank: BankRef, index: Int)], from source: MIDINameDocument,
	                          to target: BankRef, before position: Int? = nil) throws -> Range<Int> {
		let patches = try source.patchesWithBankSelect(sources)
		guard let dstBS = bank(target)?.bankLevelSelect else { throw BankEditError.notFound }
		var inserted = 0..<0
		try modifyPatchList(target) { list in
			let positions = list.patchPositions
			let at = position ?? positions.count
			guard (0...positions.count).contains(at) else { throw PatchEditError.notFound }
			let itemIndex = at < positions.count ? positions[at] : (positions.last.map { $0 + 1 } ?? list.items.count)
			list.items.insert(contentsOf: patches.map { .patch($0.0.rebased(from: $0.1, to: dstBS)) }, at: itemIndex)
			inserted = at..<(at + patches.count)
		}
		return inserted
	}

	/// Banco nuevo en el Channel Set `set` con copias de los patches `sources` del documento `source` (este u otro),
	/// delante del banco `position` de ese Channel Set (nil: al final). Cada patch sigue sonando con su bank select
	/// (P21: «New Bank from Selection» y soltar patches en la lista de bancos).
	@discardableResult
	mutating func addBank(name: String, bs0: String, bs32: String, master: Int, set: Int,
	                      withPatches sources: [(bank: BankRef, index: Int)], from source: MIDINameDocument,
	                      before position: Int? = nil) throws -> BankRef {
		// Primero al final y con sus patches; después a su sitio (las posiciones de `sources` no cambian).
		var ref = try addBank(name: name, bs0: bs0, bs32: bs32, master: master, set: set)
		try copyPatches(sources, from: source, to: ref)
		if let position { ref = try reorderBank(ref, toPosition: position) }
		return ref
	}

	/// `base` si está libre como nombre de banco en ese dispositivo; si no, «base 2», «base 3»…
	func freeBankName(_ base: String, master: Int) -> String {
		var name = base, n = 2
		while !isBankNameAvailable(name, master: master) { name = "\(base) \(n)"; n += 1 }
		return name
	}

	/// Copias de los bancos `banks` del documento `source` en el Channel Set `set` del dispositivo `master`, delante
	/// del banco `position` de ese Channel Set (nil: al final), en ese orden. Cada copia lleva el bank select, los
	/// patches y el resto del banco de origen, con su propia lista (P2); si el nombre está ocupado, «nombre 2»…
	/// Devuelve las copias y los nombres de listas de notas o de controles que usan sus patches y no hay en el destino.
	@discardableResult
	mutating func copyBanks(_ banks: [BankRef], from source: MIDINameDocument, master: Int, set: Int,
	                        before position: Int? = nil) throws -> (added: [BankRef], missingLists: [String]) {
		guard masterAt(master)?.setAt(set) != nil else { throw BankEditError.notFound }
		var added: [BankRef] = []
		var used = Set<String>()
		for (i, ref) in banks.enumerated() {
			guard var bank = source.bank(ref) else { throw BankEditError.notFound }
			var name = bank.name, n = 2
			while !isBankNameAvailable(name, master: master) { name = "\(bank.name) \(n)"; n += 1 }
			bank.name = name
			let shared = source.patchList(ref)
			for p in shared?.patches ?? [] {
				for case .usesNoteNameList(let l) in p.items { used.insert(l) }
				for case .usesControlNameList(let l) in p.items { used.insert(l) }
			}
			var newRef = BankRef(master: master, set: set, item: 0)
			try modifyMaster(master) { m in
				// Una lista compartida en el origen pasa a ser propia de la copia, con el nombre del banco (P2).
				if let k = bank.items.firstIndex(where: { if case .usesPatchNameList = $0 { return true }; return false }) {
					var listName = name, c = 2
					while m.listIndex(named: listName) != nil { listName = "\(name) \(c)"; c += 1 }
					bank.items[k] = .usesPatchNameList(listName)
					var list = shared ?? PatchNameList(name: listName, items: [])
					list.name = listName
					let insertAt = (m.items.lastIndex { if case .patchNameList = $0 { return true }; return false }).map { $0 + 1 }
					m.items.insert(.patchNameList(list), at: insertAt ?? m.items.endIndex)
				}
				try m.modifySet(set) { s in newRef.item = s.insertBankAtEnd(bank) }
			}
			if let position { newRef = try reorderBank(newRef, toPosition: position + i) }
			added.append(newRef)
		}
		let have = Set(masterAt(master)?.items.compactMap { item -> String? in
			switch item {
			case .controlNameList(let l): return l.name
			// MidnamKit guarda las listas de notas sin interpretar.
			case .other(let e) where e.name == "NoteNameList": return e[attribute: "Name"]
			default: return nil
			}
		} ?? [])
		return (added, used.subtracting(have).sorted())
	}

	internal func patchesWithBankSelect(_ sources: [(bank: BankRef, index: Int)]) throws -> [(Patch, (String, String))] {
		try sources.map { s in
			guard let bank = bank(s.bank), let list = patchList(s.bank) else { throw BankEditError.notFound }
			let all = list.patches
			guard all.indices.contains(s.index) else { throw PatchEditError.notFound }
			return (all[s.index], bank.bankLevelSelect)
		}
	}
}

// Herramientas de la pestaña Patch Banks que trabajan con varios bancos (T-019; manual del original, «Banks Tab» y
// «Custom Banks»): Merge, Find (ventana Finder) y Zap Dups.
// Un Custom Bank es un banco sin bank select propio cuyos patches llevan cada uno el suyo (manual); los demás bancos
// con bank select son «Standard Banks».
import Foundation
import MidnamKit

/// Un patch encontrado con Find: dónde está y cómo suena (columnas de la ventana Finder, sin editar).
public struct FoundPatch: Equatable, Sendable {
	public var bank: BankRef
	/// Posición entre los patches de la lista del banco.
	public var index: Int
	public var bankName: String
	/// Bank select efectivo («-» si no se envía).
	public var bankSelect0: String
	public var bankSelect32: String
	public var program: String
	public var name: String
	public var ascii: String

	/// Lo que identifica al sonido en el módulo: bank select efectivo y Program Change.
	var key: SoundKey { SoundKey(bankSelect0, bankSelect32, program) }

	/// «Remove Duplicates» del Finder: quita los que suenan igual que uno anterior de la lista (deducido: el manual no
	/// lo describe; mismo criterio que Zap Dups).
	public static func removingDuplicates(_ found: [FoundPatch]) -> [FoundPatch] {
		var seen = Set<SoundKey>()
		return found.filter { seen.insert($0.key).inserted }
	}
}

/// Bank select efectivo + Program Change, con los números normalizados («01» = «1»).
struct SoundKey: Hashable {
	var values: [String]

	init(_ bs0: String, _ bs32: String, _ program: String) {
		values = [bs0, bs32, program].map { Int($0).map(String.init) ?? $0 }
	}
}

public extension MIDINameDocument {
	/// Find: patches de todos los bancos cuyo nombre contiene `text` (sin distinguir mayúsculas ni acentos), en el
	/// orden de la tabla de bancos. Sin texto, nada.
	func findPatches(containing text: String) -> [FoundPatch] {
		let t = text.trimmingCharacters(in: .whitespaces)
		guard !t.isEmpty else { return [] }
		return BankRows.rows(self).flatMap { row in
			patchRows(row.ref).filter { $0.name.range(of: t, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
				.map {
					FoundPatch(bank: row.ref, index: $0.index, bankName: row.name, bankSelect0: $0.bankSelect0,
					           bankSelect32: $0.bankSelect32, program: $0.program, name: $0.name, ascii: $0.ascii)
				}
		}
	}

	/// Copias de los patches `sources` (banco y posición, de cualquier banco) delante del patch `position` de `target`
	/// (nil: al final), en ese orden; cada una sigue sonando con su bank select (arrastrar desde el Finder).
	@discardableResult
	mutating func copyPatches(_ sources: [(bank: BankRef, index: Int)], to target: BankRef,
	                          before position: Int? = nil) throws -> Range<Int> {
		let patches = try sources.map { s -> (Patch, (String, String)) in
			guard let bank = bank(s.bank), let list = patchList(s.bank) else { throw BankEditError.notFound }
			let all = list.patches
			guard all.indices.contains(s.index) else { throw PatchEditError.notFound }
			return (all[s.index], bank.bankLevelSelect)
		}
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

	/// «Add New Bank With Patches» (Finder): banco nuevo al final del Channel Set `set` con copias de `sources`.
	@discardableResult
	mutating func addBank(name: String, bs0: String, bs32: String, master: Int, set: Int,
	                      withPatches sources: [(bank: BankRef, index: Int)]) throws -> BankRef {
		// Las posiciones de los originales no cambian al añadir el banco: va detrás de los demás de su Channel Set.
		let ref = try addBank(name: name, bs0: bs0, bs32: bs32, master: master, set: set)
		try copyPatches(sources, to: ref)
		return ref
	}

	/// Merge (hoja «Name for Merged Bank»): banco nuevo con todos los patches de `refs` (al menos dos, del mismo
	/// MasterDeviceNames), banco tras banco en el orden de la tabla. Borra los originales salvo `keepOriginals`
	/// (Option-Add en el original). Devuelve la posición del banco nuevo.
	@discardableResult
	mutating func mergeBanks(_ refs: [BankRef], name: String, bs0: String, bs32: String, set: Int,
	                         keepOriginals: Bool = false) throws -> BankRef {
		guard let master = refs.first?.master, refs.count > 1, refs.allSatisfy({ $0.master == master }) else {
			throw BankEditError.notFound
		}
		let ordered = refs.sorted { ($0.set, $0.item) < ($1.set, $1.item) }
		let sources = ordered.flatMap { r in (patchList(r)?.patches.indices ?? 0..<0).map { (bank: r, index: $0) } }
		var ref = try addBank(name: name, bs0: bs0, bs32: bs32, master: master, set: set, withPatches: sources)
		if !keepOriginals {
			// El banco nuevo va detrás de los demás de su Channel Set: las posiciones de los originales no cambian.
			try deleteBanks(ordered)
			guard let m = masterAt(master), let found = m.bankRefs(master: master).first(where: { $0.bank.name == name.trimmingCharacters(in: .whitespaces) })
			else { throw BankEditError.notFound }
			ref = found.ref
		}
		return ref
	}

	/// Zap Dups (deducido; el manual dice «borra los patches de los Standard Banks que también están en Custom Banks»):
	/// en cada Channel Set, patches que suenan igual (bank select efectivo + Program Change) que uno de los bancos que
	/// se conservan. Sin `keeping`, se conservan los bancos sin bank select y se borra solo de los que lo tienen; con
	/// `keeping` ([PROPUESTA P12], los bancos seleccionados), se conservan esos y se borra de todos los demás de su
	/// Channel Set. Una lista compartida con un banco que se conserva no se toca.
	func duplicatePatches(keeping: [BankRef]? = nil) -> [(bank: BankRef, index: Int)] {
		var out: [(bank: BankRef, index: Int)] = []
		for (mi, item) in items.enumerated() {
			guard case .masterDeviceNames(let m) = item else { continue }
			let banks = m.bankRefs(master: mi)
			for setIndex in Set(banks.map(\.ref.set)).sorted() {
				let inSet = banks.filter { $0.ref.set == setIndex }
				let isKept: ((ref: BankRef, bank: PatchBank)) -> Bool = { b in
					keeping.map { $0.contains(b.ref) } ?? (b.bank.bankLevelSelect == ("-", "-"))
				}
				let kept = inSet.filter(isKept)
				let keptLists = Set(kept.compactMap(\.bank.usedListName))
				let keys = Set(kept.flatMap { b in patchRows(b.ref).map { SoundKey($0.bankSelect0, $0.bankSelect32, $0.program) } })
				var doneLists = Set<String>()
				for b in inSet where !isKept(b) {
					if let l = b.bank.usedListName {
						// Cada lista una vez: otro banco que la use vería borrados los mismos patches.
						if keptLists.contains(l) || !doneLists.insert(l).inserted { continue }
					}
					for r in patchRows(b.ref) where r.program != "-" && keys.contains(SoundKey(r.bankSelect0, r.bankSelect32, r.program)) {
						out.append((b.ref, r.index))
					}
				}
			}
		}
		return out
	}

	/// Borra los patches de `duplicatePatches(keeping:)`. Devuelve cuántos.
	@discardableResult
	mutating func zapDuplicates(keeping: [BankRef]? = nil) throws -> Int {
		let dups = duplicatePatches(keeping: keeping)
		for ref in Set(dups.map(\.bank)) {
			try deletePatches(ref, at: IndexSet(dups.filter { $0.bank == ref }.map(\.index)))
		}
		return dups.count
	}
}

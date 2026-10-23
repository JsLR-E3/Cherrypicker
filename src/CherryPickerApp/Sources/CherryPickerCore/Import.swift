// Import (ventana «Patchlist Importer», nib ImportBrowser; manual del original, «Importing»; docs/20 §3.4; T-022).
// De otro `.midnam` se ofrecen sus listas de patches («Available Patch Lists»), una por banco; cada una se lleva a un
// banco de destino: si hay uno con el mismo nombre se propone ese (manual), y el banco queda lleno con los patches
// importados (sustituyen a los que tenía). [PROPUESTA P14] También se puede crear un banco nuevo con la lista.
// Cada patch sigue sonando con el bank select que tenía en su fichero.
import Foundation
import MidnamKit

/// Una lista que se puede importar: la de un banco del fichero de origen.
public struct ImportableList: Equatable, Sendable {
	/// Banco del fichero de origen.
	public var bank: BankRef
	public var name: String
	public var count: Int
	public var bankSelect0: String
	public var bankSelect32: String
}

public extension MIDINameDocument {
	/// Fabricante y modelo del primer dispositivo («Type» en la lista de ficheros).
	var deviceDescription: String {
		guard let m = masterDeviceNames.first else { return "" }
		return [m.manufacturer, m.models.first].compactMap { $0 }.joined(separator: " ")
	}

	/// «Available Patch Lists»: una por banco con lista en el fichero (los bancos que comparten lista, una vez).
	func importableLists() -> [ImportableList] {
		var seen = Set<String>()
		return BankRows.rows(self).compactMap { r in
			guard let list = patchList(r.ref), let bank = bank(r.ref) else { return nil }
			if let n = bank.usedListName, !seen.insert("\(r.ref.master)|\(n)").inserted { return nil }
			return ImportableList(bank: r.ref, name: r.name, count: list.patches.count,
			                      bankSelect0: r.bankSelect0, bankSelect32: r.bankSelect32)
		}
	}

	/// Banco de destino propuesto: el del mismo nombre en el dispositivo `master` (manual del original).
	func proposedImportDestination(_ list: ImportableList, master: Int) -> BankRef? {
		BankRows.rows(self).first { $0.ref.master == master && $0.name == list.name }?.ref
	}

	/// Llena el banco `target` con los patches de `list` (del documento `source`); sus patches anteriores se van.
	mutating func importList(_ list: ImportableList, from source: MIDINameDocument, into target: BankRef) throws {
		let patches = try source.importedPatches(list)
		guard let dstBS = bank(target)?.bankLevelSelect else { throw BankEditError.notFound }
		try modifyPatchList(target) { l in
			l.items.removeAll { if case .patch = $0 { return true }; return false }
			l.items += patches.map { .patch($0.patch.rebased(from: $0.bankSelect, to: dstBS)) }
		}
	}

	/// [PROPUESTA P14] Banco nuevo con la lista, al final del Channel Set `set`, con el nombre de la lista (o «nombre 2»
	/// si está ocupado) y el bank select de su banco de origen.
	@discardableResult
	mutating func importListAsNewBank(_ list: ImportableList, from source: MIDINameDocument, master: Int,
	                                  set: Int) throws -> BankRef {
		var name = list.name, n = 2
		while !isBankNameAvailable(name, master: master) { name = "\(list.name) \(n)"; n += 1 }
		let ref = try addBank(name: name, bs0: list.bankSelect0, bs32: list.bankSelect32, master: master, set: set)
		try importList(list, from: source, into: ref)
		return ref
	}

	internal func importedPatches(_ list: ImportableList) throws -> [(patch: Patch, bankSelect: (String, String))] {
		guard let bank = bank(list.bank), let l = patchList(list.bank) else { throw BankEditError.notFound }
		return l.patches.map { ($0, bank.bankLevelSelect) }
	}
}

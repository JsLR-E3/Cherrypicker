// Pestaña Categories (nib MainWindow, CPCategoryController; docs/20 §3.1; T-025). Juegos de nombres de banco
// («Categories») con sus nombres («Bank Names»); «Add To Banks» crea con ellos Custom Banks vacíos (sin bank select)
// en el documento. Deducido del nib y del binario (nivel D): acciones addCat:/deleteCat:, addBank:/deleteBank:,
// duplicate: y addToSynth:; recurso Categories.plist con «GM Categories» y «EMU Categories».
// Los juegos estándar no se editan (se duplican con «Dup» para hacer uno propio); los propios se guardan en la app
// (no en el .midnam). Las listas se escriben aquí, sin usar el recurso del original; los nombres E-mu coinciden con
// los suyos porque son nombres de categoría (datos): el usuario decide dejarlos así (2026-10-24, P17 y D-007).
import Foundation
import MidnamKit

/// Un juego de nombres de banco.
public struct CategorySet: Codable, Equatable, Sendable {
	public var name: String
	public var bankNames: [String]
	/// Juego de serie (GM, E-mu): no se edita ni se borra.
	public var isStandard: Bool

	public init(name: String, bankNames: [String], isStandard: Bool = false) {
		self.name = name
		self.bankNames = bankNames
		self.isStandard = isStandard
	}

	/// Familias de instrumentos de General MIDI 1 (programas 1–8, 9–16…, 121–128).
	public static let gm = CategorySet(name: "GM Categories", bankNames: [
		"Piano", "Chromatic Percussion", "Organ", "Guitar", "Bass", "Strings", "Ensemble", "Brass",
		"Reed", "Pipe", "Synth Lead", "Synth Pad", "Synth Effects", "Ethnic", "Percussive", "Sound Effects",
	], isStandard: true)

	/// Categorías de sonido de los módulos E-mu (Proteus y similares).
	public static let emu = CategorySet(name: "EMU Categories", bankNames: [
		"Tempo Based LFO/Envs", "Brass Instruments", "Acoustic Bass", "Electric Bass", "Sub Bass", "Dance Bass",
		"Bass Miscellaneous", "Guitar", "Orchestral Hits/Short Blasts", "Pianos", "Electric Piano", "Organs",
		"Hybrid/Mixed Keys", "Drum Kits", "Leads", "Noises", "Orchestral Sounds", "Pads", "Percussive", "Scratches",
		"Sound Effects", "Strings", "Synthesizers", "Vocals", "Simple Waveforms", "Winds",
	], isStandard: true)
}

public enum CategoryEditError: LocalizedError, Equatable {
	case standard(String)
	case emptyName
	case duplicateCategory(String)
	case duplicateBankName(String)

	public var errorDescription: String? {
		switch self {
		case .standard(let n): return "“\(n)” is a standard category and can't be changed. Use Dup to make your own copy."
		case .emptyName: return "A name must be entered."
		case .duplicateCategory(let n): return "There is already a category named “\(n)”."
		case .duplicateBankName(let n): return "“\(n)” is already in this category."
		}
	}
}

/// Todos los juegos: primero los estándar, después los propios en el orden en que se crearon.
public struct CategoryLibrary: Equatable, Sendable {
	public private(set) var sets: [CategorySet]

	/// `user`: los juegos propios guardados (los que se llamen como uno estándar se ignoran).
	public init(user: [CategorySet] = []) {
		let standard = [CategorySet.gm, .emu]
		var names = Set(standard.map(\.name))
		sets = standard
		for var s in user where names.insert(s.name).inserted {
			s.isStandard = false
			sets.append(s)
		}
	}

	/// Los juegos propios, para guardarlos.
	public var userSets: [CategorySet] { sets.filter { !$0.isStandard } }

	/// Un nombre libre a partir de `base` («base», «base 2»…).
	public func freeName(_ base: String) -> String {
		var name = base, n = 2
		while sets.contains(where: { $0.name == name }) { name = "\(base) \(n)"; n += 1 }
		return name
	}

	/// + en Categories: juego propio vacío. Devuelve su índice.
	@discardableResult
	public mutating func addCategory(named name: String) throws -> Int {
		let n = try checkedCategoryName(name)
		sets.append(CategorySet(name: n, bankNames: []))
		return sets.count - 1
	}

	/// «Dup»: copia propia del juego, con nombre libre («… copy»). Devuelve su índice.
	@discardableResult
	public mutating func duplicateCategory(at i: Int) -> Int {
		var copy = sets[i]
		copy.name = freeName(copy.name + " copy")
		copy.isStandard = false
		sets.append(copy)
		return sets.count - 1
	}

	/// − en Categories: borra juegos propios (los estándar no).
	public mutating func removeCategories(at indexes: IndexSet) throws {
		if let s = indexes.map({ sets[$0] }).first(where: \.isStandard) { throw CategoryEditError.standard(s.name) }
		for i in indexes.sorted(by: >) { sets.remove(at: i) }
	}

	public mutating func renameCategory(at i: Int, to name: String) throws {
		guard !sets[i].isStandard else { throw CategoryEditError.standard(sets[i].name) }
		let t = name.trimmingCharacters(in: .whitespaces)
		if t == sets[i].name { return }
		sets[i].name = try checkedCategoryName(t)
	}

	/// + en Bank Names: añade un nombre al final del juego. Devuelve su posición.
	@discardableResult
	public mutating func addBankName(_ name: String, toCategory i: Int) throws -> Int {
		let n = try checkedBankName(name, in: i)
		sets[i].bankNames.append(n)
		return sets[i].bankNames.count - 1
	}

	/// Un nombre de banco libre en el juego (para + en Bank Names: «New Bank», «New Bank 2»…).
	public func freeBankName(_ base: String, inCategory i: Int) -> String {
		var name = base, n = 2
		while sets[i].bankNames.contains(name) { name = "\(base) \(n)"; n += 1 }
		return name
	}

	public mutating func removeBankNames(at indexes: IndexSet, fromCategory i: Int) throws {
		guard !sets[i].isStandard else { throw CategoryEditError.standard(sets[i].name) }
		for j in indexes.sorted(by: >) where sets[i].bankNames.indices.contains(j) { sets[i].bankNames.remove(at: j) }
	}

	public mutating func renameBankName(at j: Int, inCategory i: Int, to name: String) throws {
		let t = name.trimmingCharacters(in: .whitespaces)
		if t == sets[i].bankNames[j] { return }
		sets[i].bankNames[j] = try checkedBankName(t, in: i)
	}

	private func checkedCategoryName(_ name: String) throws -> String {
		let t = name.trimmingCharacters(in: .whitespaces)
		guard !t.isEmpty else { throw CategoryEditError.emptyName }
		guard !sets.contains(where: { $0.name == t }) else { throw CategoryEditError.duplicateCategory(t) }
		return t
	}

	private func checkedBankName(_ name: String, in i: Int) throws -> String {
		guard !sets[i].isStandard else { throw CategoryEditError.standard(sets[i].name) }
		let t = name.trimmingCharacters(in: .whitespaces)
		guard !t.isEmpty else { throw CategoryEditError.emptyName }
		guard !sets[i].bankNames.contains(t) else { throw CategoryEditError.duplicateBankName(t) }
		return t
	}
}

public extension MIDINameDocument {
	/// «Add To Banks»: un Custom Bank vacío (bank select «-») por nombre, al final del Channel Set, en el orden dado.
	/// Los nombres que ya son de un banco del dispositivo no se crean (nombres únicos) y se devuelven en `skipped`.
	@discardableResult
	mutating func addCustomBanks(named names: [String], master: Int, set: Int) throws
		-> (added: [BankRef], skipped: [String]) {
		var added: [BankRef] = [], skipped: [String] = []
		for name in names {
			let n = name.trimmingCharacters(in: .whitespaces)
			guard !n.isEmpty else { continue }
			if isBankNameAvailable(n, master: master) {
				added.append(try addBank(name: n, bs0: "-", bs32: "-", master: master, set: set))
			} else {
				skipped.append(n)
			}
		}
		return (added, skipped)
	}
}

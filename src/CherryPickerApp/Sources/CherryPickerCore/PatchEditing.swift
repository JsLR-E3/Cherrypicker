// Edición de la lista de patches de un banco (ventana Patch Names, docs/20 §3.2–3.3; T-018). Como BankEditing: solo
// el modelo; la app copia el documento antes de cada operación para deshacer.
// Columnas del original (nib PatchWindow, EXP-012): `B0`, `B32` (bank select con el que suena el patch), `#` (Program
// Change), `Patch Name` y `Ascii` (la etiqueta `Number` del fichero). Los patches se señalan por su posición entre los
// patches de la lista (los elementos desconocidos de la lista se conservan donde estén).
// Si la lista la comparten varios bancos, los cambios se ven en todos (es una sola lista en el fichero).
import Foundation
import MidnamKit

public struct PatchRow: Equatable, Sendable {
	/// Posición entre los patches de la lista.
	public var index: Int
	/// CC0 con el que suena: el propio, el del banco (forma corta) o «-».
	public var bankSelect0: String
	public var bankSelect32: String
	/// Columna `#`: Program Change, o «-» si el patch no lo lleva.
	public var program: String
	public var name: String
	/// Columna Ascii: atributo `Number`.
	public var ascii: String

	public init(index: Int, bankSelect0: String, bankSelect32: String, program: String, name: String, ascii: String) {
		self.index = index
		self.bankSelect0 = bankSelect0
		self.bankSelect32 = bankSelect32
		self.program = program
		self.name = name
		self.ascii = ascii
	}
}

/// Delimitador de la hoja New Patches («Patch Delimiter», EXP-012).
public enum PatchDelimiter: CaseIterable, Sendable {
	case endOfLine, comma, quote, tab

	public var title: String {
		switch self {
		case .endOfLine: return "End of line"
		case .comma: return "Comma"
		case .quote: return "Quote"
		case .tab: return "Tab"
		}
	}

	/// Nombres de un texto pegado o soltado, sin espacios alrededor y sin vacíos. Con `quote`, el texto que va entre
	/// comillas dobles (deducido del nombre de la opción; no contrastado con el original).
	public func names(in text: String) -> [String] {
		let parts: [Substring]
		switch self {
		case .endOfLine: parts = text.split(whereSeparator: \.isNewline)
		case .comma: parts = text.split(separator: ",")
		case .tab: parts = text.split(separator: "\t")
		case .quote:
			let pieces = text.split(separator: "\"", omittingEmptySubsequences: false)
			parts = pieces.indices.filter { $0 % 2 == 1 && $0 < pieces.count - 1 }.map { pieces[$0] }
		}
		return parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
	}
}

/// Columna por la que se ordena la lista (B0 y B32 ordenan por el par CC0, CC32).
public enum PatchSortKey: Sendable {
	case bankSelect, program, name, ascii

	/// Texto de cada campo que se compara; números como números y «-» al final.
	func value(_ p: Patch, bank: (String, String)) -> [String] {
		switch self {
		case .bankSelect: return BankRows.effectiveBankSelect(p, bank: bank)
		case .program: return [p.program ?? "-"]
		case .name: return [p.name]
		case .ascii: return [p.number]
		}
	}

	static func compare(_ a: [String], _ b: [String]) -> ComparisonResult {
		for (x, y) in zip(a, b) where x != y {
			if x == "-" { return .orderedDescending }
			if y == "-" { return .orderedAscending }
			let c = x.localizedStandardCompare(y)
			if c != .orderedSame { return c }
		}
		return .orderedSame
	}
}

public enum PatchEditError: LocalizedError, Equatable {
	case notFound
	case emptyAscii
	case invalidProgram(String)
	case programOutOfRange(Int)

	public var errorDescription: String? {
		switch self {
		case .notFound: return "The patch no longer exists."
		case .emptyAscii: return "An Ascii label must be entered."
		case .invalidProgram(let v): return "“\(v)” is not a valid program number. Use a number from 0 to 127."
		case .programOutOfRange(let n): return "Program numbers would go up to \(n). The last one must be 127 or less."
		}
	}
}

/// Siguiente etiqueta Ascii: suma 1 a los dígitos del final conservando su anchura («001» → «002», «A09» → «A10»).
/// Sin dígitos al final, la etiqueta no cambia.
public func nextAscii(_ label: String, by step: Int = 1) -> String {
	let digits = label.reversed().prefix { $0.isASCII && $0.isNumber }.count
	guard digits > 0, let n = Int(label.suffix(digits)) else { return label }
	let s = String(n + step)
	return String(label.dropLast(digits)) + String(repeating: "0", count: max(0, digits - s.count)) + s
}

public extension MIDINameDocument {
	/// Lista de patches del banco (citada con `UsesPatchNameList` o en línea).
	func patchList(_ ref: BankRef) -> PatchNameList? {
		guard let m = masterAt(ref.master), let bank = bank(ref) else { return nil }
		if let n = bank.usedListName {
			guard let li = m.listIndex(named: n), case .patchNameList(let l) = m.items[li] else { return nil }
			return l
		}
		for case .patchNameList(let l) in bank.items { return l }
		return nil
	}

	func patchRows(_ ref: BankRef) -> [PatchRow] {
		guard let bank = bank(ref), let list = patchList(ref) else { return [] }
		let bs = bank.bankLevelSelect
		return list.patches.enumerated().map { i, p in
			let eff = BankRows.effectiveBankSelect(p, bank: bs)
			return PatchRow(index: i, bankSelect0: eff[0], bankSelect32: eff[1], program: p.program ?? "-", name: p.name, ascii: p.number)
		}
	}

	mutating func renamePatch(_ ref: BankRef, at index: Int, to name: String) throws {
		try modifyPatch(ref, at: index) { $0.name = name }
	}

	mutating func setPatchAscii(_ ref: BankRef, at index: Int, to ascii: String) throws {
		let a = ascii.trimmingCharacters(in: .whitespaces)
		guard !a.isEmpty else { throw PatchEditError.emptyAscii }
		try modifyPatch(ref, at: index) { $0.number = a }
	}

	/// Columna `#`: 0–127.
	mutating func setPatchProgram(_ ref: BankRef, at index: Int, to text: String) throws {
		let t = text.trimmingCharacters(in: .whitespaces)
		guard let n = Int(t), (0...127).contains(n) else { throw PatchEditError.invalidProgram(text) }
		try modifyPatch(ref, at: index) { $0.program = String(n) }
	}

	/// Columnas B0/B32 de un patch. Igual que el banco: forma corta (hereda). Distinto: propios; «-» en los dos con un
	/// banco que sí lleva bank select: solo Program Change (el «-» del original, EXP-009).
	mutating func setPatchBankSelect(_ ref: BankRef, at index: Int, bs0: String, bs32: String) throws {
		let v0 = try BankRef.normalizeBankSelect(bs0), v32 = try BankRef.normalizeBankSelect(bs32)
		guard let bank = bank(ref) else { throw BankEditError.notFound }
		let bankBS = bank.bankLevelSelect
		try modifyPatch(ref, at: index) { p in
			if (v0, v32) == bankBS {
				p.setOwnBankSelect(bs0: "-", bs32: "-")
			} else {
				p.setOwnBankSelect(bs0: v0, bs32: v32)
				p.makeExplicit()
			}
		}
	}

	mutating func deletePatches(_ ref: BankRef, at indices: IndexSet) throws {
		try modifyPatchList(ref) { list in
			let positions = list.patchPositions
			guard indices.allSatisfy(positions.indices.contains) else { throw PatchEditError.notFound }
			for i in indices.reversed() { list.items.remove(at: positions[i]) }
		}
	}

	/// Hoja New Patches (+, o pegar o soltar texto; EXP-012): `names.count` patches (vacíos con +) desde `startAt`
	/// (Program Change) y `startAscii`, insertados delante del patch `position` (nil: al final).
	/// «Set Bank Selects to Bank values» (regla acordada, docs/20 P9): marcada, o banco sin bank select → forma corta
	/// (heredan del banco); sin marcar en un banco con bank select → «-» (solo Program Change).
	/// Devuelve las posiciones de los nuevos patches.
	@discardableResult
	mutating func addPatches(_ ref: BankRef, names: [String], startAt: Int, startAscii: String,
	                         useBankSelects: Bool, before position: Int? = nil) throws -> Range<Int> {
		guard (0...127).contains(startAt) else { throw PatchEditError.invalidProgram(String(startAt)) }
		let last = startAt + names.count - 1
		guard last <= 127 else { throw PatchEditError.programOutOfRange(last) }
		let ascii = startAscii.trimmingCharacters(in: .whitespaces)
		guard !ascii.isEmpty else { throw PatchEditError.emptyAscii }
		guard let bank = bank(ref) else { throw BankEditError.notFound }
		let bankHasSelect = bank.bankLevelSelect != ("-", "-")
		let new = names.enumerated().map { i, name -> PatchNameList.Item in
			var p = Patch(number: nextAscii(ascii, by: i), name: name, programChange: String(startAt + i))
			if !useBankSelects && bankHasSelect { p.makeExplicit() }
			return .patch(p)
		}
		var inserted = 0..<0
		try modifyPatchList(ref) { list in
			let positions = list.patchPositions
			let at = position ?? positions.count
			guard (0...positions.count).contains(at) else { throw PatchEditError.notFound }
			let itemIndex = at < positions.count ? positions[at] : (positions.last.map { $0 + 1 } ?? list.items.count)
			list.items.insert(contentsOf: new, at: itemIndex)
			inserted = at..<(at + new.count)
		}
		return inserted
	}

	/// Hoja Renumber Patches: Program Change desde `midiStart` y Ascii desde `displayStart`, en todos los patches
	/// (`indices` nil, «All») o en los seleccionados («Selection»), por orden de la lista.
	mutating func renumberPatches(_ ref: BankRef, indices: IndexSet? = nil, midiStart: Int, displayStart: String) throws {
		let ascii = displayStart.trimmingCharacters(in: .whitespaces)
		guard !ascii.isEmpty else { throw PatchEditError.emptyAscii }
		guard (0...127).contains(midiStart) else { throw PatchEditError.invalidProgram(String(midiStart)) }
		try modifyPatchList(ref) { list in
			let positions = list.patchPositions
			let chosen = indices.map(Array.init) ?? Array(positions.indices)
			guard chosen.allSatisfy(positions.indices.contains) else { throw PatchEditError.notFound }
			let last = midiStart + chosen.count - 1
			guard last <= 127 else { throw PatchEditError.programOutOfRange(last) }
			for (k, i) in chosen.enumerated() {
				guard case .patch(var p) = list.items[positions[i]] else { continue }
				p.program = String(midiStart + k)
				p.number = nextAscii(ascii, by: k)
				list.items[positions[i]] = .patch(p)
			}
		}
	}

	/// Arrastrar dentro de la lista: los patches `indices` pasan delante del patch `position` (posición antes de
	/// moverlos; `count` = al final). Devuelve sus posiciones nuevas.
	@discardableResult
	mutating func movePatches(_ ref: BankRef, at indices: IndexSet, before position: Int) throws -> Range<Int> {
		var moved = 0..<0
		try modifyPatchList(ref) { list in
			var patches = list.patches
			guard indices.allSatisfy(patches.indices.contains), (0...patches.count).contains(position) else {
				throw PatchEditError.notFound
			}
			let block = indices.map { patches[$0] }
			let at = position - indices.count(in: 0..<position)
			for i in indices.reversed() { patches.remove(at: i) }
			patches.insert(contentsOf: block, at: at)
			list.replacePatches(patches)
			moved = at..<(at + block.count)
		}
		return moved
	}

	/// Clic en una cabecera (manual del original: «Patches … can be sorted by clicking on the column headers»): cambia el
	/// orden de la lista en el fichero, que es el del menú del secuenciador. Orden estable; «-» va al final.
	mutating func sortPatches(_ ref: BankRef, by key: PatchSortKey, ascending: Bool = true) throws {
		guard let bank = bank(ref) else { throw BankEditError.notFound }
		let bs = bank.bankLevelSelect
		try modifyPatchList(ref) { list in
			let keyed = list.patches.enumerated().map { i, p in (i, p, key.value(p, bank: bs)) }
			let sorted = keyed.sorted { a, b in
				let c = PatchSortKey.compare(a.2, b.2)
				if c == .orderedSame { return a.0 < b.0 }
				return ascending ? c == .orderedAscending : c == .orderedDescending
			}
			list.replacePatches(sorted.map(\.1))
		}
	}

	/// Arrastrar a otra lista (banco `target`): se copian delante de `position` (nil: al final) y, si `move`, se borran
	/// del origen. Cada patch sigue sonando igual: se reescribe su bank select respecto al banco de destino.
	@discardableResult
	mutating func copyPatches(from source: BankRef, at indices: IndexSet, to target: BankRef, before position: Int? = nil,
	                          move: Bool = false) throws -> Range<Int> {
		guard let srcBank = bank(source), let dstBank = bank(target), let srcList = patchList(source) else {
			throw BankEditError.notFound
		}
		let patches = srcList.patches
		guard indices.allSatisfy(patches.indices.contains) else { throw PatchEditError.notFound }
		let dstBS = dstBank.bankLevelSelect
		let block = indices.map { i -> PatchNameList.Item in
			var p = patches[i]
			let eff = BankRows.effectiveBankSelect(p, bank: srcBank.bankLevelSelect)
			if (eff[0], eff[1]) == dstBS {
				p.setOwnBankSelect(bs0: "-", bs32: "-")
			} else {
				p.setOwnBankSelect(bs0: eff[0], bs32: eff[1])
				p.makeExplicit()
			}
			return .patch(p)
		}
		let sameList = source == target || (srcBank.usedListName != nil && srcBank.usedListName == dstBank.usedListName)
		if move && sameList {
			return try movePatches(target, at: indices, before: position ?? patches.count)
		} else if move {
			try deletePatches(source, at: indices)
		}
		var inserted = 0..<0
		try modifyPatchList(target) { list in
			let positions = list.patchPositions
			let at = position ?? positions.count
			guard (0...positions.count).contains(at) else { throw PatchEditError.notFound }
			let itemIndex = at < positions.count ? positions[at] : (positions.last.map { $0 + 1 } ?? list.items.count)
			list.items.insert(contentsOf: block, at: itemIndex)
			inserted = at..<(at + block.count)
		}
		return inserted
	}
}

// MARK: - Ayudantes

extension MIDINameDocument {
	mutating func modifyPatchList(_ ref: BankRef, _ body: (inout PatchNameList) throws -> Void) throws {
		try modifyMaster(ref.master) { m in try m.modifyPatchList(of: ref, body) }
	}

	mutating func modifyPatch(_ ref: BankRef, at index: Int, _ change: (inout Patch) -> Void) throws {
		try modifyPatchList(ref) { list in
			let positions = list.patchPositions
			guard positions.indices.contains(index), case .patch(var p) = list.items[positions[index]] else {
				throw PatchEditError.notFound
			}
			change(&p)
			list.items[positions[index]] = .patch(p)
		}
	}
}

extension MasterDeviceNames {
	/// Aplica `body` a la lista del banco (citada o en línea).
	mutating func modifyPatchList(of ref: BankRef, _ body: (inout PatchNameList) throws -> Void) throws {
		guard let s = setAt(ref.set), s.items.indices.contains(ref.item), case .patchBank(var bank) = s.items[ref.item]
		else { throw BankEditError.notFound }
		if let n = bank.usedListName {
			guard let li = listIndex(named: n), case .patchNameList(var list) = items[li] else {
				throw BankEditError.notFound
			}
			try body(&list)
			items[li] = .patchNameList(list)
		} else if let i = bank.items.firstIndex(where: { if case .patchNameList = $0 { return true }; return false }),
		          case .patchNameList(var list) = bank.items[i] {
			try body(&list)
			bank.items[i] = .patchNameList(list)
			try replaceBank(ref, with: bank)
		} else {
			throw BankEditError.notFound
		}
	}
}

extension PatchNameList {
	/// Índice en `items` de cada patch, en orden.
	var patchPositions: [Int] {
		items.indices.filter { if case .patch = items[$0] { return true }; return false }
	}

	/// Sustituye los patches en orden; los demás elementos se quedan en su sitio.
	mutating func replacePatches(_ patches: [Patch]) {
		var rest = patches[...]
		items = items.compactMap { item in
			guard case .patch = item else { return item }
			return rest.popFirst().map(Item.patch)
		}
		items += rest.map(Item.patch)
	}
}

extension PatchBank {
	/// CC0/CC32 del banco, «-» si no los lleva.
	var bankLevelSelect: (String, String) {
		var bs0 = "-", bs32 = "-"
		for case .midiCommands(let cmds) in items {
			for case .controlChange(let c, let v) in cmds {
				if c == "0" { bs0 = v } else if c == "32" { bs32 = v }
			}
		}
		return (bs0, bs32)
	}
}

extension Patch {
	/// Program Change: el atributo o el de `PatchMIDICommands`.
	var program: String? {
		get {
			if let programChange { return programChange }
			for case .patchMIDICommands(let cmds) in items {
				for case .programChange(let n) in cmds { return n }
			}
			return nil
		}
		set {
			if let i = items.firstIndex(where: { if case .patchMIDICommands = $0 { return true }; return false }),
			   case .patchMIDICommands(var cmds) = items[i],
			   let k = cmds.firstIndex(where: { if case .programChange = $0 { return true }; return false }) {
				if let newValue { cmds[k] = .programChange(number: newValue) } else { cmds.remove(at: k) }
				items[i] = .patchMIDICommands(cmds)
			} else {
				programChange = newValue
			}
		}
	}

	/// Pasa el Program Change de la forma corta a `PatchMIDICommands`: un patch así no hereda el bank select del banco
	/// (el «-» del original si no lleva CC0/CC32).
	mutating func makeExplicit() {
		guard let pc = programChange else { return }
		programChange = nil
		if let i = items.firstIndex(where: { if case .patchMIDICommands = $0 { return true }; return false }),
		   case .patchMIDICommands(let cmds) = items[i] {
			items[i] = .patchMIDICommands(cmds + [.programChange(number: pc)])
		} else {
			items.insert(.patchMIDICommands([.programChange(number: pc)]), at: 0)
		}
	}
}

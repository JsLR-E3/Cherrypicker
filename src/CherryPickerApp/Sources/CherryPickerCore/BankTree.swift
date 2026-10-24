// Sub-bancos en árbol de D-010 (T-033, [PROPUESTA P22]): el árbol está en los nombres de banco. «• » marca el banco
// con todos los presets; «├ » y «└ » (el último) marcan los sub-bancos del banco padre de encima, en su Channel Set.
// DP 11.36 solo muestra un nivel de submenús, en el orden del fichero, y el nombre de la lista (EXP-006, EXP-033), así
// que el árbol tiene un nivel y el nombre del banco se escribe igual en `PatchBank`, `UsesPatchNameList` y
// `PatchNameList`. Cada operación recalcula los prefijos de su Channel Set; si dos bancos quedarían con el mismo nombre,
// propone «nombre (padre)» (`BankEditError.treeNameConflicts`) y la app deja editar la propuesta.
import Foundation
import MidnamKit

/// Nombre de banco descompuesto según D-010.
public struct TreeName: Equatable, Sendable {
	public static let allMark = "• ", middle = "├ ", last = "└ ", dash = "- "

	/// Nombre sin prefijo.
	public var base: String
	/// «• »: banco con todos los presets (solo en bancos padre).
	public var isAll: Bool
	/// «├ »/«└ »: sub-banco del banco padre de encima.
	public var isChild: Bool

	public init(base: String, isAll: Bool = false, isChild: Bool = false) {
		self.base = base
		self.isAll = isAll
		self.isChild = isChild
	}

	public init(parsing name: String) {
		if name.hasPrefix(Self.middle) || name.hasPrefix(Self.last) {
			self.init(base: String(name.dropFirst(2)), isChild: true)
		} else if name.hasPrefix(Self.allMark) {
			self.init(base: String(name.dropFirst(2)), isAll: true)
		} else {
			self.init(base: name)
		}
	}

	public func prefix(last: Bool) -> String {
		isChild ? (last ? Self.last : Self.middle) : isAll ? Self.allMark : ""
	}

	/// Nombre completo; `last`: es el último sub-banco de su grupo.
	public func name(last: Bool) -> String { prefix(last: last) + base }
}

/// Banco que quedaría con el nombre de otro.
public struct TreeConflict: Equatable, Sendable {
	/// Posición del banco antes del cambio: clave de `overrides` al repetir la operación.
	public var ref: BankRef
	/// Prefijo que llevará («├ », «└ », «• » o nada).
	public var prefix: String
	/// Nombre (sin prefijo) que se repite.
	public var base: String
	/// Nombre (sin prefijo) propuesto: «base (padre)» o «base 2».
	public var proposal: String

	public init(ref: BankRef, prefix: String, base: String, proposal: String) {
		self.ref = ref
		self.prefix = prefix
		self.base = base
		self.proposal = proposal
	}
}

/// Banco de un Channel Set con su nombre descompuesto.
struct TreeEntry {
	/// Posición antes del cambio.
	var ref: BankRef
	var bank: PatchBank
	var tree: TreeName
	/// Padre que tenía, para proponer «nombre (padre)» si al sacarlo del grupo choca.
	var hint: String?
}

extension Array where Element == TreeEntry {
	/// Índice siguiente al último sub-banco del grupo que empieza en `start`.
	func groupEnd(_ start: Int) -> Int {
		var j = start + 1
		while j < count && self[j].tree.isChild { j += 1 }
		return j
	}

	/// ¿Se puede soltar un grupo delante de la posición `p` sin partir otro?
	func isBoundary(_ p: Int) -> Bool { p >= count || !self[p].tree.isChild }

	func parentBase(of i: Int) -> String? { self[..<i].last { !$0.tree.isChild }?.tree.base }
}

public extension MIDINameDocument {
	/// ¿Se puede meter el banco como sub-banco del de encima? (No es sub-banco ni el primero de su Channel Set.)
	func canIndent(_ ref: BankRef) -> Bool {
		guard let b = bank(ref), !TreeName(parsing: b.name).isChild else { return false }
		return masterAt(ref.master)?.setAt(ref.set)?.bankItemIndices.first != ref.item
	}

	func canOutdent(_ ref: BankRef) -> Bool { bank(ref).map { TreeName(parsing: $0.name).isChild } ?? false }

	/// ¿Puede soltarse el grupo de un banco padre delante del banco `position` de ese Channel Set (contado entre bancos)?
	func isTreeGroupBoundary(master: Int, set: Int, position: Int) -> Bool {
		treeEntries(master: master, set: set).isBoundary(position)
	}

	/// Los bancos con sus sub-bancos detrás (para llevar el grupo entero a otro Channel Set).
	func withTreeChildren(_ refs: [BankRef]) -> [BankRef] {
		var out: [BankRef] = []
		for r in refs where !out.contains(r) {
			out.append(r)
			let e = treeEntries(master: r.master, set: r.set)
			guard let i = e.firstIndex(where: { $0.ref == r }), !e[i].tree.isChild else { continue }
			for j in i + 1 ..< e.groupEnd(i) where !out.contains(e[j].ref) { out.append(e[j].ref) }
		}
		return out
	}

	/// Mete los bancos (que no son sub-bancos ni el primero de su Channel Set) en el grupo de encima. Los sub-bancos de
	/// un banco padre que se mete pasan al mismo grupo (un solo nivel). Pierden la marca «• ».
	mutating func indentBanks(_ refs: [BankRef], overrides: [BankRef: String] = [:]) throws {
		try editTree(refs, overrides: overrides) { e, selected in
			for i in e.indices.dropFirst() where selected.contains(e[i].ref) && !e[i].tree.isChild {
				e[i].tree.isChild = true
				e[i].tree.isAll = false
			}
		}
	}

	/// Saca los sub-bancos de su grupo: pasan a bancos normales justo detrás del grupo (si no, se quedarían como padre
	/// de los sub-bancos de debajo).
	mutating func outdentBanks(_ refs: [BankRef], overrides: [BankRef: String] = [:]) throws {
		try editTree(refs, overrides: overrides) { e, selected in
			var i = 0
			while i < e.count {
				let end = e.groupEnd(i)
				let children = Array(e[i + 1 ..< end])
				let moving = children.filter { selected.contains($0.ref) }.map { c -> TreeEntry in
					var c = c
					c.tree.isChild = false
					c.hint = e[i].tree.base
					return c
				}
				if !moving.isEmpty {
					e.replaceSubrange(i + 1 ..< end, with: children.filter { !selected.contains($0.ref) } + moving)
				}
				i = end
			}
		}
	}

	/// Pone «• » a los bancos padre seleccionados o, si ya la llevan todos, se la quita.
	mutating func toggleAllMark(_ refs: [BankRef], overrides: [BankRef: String] = [:]) throws {
		try editTree(refs, overrides: overrides) { e, selected in
			let tops = e.indices.filter { selected.contains(e[$0].ref) && !e[$0].tree.isChild }
			let mark = !tops.allSatisfy { e[$0].tree.isAll }
			for i in tops { e[i].tree.isAll = mark }
		}
	}

	/// Cambia el nombre sin tocar su prefijo: `base` se escribe sin él (si lo lleva, se quita). La lista, como en
	/// `renameBank` (P2). Un banco padre con un nombre ocupado da `duplicateName`; un sub-banco, una propuesta.
	mutating func renameBank(_ ref: BankRef, keepingTreeTo base: String, overrides: [BankRef: String] = [:]) throws {
		let typed = TreeName(parsing: String(base.drop { $0 == " " })).base.trimmingCharacters(in: .whitespaces)
		guard !typed.isEmpty else { throw BankEditError.emptyName }
		guard let old = bank(ref) else { throw BankEditError.notFound }
		var t = TreeName(parsing: old.name)
		if t.base == typed && overrides[ref] == nil { return }
		t.base = typed
		if !t.isChild, !isBankNameAvailable(t.name(last: false), master: ref.master, except: ref) {
			throw BankEditError.duplicateName(t.name(last: false))
		}
		try editTree([ref], overrides: overrides) { e, _ in
			if let i = e.firstIndex(where: { $0.ref == ref }) { e[i].tree.base = typed }
		}
	}

	/// Reordena dentro del Channel Set (`position` como en `reorderBank`). Un banco padre se lleva sus sub-bancos y solo
	/// se suelta entre grupos (si no, no se mueve); un sub-banco pasa al grupo donde se suelta (arriba del todo, a banco
	/// normal).
	mutating func moveBankGroup(_ ref: BankRef, toPosition position: Int, overrides: [BankRef: String] = [:]) throws {
		try editTree([ref], overrides: overrides) { e, _ in
			guard let from = e.firstIndex(where: { $0.ref == ref }) else { throw BankEditError.notFound }
			let child = e[from].tree.isChild
			let end = child ? from + 1 : e.groupEnd(from)
			var to = Swift.max(0, Swift.min(position, e.count))
			if (from ... end).contains(to) || (!child && !e.isBoundary(to)) { return }
			var block = Array(e[from ..< end])
			if child { block[0].hint = e.parentBase(of: from) }
			e.removeSubrange(from ..< end)
			if to > from { to -= end - from }
			e.insert(contentsOf: block, at: to)
		}
	}

	/// Bancos recién puestos en medio de un grupo (con patches soltados o copiados de otro documento): si el banco de
	/// debajo es un sub-banco, pasan a sub-bancos de ese grupo.
	mutating func adoptIntoGroup(_ refs: [BankRef]) throws {
		try editTree(refs, overrides: [:], autoResolve: true) { e, selected in
			let idx = e.indices.filter { selected.contains(e[$0].ref) }
			guard let first = idx.first, let last = idx.last, first > 0, last + 1 < e.count,
			      e[last + 1].tree.isChild else { return }
			for i in idx {
				e[i].tree.isChild = true
				e[i].tree.isAll = false
			}
		}
	}

	/// Sub-bancos al estilo «- » (como el SPX2000 del usuario): bancos «- nombre» con un banco sin «- » encima.
	func dashSubBanks() -> [BankRef] {
		var out: [BankRef] = []
		for (key, _) in allTreeSets() {
			var parent = false
			for entry in treeEntries(master: key.master, set: key.set) {
				if entry.bank.name.hasPrefix(TreeName.dash) {
					if parent { out.append(entry.ref) }
				} else {
					parent = true
				}
			}
		}
		return out
	}

	/// Pasa los sub-bancos «- » a árbol («├ »/«└ »).
	mutating func convertDashSubBanks(overrides: [BankRef: String] = [:]) throws {
		try editTree(dashSubBanks(), overrides: overrides) { e, selected in
			for i in e.indices where selected.contains(e[i].ref) {
				e[i].tree = TreeName(base: String(e[i].bank.name.dropFirst(2)), isChild: true)
			}
		}
	}

	/// Rehace «├ »/«└ » en todos los Channel Sets tras cualquier cambio (borrar, mover, copiar bancos…): el último de cada
	/// grupo lleva «└ »; un sub-banco sin padre encima pasa a banco normal. No toca los ficheros sin estos prefijos.
	/// `autoResolve`: si dos nombres chocan, se aplica la propuesta en vez de lanzar el error.
	mutating func normalizeTree(autoResolve: Bool = true) throws {
		try editTree([], sets: allTreeSets().map { $0.key }, overrides: [:], autoResolve: autoResolve) { _, _ in }
	}
}

// MARK: - Aplicación

extension MIDINameDocument {
	func allTreeSets() -> [(key: (master: Int, set: Int), name: String)] {
		items.indices.flatMap { mi -> [(key: (master: Int, set: Int), name: String)] in
			channelSets(master: mi).map { (key: (master: mi, set: $0.index), name: $0.name) }
		}
	}

	func treeEntries(master: Int, set: Int) -> [TreeEntry] {
		guard let s = masterAt(master)?.setAt(set) else { return [] }
		return s.bankItemIndices.compactMap { i in
			guard case .patchBank(let b) = s.items[i] else { return nil }
			return TreeEntry(ref: BankRef(master: master, set: set, item: i), bank: b, tree: TreeName(parsing: b.name))
		}
	}

	/// Aplica `body` a los bancos de cada Channel Set de `refs` (y de `sets`) y deja el resultado con `applyTree`. Si
	/// algún nombre choca, no cambia nada y lanza todas las propuestas juntas.
	mutating func editTree(_ refs: [BankRef], sets: [(master: Int, set: Int)] = [], overrides: [BankRef: String],
	                       autoResolve: Bool = false,
	                       _ body: (inout [TreeEntry], Set<BankRef>) throws -> Void) throws {
		var keys = sets.map { [$0.master, $0.set] }
		for r in refs where !keys.contains([r.master, r.set]) { keys.append([r.master, r.set]) }
		let selected = Set(refs)
		var result = self
		var conflicts: [TreeConflict] = []
		for key in keys {
			var e = result.treeEntries(master: key[0], set: key[1])
			try body(&e, selected)
			do {
				try result.applyTree(master: key[0], set: key[1], entries: e, overrides: overrides, autoResolve: autoResolve)
			} catch BankEditError.treeNameConflicts(let c) {
				conflicts += c
			}
		}
		if !conflicts.isEmpty { throw BankEditError.treeNameConflicts(conflicts) }
		self = result
	}

	/// Escribe los bancos del Channel Set en el orden de `entries` con los prefijos recalculados y renombra las listas
	/// que solo usa cada banco renombrado (si el nombre está libre entre las listas, como `renameBank`).
	mutating func applyTree(master: Int, set: Int, entries: [TreeEntry], overrides: [BankRef: String],
	                        autoResolve: Bool) throws {
		var e = entries
		// Los sub-bancos sin padre encima pasan a bancos normales.
		var i0 = 0
		while i0 < e.count && e[i0].tree.isChild { e[i0].tree.isChild = false; i0 += 1 }
		for i in e.indices {
			if e[i].tree.isChild { e[i].tree.isAll = false }
			if let o = overrides[e[i].ref] {
				let base = TreeName(parsing: o.trimmingCharacters(in: .whitespaces)).base
				if !base.isEmpty { e[i].tree.base = base }
			}
		}
		func names() -> [String] {
			e.indices.map { e[$0].tree.name(last: $0 + 1 == e.count || !e[$0 + 1].tree.isChild) }
		}
		var target = names()

		// Nombres repetidos, contando los de los otros Channel Sets del dispositivo. Los sub-bancos se comparan sin
		// prefijo: «├ Medium» y «└ Medium» chocarían al reordenar.
		func key(_ t: TreeName, _ name: String) -> String { t.isChild ? "\u{0}" + t.base : name }
		let outside = (masterAt(master)?.bankRefs(master: master) ?? []).filter { $0.ref.set != set }
			.map { key(TreeName(parsing: $0.bank.name), $0.bank.name) }
		let keys = e.indices.map { key(e[$0].tree, target[$0]) }
		var count: [String: Int] = [:]
		for k in outside + keys { count[k, default: 0] += 1 }
		var taken = Set(outside + keys)
		var conflicts: [TreeConflict] = []
		for i in e.indices where count[keys[i]]! > 1 {
			let dup = e.indices.filter { keys[$0] == keys[i] }
			// Si nada de lo repetido ha cambiado, el fichero ya venía así: no se toca.
			guard dup.contains(where: { target[$0] != e[$0].bank.name }) else { continue }
			// Se renombran los sub-bancos; si no hay, los que cambian.
			let children = dup.filter { e[$0].tree.isChild }
			let renamed = children.isEmpty ? dup.filter { target[$0] != e[$0].bank.name } : children
			guard renamed.contains(i) else { continue }
			let last = target[i].hasPrefix(TreeName.last)
			var proposal = e[i].tree.base
			if let parent = e[i].tree.isChild ? e.parentBase(of: i) : e[i].hint, parent != proposal {
				proposal += " (\(parent))"
			}
			var candidate = proposal, n = 2
			func keyFor(_ b: String) -> String { var t = e[i].tree; t.base = b; return key(t, t.name(last: last)) }
			while taken.contains(keyFor(candidate)) { candidate = "\(proposal) \(n)"; n += 1 }
			taken.insert(keyFor(candidate))
			conflicts.append(TreeConflict(ref: e[i].ref, prefix: e[i].tree.prefix(last: last), base: e[i].tree.base,
			                              proposal: candidate))
		}
		if !conflicts.isEmpty {
			guard autoResolve else { throw BankEditError.treeNameConflicts(conflicts) }
			for c in conflicts {
				if let i = e.firstIndex(where: { $0.ref == c.ref }) { e[i].tree.base = c.proposal }
			}
			target = names()
		}

		let slots = e.map(\.ref.item).sorted()
		let changed = e.indices.filter { target[$0] != e[$0].bank.name }
		if changed.isEmpty && e.map(\.ref.item) == slots { return }
		try modifyMaster(master) { m in
			// Listas que solo usa un banco renombrado: pasan a llamarse como él si el nombre queda libre.
			var lists: [String: String] = [:]
			for i in changed {
				if let l = e[i].bank.usedListName, m.listUsers(l) == 1 { lists[l] = target[i] }
			}
			var final = Set(m.patchNameLists.compactMap(\.name)).subtracting(lists.keys)
			for old in lists.keys.sorted() {
				if final.contains(lists[old]!) { lists[old] = nil } else { final.insert(lists[old]!) }
			}
			for i in e.indices {
				let old = e[i].bank.name
				e[i].bank.name = target[i]
				if let l = e[i].bank.usedListName, let n = lists[l] { e[i].bank.usedListName = n }
				for k in e[i].bank.items.indices {
					if case .patchNameList(var l) = e[i].bank.items[k], l.name == old {
						l.name = target[i]
						e[i].bank.items[k] = .patchNameList(l)
					}
				}
			}
			for k in m.items.indices {
				if case .patchNameList(var l) = m.items[k], let n = l.name, let new = lists[n] {
					l.name = new
					m.items[k] = .patchNameList(l)
				}
			}
			try m.modifySet(set) { s in
				for (slot, entry) in zip(slots, e) { s.items[slot] = .patchBank(entry.bank) }
			}
		}
	}
}

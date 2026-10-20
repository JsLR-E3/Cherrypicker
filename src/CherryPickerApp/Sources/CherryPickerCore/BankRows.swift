// Filas de la tabla de la pestaña Patch Banks (docs/20 §3.1; columnas del nib MainWindow:
// `open` «P», `bs0` «S0», `bs32` «S32», `name` «Patch Bank», `num` «#», `channels` «Channel Set»).
import MidnamKit

/// Leyenda de Patch Banks (capturas del original, EXP-009): color del nombre del banco.
public enum BankKind: Equatable, Sendable {
	/// Negro: todos los patches usan el bank select del banco.
	case normal
	/// Rojo: sin patches (o su lista no existe).
	case empty
	/// Azul: algún patch tiene un bank select efectivo distinto del banco (deducido; «custom» sale en azul).
	case mixed
}

public struct BankRow: Equatable, Sendable {
	public var kind: BankKind
	public var ref: BankRef
	/// Valor de CC0 del banco, o «-» si el banco no lo lleva (banco solo de agrupación).
	public var bankSelect0: String
	/// Valor de CC32 del banco, o «-».
	public var bankSelect32: String
	public var name: String
	/// Número de patches de su lista; nil si la lista citada no existe en el fichero.
	public var patchCount: Int?
	public var channelSet: String

	public init(ref: BankRef, kind: BankKind = .normal, bankSelect0: String, bankSelect32: String, name: String, patchCount: Int?, channelSet: String) {
		self.ref = ref
		self.kind = kind
		self.bankSelect0 = bankSelect0
		self.bankSelect32 = bankSelect32
		self.name = name
		self.patchCount = patchCount
		self.channelSet = channelSet
	}
}

public enum BankRows {
	/// Bancos de todos los ChannelNameSet del documento, en el orden del fichero.
	public static func rows(_ doc: MIDINameDocument) -> [BankRow] {
		var out: [BankRow] = []
		for (mi, item) in doc.items.enumerated() {
			guard case .masterDeviceNames(let master) = item else { continue }
			var lists: [String: PatchNameList] = [:]
			for l in master.patchNameLists {
				if let n = l.name, lists[n] == nil { lists[n] = l }
			}
			for (si, setItem) in master.items.enumerated() {
				guard case .channelNameSet(let set) = setItem else { continue }
				for (bi, bankItem) in set.items.enumerated() {
					guard case .patchBank(let bank) = bankItem else { continue }
					out.append(row(bank, ref: BankRef(master: mi, set: si, item: bi), channelSet: set.name, lists: lists))
				}
			}
		}
		return out
	}

	static func row(_ bank: PatchBank, ref: BankRef, channelSet: String, lists: [String: PatchNameList]) -> BankRow {
		var bs0 = "-", bs32 = "-"
		var count: Int?
		var list: PatchNameList?
		for item in bank.items {
			switch item {
			case .midiCommands(let cmds):
				for case .controlChange(let control, let value) in cmds {
					if control == "0" { bs0 = value } else if control == "32" { bs32 = value }
				}
			case .usesPatchNameList(let n):
				list = lists[n]
				count = lists[n].map(patchCount)
			case .patchNameList(let l):
				list = l
				count = patchCount(l)
			case .other:
				break
			}
		}
		var kind = BankKind.normal
		if (count ?? 0) == 0 {
			kind = .empty
		} else if let list, list.items.contains(where: { item in
			guard case .patch(let p) = item else { return false }
			return effectiveBankSelect(p, bank: (bs0, bs32)) != [bs0, bs32]
		}) {
			kind = .mixed
		}
		return BankRow(ref: ref, kind: kind, bankSelect0: bs0, bankSelect32: bs32, name: bank.name, patchCount: count, channelSet: channelSet)
	}

	/// Bank select con el que suena el patch: el suyo si lleva `PatchMIDICommands` (sin CC0/CC32 = «-»), si no el del
	/// banco (forma corta).
	static func effectiveBankSelect(_ p: Patch, bank: (String, String)) -> [String] {
		for case .patchMIDICommands(let cmds) in p.items {
			var v = ["-", "-"]
			for case .controlChange(let c, let value) in cmds {
				if c == "0" { v[0] = value } else if c == "32" { v[1] = value }
			}
			return v
		}
		return [bank.0, bank.1]
	}

	static func patchCount(_ list: PatchNameList) -> Int {
		list.items.reduce(0) { n, item in
			if case .patch = item { return n + 1 }
			return n
		}
	}
}

// Filas de la tabla de la pestaña Patch Banks (docs/20 §3.1; columnas del nib MainWindow:
// `open` «P», `bs0` «S0», `bs32` «S32», `name` «Patch Bank», `num` «#», `channels` «Channel Set»).
import MidnamKit

public struct BankRow: Equatable, Sendable {
	/// Valor de CC0 del banco, o «-» si el banco no lo lleva (banco solo de agrupación).
	public var bankSelect0: String
	/// Valor de CC32 del banco, o «-».
	public var bankSelect32: String
	public var name: String
	/// Número de patches de su lista; nil si la lista citada no existe en el fichero.
	public var patchCount: Int?
	public var channelSet: String

	public init(bankSelect0: String, bankSelect32: String, name: String, patchCount: Int?, channelSet: String) {
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
		for master in doc.masterDeviceNames {
			var lists: [String: PatchNameList] = [:]
			for l in master.patchNameLists {
				if let n = l.name, lists[n] == nil { lists[n] = l }
			}
			for set in master.channelNameSets {
				for case .patchBank(let bank) in set.items {
					out.append(row(bank, channelSet: set.name, lists: lists))
				}
			}
		}
		return out
	}

	static func row(_ bank: PatchBank, channelSet: String, lists: [String: PatchNameList]) -> BankRow {
		var bs0 = "-", bs32 = "-"
		var count: Int?
		for item in bank.items {
			switch item {
			case .midiCommands(let cmds):
				for case .controlChange(let control, let value) in cmds {
					if control == "0" { bs0 = value } else if control == "32" { bs32 = value }
				}
			case .usesPatchNameList(let n):
				count = lists[n].map(patchCount)
			case .patchNameList(let l):
				count = patchCount(l)
			case .other:
				break
			}
		}
		return BankRow(bankSelect0: bs0, bankSelect32: bs32, name: bank.name, patchCount: count, channelSet: channelSet)
	}

	static func patchCount(_ list: PatchNameList) -> Int {
		list.items.reduce(0) { n, item in
			if case .patch = item { return n + 1 }
			return n
		}
	}
}

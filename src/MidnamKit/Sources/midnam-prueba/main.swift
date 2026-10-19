// Genera el .midnam de prueba de T-012/EXP-006 para comprobar en DP 11.36:
// DOCTYPE con la URL de midi.org, qué nombre muestra «Master Names», bank select por banco y por preset,
// banco solo de agrupación, lista de controles con nombre y si DP recarga un fichero cambiado.
// Uso: swift run midnam-prueba <salida.midnam> [versión]   (versión 2: cambia nombres para la prueba de recarga)
import Foundation
import MidnamKit

let args = CommandLine.arguments
guard args.count >= 2 else {
	FileHandle.standardError.write("Uso: midnam-prueba <salida.midnam> [versión]\n".data(using: .utf8)!)
	exit(64)
}
let version = args.count >= 3 ? args[2] : "1"
let v = version == "1" ? "" : " v\(version)"

func patches(_ prefix: String, _ range: ClosedRange<Int>, bankSelect: [MIDICommand]? = nil) -> [PatchNameList.Item] {
	range.map { pc in
		let label = String(format: "%@%02d", prefix, pc + 1)
		if let bs = bankSelect {
			return .patch(Patch(number: label, name: "\(prefix) preset \(pc + 1)\(v)", programChange: nil,
			                    items: [.patchMIDICommands(bs + [.programChange(number: String(pc))])]))
		}
		return .patch(Patch(number: label, name: "\(prefix) preset \(pc + 1)\(v)", programChange: String(pc)))
	}
}

let set = ChannelNameSet(name: "CP Juego", items: [
	.availableForChannels((1...16).map { AvailableChannel(channel: String($0), available: true) }),
	.usesControlNameList("CP Controles"),
	.patchBank(PatchBank(name: "CP Banco A (CC0=0)\(v)", items: [
		.midiCommands([.controlChange(control: "0", value: "0"), .controlChange(control: "32", value: "0")]),
		.usesPatchNameList("CP Lista A")])),
	.patchBank(PatchBank(name: "CP Banco B (CC0=1)\(v)", items: [
		.midiCommands([.controlChange(control: "0", value: "1"), .controlChange(control: "32", value: "0")]),
		.usesPatchNameList("CP Lista B")])),
	.patchBank(PatchBank(name: "CP Agrupacion sin BS\(v)", items: [.usesPatchNameList("CP Lista C")])),
	.patchBank(PatchBank(name: "CP BS por preset\(v)", items: [.usesPatchNameList("CP Lista D")])),
])

let mode = CustomDeviceMode(name: "CP Prueba modo", items: [
	.channelNameSetAssignments((1...16).map { ChannelNameSetAssign(channel: String($0), nameSet: "CP Juego") })])

let controls = ControlNameList(name: "CP Controles", items: [
	.control(Control(number: "7", name: "CP Mezcla (CC7)")),
	.control(Control(number: "12", name: "CP Tiempo (CC12)")),
	.control(Control(number: "13", name: "CP Feedback (CC13)")),
])

let master = MasterDeviceNames(items: [
	.manufacturer("Cherrypicker"),
	.model("CP Prueba modelo"),
	.customDeviceMode(mode),
	.channelNameSet(set),
	.patchNameList(PatchNameList(name: "CP Lista A", items: patches("A", 0...9))),
	.patchNameList(PatchNameList(name: "CP Lista B", items: patches("B", 0...9))),
	.patchNameList(PatchNameList(name: "CP Lista C", items: patches("C", 20...24))),
	.patchNameList(PatchNameList(name: "CP Lista D", items: patches("D", 0...4, bankSelect: [
		.controlChange(control: "0", value: "2"), .controlChange(control: "32", value: "0")]))),
	.controlNameList(controls),
])

let doc = MIDINameDocument(items: [.author("Cherrypicker (MidnamKit) - prueba T-012 versión \(version)"),
                                   .masterDeviceNames(master)])
do {
	try MidnamFile(document: doc).text().write(toFile: args[1], atomically: true, encoding: .utf8)
	print("Escrito \(args[1]) (versión \(version))")
} catch {
	FileHandle.standardError.write("Error: \(error)\n".data(using: .utf8)!)
	exit(1)
}

import Foundation
import XCTest
@testable import MidnamKit

/// Lo que escribe MidnamKit se valida contra la DTD MIDINameDocument 1.0 con tools/validar_midnam.sh (EXP-005).
/// Las DTD están en reference/dtd (no versionado); si faltan, el test se omite.
final class DTDValidationTests: XCTestCase {
	let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized

	func validate(_ texts: [String: String]) throws -> (status: Int32, output: String) {
		let fm = FileManager.default
		try XCTSkipUnless(fm.fileExists(atPath: repo.appendingPathComponent("reference/dtd/MIDIEvents10.dtd").path),
		                  "sin DTD en reference/dtd")
		let tmp = fm.temporaryDirectory.appendingPathComponent("midnamkit-dtd-\(UUID().uuidString)")
		try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
		defer { try? fm.removeItem(at: tmp) }
		var paths: [String] = []
		for (name, text) in texts.sorted(by: { $0.key < $1.key }) {
			let url = tmp.appendingPathComponent(name)
			try text.write(to: url, atomically: true, encoding: .utf8)
			paths.append(url.path)
		}
		let p = Process()
		p.executableURL = repo.appendingPathComponent("tools/validar_midnam.sh")
		p.arguments = paths
		let pipe = Pipe()
		p.standardOutput = pipe
		p.standardError = pipe
		try p.run()
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		p.waitUntilExit()
		return (p.terminationStatus, String(decoding: data, as: UTF8.self))
	}

	func testLoQueEscribeMidnamKitEsValido() throws {
		let dtdForms = try MidnamFile(text: SyntheticTests.cherryPicker
			.replacingOccurrences(of: "\t\t\t<Patch Number=\"1\" Name=\"Uno\" ProgramChange=\"0\" />",
			                      with: "\t\t\t<Patch Number=\"1\" Name=\"Uno\" ProgramChange=\"0\" >\n\t\t\t\t<UsesControlNameList Name=\"Controles\" />\n\t\t\t</Patch>"))
		let r = try validate([
			"cherrypicker.midnam": try MidnamFile(text: SyntheticTests.cherryPicker).text(),
			"motu.midnam": try MidnamFile(text: SyntheticTests.motu).text(),
			"formas_dtd.midnam": dtdForms.text(),
		])
		XCTAssertEqual(r.status, 0, r.output)
	}

	/// Documento creado desde cero con el modelo (mínimo válido: modo, juego de canales, banco, lista).
	func testDocumentoNuevoEsValido() throws {
		let list = PatchNameList(name: "Halls", items: [.patch(Patch(number: "1", name: "Sala", programChange: "0"))])
		let bank = PatchBank(name: "Halls", items: [.midiCommands([.controlChange(control: "0", value: "1")]),
		                                             .usesPatchNameList("Halls")])
		let set = ChannelNameSet(name: "Presets", items: [
			.availableForChannels([AvailableChannel(channel: "1", available: true)]), .patchBank(bank)])
		let mode = CustomDeviceMode(name: "Mode 1", items: [
			.channelNameSetAssignments([ChannelNameSetAssign(channel: "1", nameSet: "Presets")])])
		let m = MasterDeviceNames(items: [.manufacturer("Fabricante"), .model("FX-1"), .customDeviceMode(mode),
		                                  .channelNameSet(set), .patchNameList(list)])
		let doc = MIDINameDocument(items: [.author("Cherrypicker"), .masterDeviceNames(m)])
		let r = try validate(["nuevo.midnam": MidnamFile(document: doc).text()])
		XCTAssertEqual(r.status, 0, r.output)
	}

	func testDetectaFicheroInvalido() throws {
		// ChannelNameSet sin PatchBank: la DTD exige al menos uno
		let bad = SyntheticTests.cherryPicker.replacingOccurrences(
			of: #"<PatchBank Name="Halls" >(.|\n)*?</PatchBank>\n\t\t\t<PatchBank Name="Solo agrupaci&apos;n" >(.|\n)*?</PatchBank>\n"#,
			with: "", options: .regularExpression)
		XCTAssertNotEqual(bad, SyntheticTests.cherryPicker)
		let r = try validate(["sin_bancos.midnam": bad])
		XCTAssertEqual(r.status, 1, r.output)
		XCTAssertTrue(r.output.contains("PatchBank+"), r.output)
	}
}

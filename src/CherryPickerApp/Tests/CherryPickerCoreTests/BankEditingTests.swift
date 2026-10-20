import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Edición de bancos sobre un fichero sintético válido contra la DTD 1.0 (sin datos del usuario).
final class BankEditingTests: XCTestCase {
	static let midnam = """
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE MIDINameDocument PUBLIC "-//MIDI Manufacturers Association//DTD MIDINameDocument 1.0//EN" "http://www.midi.org/dtds/MIDINameDocument10.dtd">
	<MIDINameDocument>
		<Author>Prueba</Author>
		<MasterDeviceNames>
			<Manufacturer>Prueba</Manufacturer>
			<Model>P-1</Model>
			<CustomDeviceMode Name="Modo" >
				<ChannelNameSetAssignments>
					<ChannelNameSetAssign Channel="1" NameSet="Todos" />
					<ChannelNameSetAssign Channel="10" NameSet="Drums" />
				</ChannelNameSetAssignments>
			</CustomDeviceMode>
			<ChannelNameSet Name="Todos" >
				<AvailableForChannels>
					<AvailableChannel Channel="1" Available="true" />
				</AvailableForChannels>
				<PatchBank Name="Uno" >
					<MIDICommands>
						<ControlChange Control="0" Value="1" />
						<ControlChange Control="32" Value="5" />
					</MIDICommands>
					<UsesPatchNameList Name="Uno" />
				</PatchBank>
				<PatchBank Name="Custom" >
					<UsesPatchNameList Name="Custom" />
				</PatchBank>
				<PatchBank Name="Tres" >
					<UsesPatchNameList Name="Compartida" />
				</PatchBank>
			</ChannelNameSet>
			<ChannelNameSet Name="Drums" >
				<AvailableForChannels>
					<AvailableChannel Channel="10" Available="true" />
				</AvailableForChannels>
				<PatchBank Name="Kits" >
					<UsesPatchNameList Name="Compartida" />
				</PatchBank>
			</ChannelNameSet>
			<PatchNameList Name="Uno" >
				<Patch Number="1" Name="A" ProgramChange="0" />
				<Patch Number="2" Name="B" ProgramChange="1" />
			</PatchNameList>
			<PatchNameList Name="Custom" >
				<Patch Number="1" Name="C" >
					<PatchMIDICommands>
						<ControlChange Control="0" Value="2" />
						<ControlChange Control="32" Value="0" />
						<ProgramChange Number="7" />
					</PatchMIDICommands>
				</Patch>
				<Patch Number="2" Name="D" ProgramChange="3" />
			</PatchNameList>
			<PatchNameList Name="Compartida" >
				<Patch Number="1" Name="E" ProgramChange="0" />
			</PatchNameList>
		</MasterDeviceNames>
	</MIDINameDocument>

	"""

	var file: MidnamFile!
	var doc: MIDINameDocument { get { file.document } set { file.document = newValue } }

	override func setUp() {
		file = try! MidnamFile(text: Self.midnam)
	}

	func rows() -> [BankRow] { BankRows.rows(doc) }
	func ref(_ name: String) -> BankRef { rows().first { $0.name == name }!.ref }
	func list(_ name: String) -> PatchNameList? { doc.masterDeviceNames[0].patchNameLists.first { $0.name == name } }
	func patches(_ list: String) -> [Patch] {
		self.list(list)!.items.compactMap { if case .patch(let p) = $0 { return p } else { return nil } }
	}

	func testRenameRenamesExclusiveList() throws {
		try doc.renameBank(ref("Uno"), to: " Pianos ")
		XCTAssertEqual(rows().map(\.name), ["Pianos", "Custom", "Tres", "Kits"])
		XCTAssertNotNil(list("Pianos"))
		XCTAssertEqual(doc.bank(ref("Pianos"))?.usedListName, "Pianos")
		XCTAssertEqual(rows()[0].patchCount, 2)
	}

	func testRenameKeepsSharedList() throws {
		try doc.renameBank(ref("Tres"), to: "Otro")
		XCTAssertEqual(doc.bank(ref("Otro"))?.usedListName, "Compartida")
		XCTAssertNotNil(list("Compartida"))
	}

	func testRenameRejectsDuplicateAndEmpty() {
		XCTAssertThrowsError(try doc.renameBank(ref("Uno"), to: "Kits")) {
			XCTAssertEqual($0 as? BankEditError, .duplicateName("Kits"))
		}
		XCTAssertThrowsError(try doc.renameBank(ref("Uno"), to: "  ")) {
			XCTAssertEqual($0 as? BankEditError, .emptyName)
		}
	}

	func testBankSelectValues() {
		XCTAssertEqual(try BankRef.normalizeBankSelect(" 007 "), "7")
		XCTAssertEqual(try BankRef.normalizeBankSelect("-"), "-")
		XCTAssertThrowsError(try BankRef.normalizeBankSelect("128"))
		XCTAssertThrowsError(try BankRef.normalizeBankSelect(""))
	}

	func testBankSelectWithoutKeepsPatchesWithOwn() throws {
		try doc.setBankSelect(ref("Custom"), bs0: "4", bs32: "-", apply: .patchesWithoutBankSelects)
		let r = rows()[1]
		XCTAssertEqual([r.bankSelect0, r.bankSelect32], ["4", "-"])
		XCTAssertEqual(patches("Custom")[0].items, [.patchMIDICommands([
			.controlChange(control: "0", value: "2"), .controlChange(control: "32", value: "0"), .programChange(number: "7")])])
		XCTAssertEqual(patches("Custom")[1], Patch(number: "2", name: "D", programChange: "3"), "forma corta: hereda")
	}

	func testBankKinds() throws {
		XCTAssertEqual(rows().map(\.kind), [.normal, .mixed, .normal, .normal])
		try doc.addBank(name: "Vacio", bs0: "-", bs32: "-", master: ref("Kits").master, set: ref("Kits").set)
		XCTAssertEqual(rows().first { $0.name == "Vacio" }?.kind, .empty)
		try doc.setBankSelect(ref("Custom"), bs0: "1", bs32: "0", apply: .allPatches)
		XCTAssertEqual(rows()[1].kind, .normal)
	}

	/// Contraste con CherryPicker 3 (EXP-009): `BS base.midnam` y lo que guardó el original con cada opción de la hoja
	/// Bank Selects en el banco «custom» (B Sel 0 = 5, B Sel 32 = 0). Se reproduce byte a byte.
	func testBankSelectOptionsMatchOriginal() throws {
		let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
			.appendingPathComponent("../../../../captures/exp009").standardized
		func text(_ name: String) throws -> String {
			try String(contentsOf: dir.appendingPathComponent(name), encoding: .utf8)
		}
		for (n, apply) in [(1, BankSelectApply.allPatches), (2, .patchesWithoutBankSelects), (3, .patchesWithBankSelects)] {
			var f = try MidnamFile(text: try text("BS base.midnam"))
			let custom = BankRows.rows(f.document).first { $0.name == "custom" }!.ref
			try f.document.setBankSelect(custom, bs0: "5", bs32: "0", apply: apply)
			XCTAssertEqual(f.text(), try text("BS opcion\(n).midnam"), "opción \(n)")
		}
	}

	func testBankSelectAllRemovesPatchLevel() throws {
		try doc.setBankSelect(ref("Custom"), bs0: "4", bs32: "0", apply: .allPatches)
		let p = patches("Custom")
		XCTAssertEqual(p[0], Patch(number: "1", name: "C", programChange: "7"))
		XCTAssertEqual(p[1], Patch(number: "2", name: "D", programChange: "3"))
	}

	func testBankSelectWithPatchesRewritesOwn() throws {
		try doc.setBankSelect(ref("Custom"), bs0: "9", bs32: "-", apply: .patchesWithBankSelects)
		let p = patches("Custom")
		XCTAssertEqual(p[0].items, [.patchMIDICommands([.controlChange(control: "0", value: "9"), .programChange(number: "7")])])
		XCTAssertEqual(p[1], Patch(number: "2", name: "D", programChange: "3"))
	}

	func testBankSelectDashRemovesMIDICommands() throws {
		try doc.setBankSelect(ref("Uno"), bs0: "-", bs32: "-", apply: .allPatches)
		XCTAssertEqual(doc.bank(ref("Uno"))?.items, [.usesPatchNameList("Uno")])
	}

	func testAddBankCreatesOwnEmptyList() throws {
		let todos = rows()[0].ref.set
		let r = try doc.addBank(name: "Nuevo", bs0: "3", bs32: "-", master: rows()[0].ref.master, set: todos)
		XCTAssertEqual(rows().map(\.name), ["Uno", "Custom", "Tres", "Nuevo", "Kits"])
		XCTAssertEqual(doc.bank(r)?.items, [.midiCommands([.controlChange(control: "0", value: "3")]), .usesPatchNameList("Nuevo")])
		XCTAssertEqual(list("Nuevo")?.items, [])
		XCTAssertThrowsError(try doc.addBank(name: "Nuevo", bs0: "-", bs32: "-", master: r.master, set: todos)) {
			XCTAssertEqual($0 as? BankEditError, .duplicateName("Nuevo"))
		}
		XCTAssertThrowsError(try doc.addBank(name: "Otro", bs0: "-", bs32: "-", master: 0, set: todos)) {
			XCTAssertEqual($0 as? BankEditError, .notFound)
		}
	}

	func testDeleteBanksRemovesUnusedLists() throws {
		try doc.deleteBanks([ref("Uno"), ref("Tres")])
		XCTAssertEqual(rows().map(\.name), ["Custom", "Kits"])
		XCTAssertNil(list("Uno"))
		XCTAssertNotNil(list("Compartida"), "la usa Kits")
	}

	func testCannotEmptyAChannelSet() {
		XCTAssertThrowsError(try doc.deleteBanks([ref("Kits")])) {
			XCTAssertEqual($0 as? BankEditError, .lastBankInChannelSet("Drums"))
		}
		XCTAssertThrowsError(try doc.moveBank(ref("Kits"), toChannelSet: ref("Uno").set))
	}

	func testMoveBankToOtherChannelSet() throws {
		let r = try doc.moveBank(ref("Uno"), toChannelSet: ref("Kits").set)
		XCTAssertEqual(rows().map(\.name), ["Custom", "Tres", "Kits", "Uno"])
		XCTAssertEqual(rows().last?.channelSet, "Drums")
		XCTAssertEqual(doc.bank(r)?.name, "Uno")
	}

	func testReorderBank() throws {
		try doc.reorderBank(ref("Tres"), toPosition: 0)
		XCTAssertEqual(rows().map(\.name), ["Tres", "Uno", "Custom", "Kits"])
		try doc.reorderBank(ref("Tres"), toPosition: 3)
		XCTAssertEqual(rows().map(\.name), ["Uno", "Custom", "Tres", "Kits"])
		try doc.reorderBank(ref("Uno"), toPosition: 2)
		XCTAssertEqual(rows().map(\.name), ["Custom", "Uno", "Tres", "Kits"])
	}

	/// Tras editar, lo escrito sigue siendo válido contra la DTD (tools/validar_midnam.sh, EXP-005).
	func testEditedFileIsValid() throws {
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		let fm = FileManager.default
		try XCTSkipUnless(fm.fileExists(atPath: repo.appendingPathComponent("reference/dtd/MIDIEvents10.dtd").path),
		                  "sin DTD en reference/dtd")
		try doc.renameBank(ref("Uno"), to: "Pianos")
		try doc.setBankSelect(ref("Custom"), bs0: "4", bs32: "-", apply: .allPatches)
		try doc.setBankSelect(ref("Pianos"), bs0: "-", bs32: "-", apply: .patchesWithoutBankSelects)
		try doc.addBank(name: "Vacio", bs0: "-", bs32: "-", master: ref("Kits").master, set: ref("Kits").set)
		try doc.deleteBanks([ref("Tres")])
		try doc.reorderBank(ref("Vacio"), toPosition: 0)

		let url = fm.temporaryDirectory.appendingPathComponent("cherrypicker-\(UUID().uuidString).midnam")
		defer { try? fm.removeItem(at: url) }
		try file.text().write(to: url, atomically: true, encoding: .utf8)
		let p = Process()
		p.executableURL = repo.appendingPathComponent("tools/validar_midnam.sh")
		p.arguments = [url.path]
		let pipe = Pipe()
		p.standardOutput = pipe
		p.standardError = pipe
		try p.run()
		let out = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
		p.waitUntilExit()
		XCTAssertEqual(p.terminationStatus, 0, out)
	}

	/// Sin cambios, el fichero se reescribe idéntico.
	func testUneditedRoundTrip() throws {
		XCTAssertEqual(file.text(), Self.midnam)
	}
}

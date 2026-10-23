import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Merge, Find y Zap Dups (T-019) sobre el fichero sintético de BankEditingTests: «Uno» (1/5: A 0, B 1), «Custom»
/// (sin bank select: C 2/0 7, D «-» 3), «Tres» (sin bank select, lista «Compartida»: E) y «Kits» (Drums, misma lista).
final class BankToolsTests: XCTestCase {
	var file: MidnamFile!
	var doc: MIDINameDocument { get { file.document } set { file.document = newValue } }

	override func setUp() {
		file = try! MidnamFile(text: BankEditingTests.midnam)
	}

	func ref(_ name: String) -> BankRef { BankRows.rows(doc).first { $0.name == name }!.ref }
	func cols(_ bank: String) -> [String] {
		doc.patchRows(ref(bank)).map { "\($0.bankSelect0)/\($0.bankSelect32) \($0.program) \($0.name)" }
	}
	func banks() -> [String] { BankRows.rows(doc).map { "\($0.channelSet):\($0.name)" } }

	func testFind() {
		XCTAssertEqual(doc.findPatches(containing: "a").map(\.name), ["A"])
		XCTAssertEqual(doc.findPatches(containing: " ").count, 0, "sin texto, nada")
		let e = doc.findPatches(containing: "e")
		XCTAssertEqual(e.map(\.bankName), ["Tres", "Kits"], "una lista compartida sale en cada banco")
		let c = doc.findPatches(containing: "c")[0]
		XCTAssertEqual([c.bankName, c.bankSelect0, c.bankSelect32, c.program, c.ascii], ["Custom", "2", "0", "7", "1"])
	}

	/// «Remove Duplicates» del Finder: mismo bank select efectivo y Program Change.
	func testFoundRemovingDuplicates() {
		let e = doc.findPatches(containing: "e")
		XCTAssertEqual(FoundPatch.removingDuplicates(e).map(\.bankName), ["Tres"])
	}

	/// «Add New Bank With Patches»: un Custom Bank (sin bank select) con copias que suenan igual.
	func testAddBankWithFoundPatches() throws {
		let found = doc.findPatches(containing: "a") + doc.findPatches(containing: "d")
		let r = try doc.addBank(name: "Encontrados", bs0: "-", bs32: "-", master: 1, set: ref("Uno").set,
		                        withPatches: found.map { ($0.bank, $0.index) })
		XCTAssertEqual(doc.bank(r)?.name, "Encontrados")
		XCTAssertEqual(cols("Encontrados"), ["1/5 0 A", "-/- 3 D"])
		XCTAssertEqual(cols("Uno").count, 2, "el original no cambia")
	}

	func testMerge() throws {
		try doc.mergeBanks([ref("Custom"), ref("Uno")], name: "Juntos", bs0: "1", bs32: "5", set: ref("Uno").set)
		XCTAssertEqual(banks(), ["Todos:Tres", "Todos:Juntos", "Drums:Kits"])
		// En el orden de la tabla; los de 1/5 en forma corta, los demás con el suyo.
		XCTAssertEqual(cols("Juntos"), ["1/5 0 A", "1/5 1 B", "2/0 7 C", "-/- 3 D"])
		XCTAssertEqual(doc.patchList(ref("Juntos"))!.patches[0], Patch(number: "1", name: "A", programChange: "0"))
		XCTAssertFalse(file.text().contains("PatchNameList Name=\"Uno\""), "la lista de un banco borrado se va")
	}

	func testMergeKeepingOriginalsAndOtherChannelSet() throws {
		try doc.mergeBanks([ref("Uno"), ref("Tres")], name: "Juntos", bs0: "-", bs32: "-", set: ref("Kits").set,
		                   keepOriginals: true)
		XCTAssertEqual(banks(), ["Todos:Uno", "Todos:Custom", "Todos:Tres", "Drums:Kits", "Drums:Juntos"])
		XCTAssertEqual(cols("Juntos"), ["1/5 0 A", "1/5 1 B", "-/- 0 E"])
	}

	func testMergeErrors() {
		XCTAssertThrowsError(try doc.mergeBanks([ref("Uno")], name: "X", bs0: "-", bs32: "-", set: ref("Uno").set))
		XCTAssertThrowsError(try doc.mergeBanks([ref("Uno"), ref("Tres")], name: "Custom", bs0: "-", bs32: "-",
		                                        set: ref("Uno").set)) { XCTAssertEqual($0 as? BankEditError, .duplicateName("Custom")) }
		// Los únicos bancos de Todos no pueden irse a Drums.
		XCTAssertThrowsError(try doc.mergeBanks([ref("Uno"), ref("Custom"), ref("Tres")], name: "X", bs0: "-", bs32: "-",
		                                        set: ref("Kits").set)) {
			XCTAssertEqual($0 as? BankEditError, .lastBankInChannelSet("Todos"))
		}
	}

	/// Zap Dups: copiar A (1/5 0) y B al Custom Bank deja duplicados en Uno; se borran del Standard Bank.
	func testZapDups() throws {
		XCTAssertEqual(doc.duplicatePatches().count, 0)
		try doc.copyPatches(from: ref("Uno"), at: [1], to: ref("Custom"))
		XCTAssertEqual(cols("Custom").last, "1/5 1 B")
		XCTAssertEqual(try doc.zapDuplicates(), 1)
		XCTAssertEqual(cols("Uno"), ["1/5 0 A"])
		XCTAssertEqual(cols("Custom"), ["2/0 7 C", "-/- 3 D", "1/5 1 B"], "el Custom no se toca")
	}

	/// Solo dentro del Channel Set: un Custom Bank de Drums no afecta a Uno (Todos), aunque suene igual.
	func testZapDupsOnlyInSameChannelSet() throws {
		let drums = ref("Kits").set
		try doc.addBank(name: "Otro", bs0: "1", bs32: "5", master: 1, set: drums)
		try doc.addPatches(ref("Otro"), names: ["X"], startAt: 0, startAscii: "1", useBankSelects: true)
		try doc.addBank(name: "CustomD", bs0: "-", bs32: "-", master: 1, set: drums)
		try doc.copyPatches(from: ref("Otro"), at: [0], to: ref("CustomD"))
		XCTAssertEqual(doc.duplicatePatches().map { doc.bank($0.bank)!.name }, ["Otro"])
		try doc.zapDuplicates()
		XCTAssertEqual(cols("Uno").count, 2)
		XCTAssertEqual(cols("Otro"), [])
		XCTAssertEqual(cols("CustomD"), ["1/5 0 X"])
	}

	func testSoundKeyComparesNumbers() {
		XCTAssertEqual(SoundKey("01", "5", "007"), SoundKey("1", "5", "7"))
		XCTAssertNotEqual(SoundKey("-", "5", "7"), SoundKey("0", "5", "7"))
	}
}

import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Import (T-022): del fichero de EXP-010 («Melodicos»: Kits 2/0; «Bateria»: Kits extra 2/1, Pianos CP 4/0, Cuerdas
/// 5/0, Sintes 1/0; 3 patches cada uno) al fichero sintético de BankEditingTests.
final class ImportTests: XCTestCase {
	var file: MidnamFile!
	var source: MIDINameDocument!
	var doc: MIDINameDocument { get { file.document } set { file.document = newValue } }

	override func setUp() {
		file = try! MidnamFile(text: BankEditingTests.midnam)
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		source = try! MidnamFile(text: String(contentsOf: repo.appendingPathComponent("captures/exp011/Prueba canales.midnam"))).document
	}

	func ref(_ name: String) -> BankRef { BankRows.rows(doc).first { $0.name == name }!.ref }
	func cols(_ bank: String) -> [String] {
		doc.patchRows(ref(bank)).map { "\($0.bankSelect0)/\($0.bankSelect32) \($0.program) \($0.name)" }
	}
	func list(_ name: String) -> ImportableList { source.importableLists().first { $0.name == name }! }

	func testImportableLists() {
		XCTAssertEqual(source.deviceDescription, "Cherrypicker CP Canales")
		XCTAssertEqual(source.importableLists().map { "\($0.name) \($0.count) \($0.bankSelect0)/\($0.bankSelect32)" },
		               ["Kits 3 2/0", "Kits extra 3 2/1", "Pianos CP 3 4/0", "Cuerdas 3 5/0", "Sintes 3 1/0"])
		// Destino propuesto: el banco del mismo nombre.
		XCTAssertEqual(doc.proposedImportDestination(list("Kits"), master: 1), ref("Kits"))
		XCTAssertNil(doc.proposedImportDestination(list("Sintes"), master: 1))
	}

	/// Los patches importados sustituyen a los del banco y siguen sonando con su bank select de origen.
	func testImportIntoExistingBank() throws {
		try doc.importList(list("Pianos CP"), from: source, into: ref("Uno"))
		XCTAssertEqual(cols("Uno"), ["4/0 0 Pianos 1", "4/0 1 Pianos 2", "4/0 2 Pianos 3"])
		try doc.importList(list("Kits"), from: source, into: ref("Kits"))
		XCTAssertEqual(cols("Kits"), ["2/0 0 Kits 1", "2/0 1 Kits 2", "2/0 2 Kits 3"])
		XCTAssertEqual(cols("Tres").count, 3, "Tres comparte la lista con Kits")
	}

	func testImportAsNewBank() throws {
		let r = try doc.importListAsNewBank(list("Sintes"), from: source, master: 1, set: ref("Uno").set)
		XCTAssertEqual(doc.bank(r)?.name, "Sintes")
		XCTAssertEqual(BankRows.rows(doc).first { $0.name == "Sintes" }.map { "\($0.bankSelect0)/\($0.bankSelect32) \($0.kind)" },
		               "1/0 normal")
		XCTAssertEqual(doc.patchList(r)!.patches.first, Patch(number: "001", name: "Sintes 1", programChange: "0"),
		               "forma corta: hereda el bank select del banco")
		let r2 = try doc.importListAsNewBank(list("Sintes"), from: source, master: 1, set: ref("Uno").set)
		XCTAssertEqual(doc.bank(r2)?.name, "Sintes 2")
	}
}

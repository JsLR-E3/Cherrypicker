import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Árbol de sub-bancos de D-010 (T-033) sobre un fichero sintético válido contra la DTD 1.0 (sin datos del usuario).
final class BankTreeTests: XCTestCase {
	/// Bancos de «Todos» y «Drums»; cada uno con su lista del mismo nombre salvo «Live» (lista «Compartida», que también
	/// usa «Kits»).
	static func midnam(_ todos: [String], drums: [String] = ["Kits"]) -> String {
		func bank(_ n: String, _ list: String? = nil) -> String {
			"<PatchBank Name=\"\(n)\" ><UsesPatchNameList Name=\"\(list ?? n)\" /></PatchBank>"
		}
		let banks = todos.map { $0 == "Live" ? bank($0, "Compartida") : bank($0) }.joined()
		let kits = drums.map { $0 == "Kits" ? bank($0, "Compartida") : bank($0) }.joined()
		let lists = (todos + drums).filter { $0 != "Live" && $0 != "Kits" } + ["Compartida"]
		return """
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
					<AvailableForChannels><AvailableChannel Channel="1" Available="true" /></AvailableForChannels>
					\(banks)
				</ChannelNameSet>
				<ChannelNameSet Name="Drums" >
					<AvailableForChannels><AvailableChannel Channel="10" Available="true" /></AvailableForChannels>
					\(kits)
				</ChannelNameSet>
				\(lists.map { "<PatchNameList Name=\"\($0)\" ><Patch Number=\"1\" Name=\"P \($0)\" ProgramChange=\"0\" /></PatchNameList>" }.joined())
			</MasterDeviceNames>
		</MIDINameDocument>

		"""
	}

	static let tree = ["• All", "├ Halls", "└ Rooms", "Indoor", "├ Medium", "└ Small", "Outdoor", "Live"]

	var file: MidnamFile!
	var doc: MIDINameDocument { get { file.document } set { file.document = newValue } }

	override func setUp() { load(Self.tree) }

	func load(_ todos: [String], drums: [String] = ["Kits"]) {
		file = try! MidnamFile(text: Self.midnam(todos, drums: drums))
	}

	func names() -> [String] { BankRows.rows(doc).filter { $0.channelSet == "Todos" }.map(\.name) }
	func ref(_ name: String) -> BankRef { BankRows.rows(doc).first { $0.name == name }!.ref }
	func listNames() -> [String] { doc.masterDeviceNames[0].patchNameLists.compactMap(\.name) }

	/// Cada banco usa una lista que existe y, si es suya, con su mismo nombre (P2, EXP-006).
	func assertListsMatch(file: StaticString = #filePath, line: UInt = #line) {
		let lists = Set(listNames())
		for r in BankRows.rows(doc) {
			let used = doc.bank(r.ref)!.usedListName!
			XCTAssertTrue(lists.contains(used), "falta la lista \(used)", file: file, line: line)
			if used != "Compartida" { XCTAssertEqual(used, r.name, file: file, line: line) }
		}
	}

	func testParseAndCompose() {
		XCTAssertEqual(TreeName(parsing: "├ Halls"), TreeName(base: "Halls", isChild: true))
		XCTAssertEqual(TreeName(parsing: "└ Halls"), TreeName(base: "Halls", isChild: true))
		XCTAssertEqual(TreeName(parsing: "• All"), TreeName(base: "All", isAll: true))
		XCTAssertEqual(TreeName(parsing: "- Hall"), TreeName(base: "- Hall"))
		XCTAssertEqual(TreeName(base: "X", isChild: true).name(last: true), "└ X")
		XCTAssertEqual(TreeName(base: "X", isAll: true).name(last: true), "• X")
	}

	func testIndentJoinsGroupAboveAndRedoesLast() throws {
		try doc.indentBanks([ref("Live")])
		XCTAssertEqual(names(), ["• All", "├ Halls", "└ Rooms", "Indoor", "├ Medium", "└ Small", "Outdoor", "└ Live"])
		try doc.indentBanks([ref("Outdoor")])
		XCTAssertEqual(names(), ["• All", "├ Halls", "└ Rooms", "Indoor", "├ Medium", "├ Small", "├ Outdoor", "└ Live"])
		assertListsMatch()
		// La lista compartida no cambia de nombre.
		XCTAssertEqual(doc.bank(ref("└ Live"))?.usedListName, "Compartida")
	}

	func testIndentNotFirstAndDropsAllMark() throws {
		XCTAssertFalse(doc.canIndent(ref("• All")))
		XCTAssertFalse(doc.canIndent(ref("├ Halls")))
		XCTAssertTrue(doc.canIndent(ref("Indoor")))
		try doc.indentBanks([ref("• All")])
		XCTAssertEqual(names(), Self.tree)
		load(["Uno", "• Dos"])
		try doc.indentBanks([ref("• Dos")])
		XCTAssertEqual(names(), ["Uno", "└ Dos"])
	}

	func testOutdentMovesBehindGroup() throws {
		try doc.outdentBanks([ref("├ Halls")])
		XCTAssertEqual(names(), ["• All", "└ Rooms", "Halls", "Indoor", "├ Medium", "└ Small", "Outdoor", "Live"])
		try doc.outdentBanks([ref("├ Medium"), ref("└ Small")])
		XCTAssertEqual(names(), ["• All", "└ Rooms", "Halls", "Indoor", "Medium", "Small", "Outdoor", "Live"])
		assertListsMatch()
	}

	func testToggleAllMark() throws {
		try doc.toggleAllMark([ref("Indoor"), ref("├ Halls")])
		XCTAssertEqual(names()[3], "• Indoor")
		XCTAssertEqual(names()[1], "├ Halls")
		try doc.toggleAllMark([ref("• Indoor"), ref("• All")])
		XCTAssertEqual(names()[0], "All")
		XCTAssertEqual(names()[3], "Indoor")
		assertListsMatch()
	}

	func testRenameKeepsPrefix() throws {
		try doc.renameBank(ref("└ Rooms"), keepingTreeTo: "Chambers")
		XCTAssertEqual(names()[2], "└ Chambers")
		// Si se escribe un prefijo, se quita.
		try doc.renameBank(ref("• All"), keepingTreeTo: "├ Everything")
		XCTAssertEqual(names()[0], "• Everything")
		XCTAssertThrowsError(try doc.renameBank(ref("Outdoor"), keepingTreeTo: "Indoor")) {
			XCTAssertEqual($0 as? BankEditError, .duplicateName("Indoor"))
		}
		XCTAssertThrowsError(try doc.renameBank(ref("Outdoor"), keepingTreeTo: "├ ")) {
			XCTAssertEqual($0 as? BankEditError, .emptyName)
		}
		assertListsMatch()
	}

	/// Dos sub-bancos con el mismo nombre en grupos distintos: se propone «nombre (padre)» para los dos; con las
	/// propuestas (o lo que escriba el usuario) la operación sale.
	func testDuplicateChildProposesParent() throws {
		load(["Indoor", "├ Medium", "└ Small", "Outdoor", "Medium"])
		let medium = ref("Medium"), inner = ref("├ Medium")
		var conflicts: [TreeConflict] = []
		XCTAssertThrowsError(try doc.indentBanks([medium])) {
			guard case .treeNameConflicts(let c)? = $0 as? BankEditError else { return XCTFail("\($0)") }
			conflicts = c
		}
		XCTAssertEqual(names(), ["Indoor", "├ Medium", "└ Small", "Outdoor", "Medium"])
		XCTAssertEqual(conflicts.map(\.proposal), ["Medium (Indoor)", "Medium (Outdoor)"])
		XCTAssertEqual(conflicts.map(\.prefix), ["├ ", "└ "])
		XCTAssertEqual(conflicts.map(\.ref), [inner, medium])
		try doc.indentBanks([medium], overrides: [inner: "Indoor Medium", medium: "Medium (Outdoor)"])
		XCTAssertEqual(names(), ["Indoor", "├ Indoor Medium", "└ Small", "Outdoor", "└ Medium (Outdoor)"])
		assertListsMatch()
	}

	/// «├ Medium» y «└ Medium» también chocan (al reordenar serían el mismo nombre).
	func testDuplicateBaseWithOtherPrefixAndOtherChannelSet() throws {
		load(["Indoor", "├ Medium", "└ Small", "Outdoor", "Medium"], drums: ["Kits", "Pads", "Medium"])
		XCTAssertThrowsError(try doc.indentBanks([ref("Medium")]))
		// Un sub-banco en otro Channel Set con el mismo nombre que el del fichero ya existente no cuenta como cambio.
		load(["Indoor", "└ Medium"], drums: ["Kits", "Pads", "└ Medium"])
		try doc.normalizeTree(autoResolve: false)
		XCTAssertEqual(names(), ["Indoor", "└ Medium"])
	}

	func testMoveGroupCarriesChildren() throws {
		// «Indoor» (con sus dos sub-bancos) al principio.
		try doc.moveBankGroup(ref("Indoor"), toPosition: 0)
		XCTAssertEqual(names(), ["Indoor", "├ Medium", "└ Small", "• All", "├ Halls", "└ Rooms", "Outdoor", "Live"])
		// Dentro de otro grupo no se suelta.
		XCTAssertFalse(doc.isTreeGroupBoundary(master: ref("Indoor").master, set: ref("Indoor").set, position: 4))
		try doc.moveBankGroup(ref("Outdoor"), toPosition: 4)
		XCTAssertEqual(names()[6], "Outdoor")
		// Al final.
		try doc.moveBankGroup(ref("• All"), toPosition: 8)
		XCTAssertEqual(names(), ["Indoor", "├ Medium", "└ Small", "Outdoor", "Live", "• All", "├ Halls", "└ Rooms"])
		assertListsMatch()
	}

	func testMoveChildChangesGroup() throws {
		// «├ Halls» detrás de «Outdoor»: pasa a su grupo.
		try doc.moveBankGroup(ref("├ Halls"), toPosition: 7)
		XCTAssertEqual(names(), ["• All", "└ Rooms", "Indoor", "├ Medium", "└ Small", "Outdoor", "└ Halls", "Live"])
		// Arriba del todo: banco normal.
		try doc.moveBankGroup(ref("└ Small"), toPosition: 0)
		XCTAssertEqual(names(), ["Small", "• All", "└ Rooms", "Indoor", "└ Medium", "Outdoor", "└ Halls", "Live"])
		assertListsMatch()
	}

	func testNormalizeAfterDeleteAndChannelSetMove() throws {
		try doc.deleteBanks([ref("└ Small")])
		try doc.normalizeTree()
		XCTAssertEqual(names(), ["• All", "├ Halls", "└ Rooms", "Indoor", "└ Medium", "Outdoor", "Live"])
		// Borrar el primer padre deja sus sub-bancos sin padre: pasan a bancos normales.
		try doc.deleteBanks([ref("• All")])
		try doc.normalizeTree()
		XCTAssertEqual(names(), ["Halls", "Rooms", "Indoor", "└ Medium", "Outdoor", "Live"])
		XCTAssertEqual(doc.withTreeChildren([ref("Indoor")]), [ref("Indoor"), ref("└ Medium")])
		try doc.moveBanks(doc.withTreeChildren([ref("Indoor")]), toChannelSet: ref("Kits").set)
		try doc.normalizeTree()
		XCTAssertEqual(BankRows.rows(doc).filter { $0.channelSet == "Drums" }.map(\.name), ["Kits", "Indoor", "└ Medium"])
		assertListsMatch()
	}

	func testAdoptIntoGroup() throws {
		let r = try doc.addBank(name: "Big", bs0: "-", bs32: "-", master: ref("Live").master, set: ref("Live").set)
		_ = try doc.reorderBank(r, toPosition: 5)
		XCTAssertEqual(names()[5], "Big")
		try doc.adoptIntoGroup([ref("Big")])
		XCTAssertEqual(names(), ["• All", "├ Halls", "└ Rooms", "Indoor", "├ Medium", "├ Big", "└ Small", "Outdoor", "Live"])
		// Entre grupos se queda como banco normal.
		try doc.adoptIntoGroup([ref("Outdoor")])
		XCTAssertEqual(names()[7], "Outdoor")
		assertListsMatch()
	}

	func testConvertDashSubBanks() throws {
		load(["- Lone", "PRESET", "- Hall", "- Plate", "- Samplig", "CLASSIC", "USER"])
		XCTAssertEqual(doc.dashSubBanks().count, 3)
		try doc.convertDashSubBanks()
		XCTAssertEqual(names(), ["- Lone", "PRESET", "├ Hall", "├ Plate", "└ Samplig", "CLASSIC", "USER"])
		XCTAssertTrue(doc.dashSubBanks().isEmpty)
		assertListsMatch()
	}

	/// Sin prefijos de D-010, nada cambia; tras editar el árbol, lo escrito es válido contra la DTD
	/// (tools/validar_midnam.sh, EXP-005).
	func testNoTreeIsUntouchedAndOutputValid() throws {
		load(["Uno", "Dos", "Live"])
		let before = doc
		try doc.normalizeTree(autoResolve: false)
		XCTAssertEqual(doc, before)

		load(Self.tree)
		try doc.indentBanks([ref("Live")])
		try doc.toggleAllMark([ref("Indoor")])
		let text = file.text()
		XCTAssertTrue(text.contains("<UsesPatchNameList Name=\"└ Live\"") == false)
		XCTAssertTrue(text.contains("<PatchBank Name=\"└ Live\""))
		XCTAssertTrue(text.contains("<PatchNameList Name=\"• Indoor\""))
		XCTAssertTrue(text.contains("<UsesPatchNameList Name=\"• Indoor\""))

		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		let fm = FileManager.default
		try XCTSkipUnless(fm.fileExists(atPath: repo.appendingPathComponent("reference/dtd/MIDIEvents10.dtd").path),
		                  "sin DTD en reference/dtd")
		let url = fm.temporaryDirectory.appendingPathComponent("cherrypicker-\(UUID().uuidString).midnam")
		defer { try? fm.removeItem(at: url) }
		try text.write(to: url, atomically: true, encoding: .utf8)
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
}

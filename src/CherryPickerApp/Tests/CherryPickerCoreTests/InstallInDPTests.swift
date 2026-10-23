import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// «Install in DP…» (T-024, P3).
final class InstallInDPTests: XCTestCase {
	func testNames() {
		XCTAssertEqual(InstallInDP.folder(manufacturer: "TC Electronic").path, "/Library/Audio/MIDI Devices/MOTU/TC Electronic")
		XCTAssertEqual(InstallInDP.folder(manufacturer: "A/B:C").lastPathComponent, "A-B-C")
		XCTAssertEqual(InstallInDP.middevName(manufacturer: "Roland"), "Roland (CherryPicker).middev")
		XCTAssertEqual(InstallInDP.midnamName("Mi módulo.midnam"), "Mi módulo.midnam")
		XCTAssertEqual(InstallInDP.midnamName(" Banco/1 "), "Banco-1.midnam")
		XCTAssertEqual(InstallInDP.midnamName(""), "Untitled.midnam")
	}

	func testNewMiddev() {
		let text = InstallInDP.middev(adding: "R&D", model: "X \"1\"", to: nil)
		XCTAssertEqual(middevEntries(text).map { "\($0.manufacturer)|\($0.model)" }, ["R&D|X \"1\""])
		XCTAssertTrue(text.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE MIDIDeviceTypes"))
		XCTAssertTrue(text.contains("Manufacturer=\"R&amp;D\" Model=\"X &quot;1&quot;\""))
	}

	/// Se añade delante del cierre sin tocar lo demás; un modelo que ya está no se repite.
	func testAddToExisting() throws {
		let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../..").standardized
		let old = try String(contentsOf: repo.appendingPathComponent("captures/exp014/Cherrypicker.middev"))
		let new = InstallInDP.middev(adding: "Cherrypicker", model: "CP Nuevo", to: old)
		XCTAssertEqual(middevEntries(new).map(\.model), ["CP Canales", "CP Patches", "CP Zap", "CP Nuevo"])
		let end = old.range(of: "</MIDIDeviceTypes>")!.lowerBound
		XCTAssertTrue(new.hasPrefix(String(old[..<end])), "lo anterior queda igual")
		XCTAssertEqual(InstallInDP.middev(adding: "Cherrypicker", model: "CP Zap", to: old), old)
		XCTAssertNoThrow(try XMLReader.parse(new))
	}
}

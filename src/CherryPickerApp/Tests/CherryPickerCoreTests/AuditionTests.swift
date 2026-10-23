import Foundation
import XCTest
import MidnamKit
@testable import CherryPickerCore

/// Audición (T-021, D-002): solo CC0, CC32 y Program Change.
final class AuditionTests: XCTestCase {
	func testMessages() throws {
		XCTAssertEqual(try auditionMessages(bankSelect0: "1", bankSelect32: "5", program: "7", channel: 1),
		               [[0xB0, 0, 1], [0xB0, 32, 5], [0xC0, 7]])
		XCTAssertEqual(try auditionMessages(bankSelect0: "-", bankSelect32: "127", program: "0", channel: 16),
		               [[0xBF, 32, 127], [0xCF, 0]])
		XCTAssertEqual(try auditionMessages(bankSelect0: "-", bankSelect32: "-", program: "3", channel: 10), [[0xC9, 3]])
		XCTAssertEqual(try auditionMessages(bankSelect0: "2", bankSelect32: "0", program: "-", channel: 1), [],
		               "sin Program Change no se envía nada")
	}

	func testInvalid() {
		XCTAssertThrowsError(try auditionMessages(bankSelect0: "-", bankSelect32: "-", program: "1", channel: 0))
		XCTAssertThrowsError(try auditionMessages(bankSelect0: "-", bankSelect32: "-", program: "1", channel: 17))
		XCTAssertThrowsError(try auditionMessages(bankSelect0: "128", bankSelect32: "-", program: "1", channel: 1))
		XCTAssertThrowsError(try auditionMessages(bankSelect0: "-", bankSelect32: "-", program: "x", channel: 1))
	}

	/// Regla 4: todo lo que se construye está permitido; SysEx y otros mensajes, no.
	func testOnlyAllowedMessages() throws {
		for bs0 in ["-", "0", "127"] {
			for bs32 in ["-", "0", "64"] {
				for ch in [1, 9, 16] {
					for m in try auditionMessages(bankSelect0: bs0, bankSelect32: bs32, program: "5", channel: ch) {
						XCTAssertTrue(isAllowedAuditionMessage(m), "\(m)")
					}
				}
			}
		}
		for bad: [UInt8] in [[0xF0, 0x7E, 0xF7], [0xB0, 7, 100], [0x90, 60, 100], [0xC0], [0xC0, 0x80], [0xB0, 0, 1, 2], []] {
			XCTAssertFalse(isAllowedAuditionMessage(bad), "\(bad)")
		}
	}

	func testDefaultChannel() throws {
		let file = try MidnamFile(text: BankEditingTests.midnam)
		let rows = BankRows.rows(file.document)
		let ch = rows.map { "\($0.name) \(file.document.defaultAuditionChannel($0.ref).map(String.init) ?? "nil")" }
		XCTAssertEqual(ch, ["Uno 1", "Custom 1", "Tres 1", "Kits 10"])
		XCTAssertEqual(file.document.channelSetName(rows[3].ref), "Drums")
	}
}

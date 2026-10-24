// Audición (D-002, P5; docs/20 §4 flujo 5; T-021): al seleccionar un patch se envían CC0/CC32 (si no son «-») y el
// Program Change por el «Audition Ch» del Channel Set del banco y, si se activa para el dispositivo, una nota de
// prueba (Note On y su Note Off; D-008, para módulos de sonido). Nada más: nunca SysEx ni otros mensajes que cambien
// la memoria del módulo (regla 4). Aquí solo se construyen los bytes; el envío (CoreMIDI) es de la app.
import Foundation
import MidnamKit

public enum AuditionError: LocalizedError, Equatable {
	case invalidChannel(Int)
	case invalidValue(String)

	public var errorDescription: String? {
		switch self {
		case .invalidChannel(let c): return "\(c) is not a valid MIDI channel. Use a number from 1 to 16."
		case .invalidValue(let v): return "“\(v)” is not a valid MIDI value (0 to 127)."
		}
	}
}

/// Mensajes de audición de un patch: Bank Select MSB (CC0), LSB (CC32) y Program Change, en ese orden. «-» = no se
/// envía. Sin Program Change («-») no se envía nada: solo cambiaría de banco.
public func auditionMessages(bankSelect0: String, bankSelect32: String, program: String, channel: Int) throws -> [[UInt8]] {
	guard (1...16).contains(channel) else { throw AuditionError.invalidChannel(channel) }
	func value(_ s: String) throws -> UInt8? {
		let t = s.trimmingCharacters(in: .whitespaces)
		if t == "-" || t.isEmpty { return nil }
		guard let n = Int(t), (0...127).contains(n) else { throw AuditionError.invalidValue(s) }
		return UInt8(n)
	}
	guard let pc = try value(program) else { return [] }
	let ch = UInt8(channel - 1)
	var out: [[UInt8]] = []
	if let v = try value(bankSelect0) { out.append([0xB0 | ch, 0, v]) }
	if let v = try value(bankSelect32) { out.append([0xB0 | ch, 32, v]) }
	out.append([0xC0 | ch, pc])
	return out
}

/// Nota de prueba (D-008): desactivada por defecto; se ajusta por dispositivo en la pestaña MIDI.
public struct TestNote: Equatable, Sendable {
	public var note: Int
	public var velocity: Int
	/// Duración en milisegundos (entre el Note On y el Note Off).
	public var length: Int

	public static let `default` = TestNote(note: 60, velocity: 100, length: 500)
	public static let lengths = 50...5000

	public init(note: Int, velocity: Int, length: Int) {
		self.note = note
		self.velocity = velocity
		self.length = length
	}

	/// Note On y Note Off (Note On con velocidad 0 no: algunos módulos lo tratan distinto) por el canal 1–16.
	public func messages(channel: Int) throws -> (on: [UInt8], off: [UInt8]) {
		guard (1...16).contains(channel) else { throw AuditionError.invalidChannel(channel) }
		guard (0...127).contains(note) else { throw AuditionError.invalidValue(String(note)) }
		guard (1...127).contains(velocity) else { throw AuditionError.invalidValue(String(velocity)) }
		let ch = UInt8(channel - 1)
		return ([0x90 | ch, UInt8(note), UInt8(velocity)], [0x80 | ch, UInt8(note), 64])
	}

	/// Nombre de la nota con el do central (60) como C3, como DP.
	public static func name(_ note: Int) -> String {
		let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
		return names[((note % 12) + 12) % 12] + String(note / 12 - 2)
	}
}

/// ¿Es un mensaje que la audición puede enviar? (Control Change 0 o 32, Program Change, o Note On / Note Off de la
/// nota de prueba; regla 4 y D-008.)
public func isAllowedAuditionMessage(_ m: [UInt8]) -> Bool {
	guard let status = m.first, status & 0x80 != 0, m.dropFirst().allSatisfy({ $0 < 0x80 }) else { return false }
	switch status & 0xF0 {
	case 0xB0: return m.count == 3 && (m[1] == 0 || m[1] == 32)
	case 0xC0: return m.count == 2
	case 0x80, 0x90: return m.count == 3
	default: return false
	}
}

public extension MIDINameDocument {
	/// Canal de audición por defecto del banco: el más bajo de su Channel Set en el primer modo que lo usa (manual
	/// del original). nil si ningún modo lo asigna.
	func defaultAuditionChannel(_ ref: BankRef) -> Int? {
		guard let m = masterAt(ref.master), let s = m.setAt(ref.set) else { return nil }
		for case .customDeviceMode(let d) in m.items {
			if let c = d.assignedChannels.filter({ $0.value == s.name }).keys.min() { return c }
		}
		return nil
	}

	/// Nombre del Channel Set del banco.
	func channelSetName(_ ref: BankRef) -> String? { masterAt(ref.master)?.setAt(ref.set)?.name }
}

// Salida MIDI para la audición (CoreMIDI; D-002, T-021). Un cliente para toda la app, creado la primera vez que se
// usa; solo envía lo que `isAllowedAuditionMessage` permite (CC0, CC32, Program Change y la nota de prueba; regla 4,
// D-008).
// Ajustes por documento: «Enable MIDI» desactivado al abrir (P5); el destino («Device Out») y los «Audition Ch»
// cambiados se recuerdan por fabricante y modelo (manual: «Your settings for each synth are saved»).
import CoreMIDI
import CherryPickerCore
import Foundation

final class MIDIOut {
	static let shared = MIDIOut()
	/// Cambió la lista de destinos (se conectó o desconectó algo).
	static let destinationsDidChange = Notification.Name("MIDIOutDestinationsDidChange")

	private var client = MIDIClientRef()
	private var port = MIDIPortRef()
	private(set) var error: OSStatus = noErr

	private init() {
		error = MIDIClientCreateWithBlock("CherryPicker" as CFString, &client) { _ in
			DispatchQueue.main.async { NotificationCenter.default.post(name: MIDIOut.destinationsDidChange, object: nil) }
		}
		if error == noErr { error = MIDIOutputPortCreate(client, "Audition" as CFString, &port) }
	}

	struct Destination: Equatable {
		var id: MIDIUniqueID
		var name: String
	}

	var destinations: [Destination] {
		(0..<MIDIGetNumberOfDestinations()).compactMap { i in
			let e = MIDIGetDestination(i)
			guard e != 0 else { return nil }
			var id: MIDIUniqueID = 0
			MIDIObjectGetIntegerProperty(e, kMIDIPropertyUniqueID, &id)
			var name: Unmanaged<CFString>?
			MIDIObjectGetStringProperty(e, kMIDIPropertyDisplayName, &name)
			return Destination(id: id, name: (name?.takeRetainedValue() as String?) ?? "MIDI \(i + 1)")
		}
	}

	private func endpoint(_ id: MIDIUniqueID) -> MIDIEndpointRef? {
		var obj = MIDIObjectRef()
		var type = MIDIObjectType.other
		guard MIDIObjectFindByUniqueID(id, &obj, &type) == noErr, type == .destination || type == .externalDestination
		else { return nil }
		return obj
	}

	/// Envía los mensajes en un solo paquete (MIDI 1.0 en UMP). Rechaza cualquier mensaje no permitido.
	func send(_ messages: [[UInt8]], to id: MIDIUniqueID) throws {
		guard error == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(error)) }
		guard messages.allSatisfy(isAllowedAuditionMessage) else { throw AuditionError.invalidValue("message") }
		guard !messages.isEmpty, let dest = endpoint(id) else { return }
		var list = MIDIEventList()
		var packet = MIDIEventListInit(&list, ._1_0)
		for m in messages {
			// Mensaje de canal MIDI 1.0 de 32 bits: tipo 2, grupo 0, estado y datos.
			var word: UInt32 = 0x2000_0000 | UInt32(m[0]) << 16 | UInt32(m[1]) << 8 | (m.count > 2 ? UInt32(m[2]) : 0)
			packet = MIDIEventListAdd(&list, MemoryLayout<MIDIEventList>.size, packet, 0, 1, &word)
		}
		let status = MIDISendEventList(port, dest, &list)
		if status != noErr { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
	}
}

/// Ajustes de audición de un documento.
final class AuditionSettings {
	static let didChange = Notification.Name("AuditionSettingsDidChange")

	/// «Enable MIDI»: siempre desactivado al abrir (P5).
	var enabled = false { didSet { post() } }
	private let key: String

	init(manufacturer: String, model: String) {
		key = "\(manufacturer)|\(model)"
	}

	/// «Device Out»: destino elegido (se recuerda por fabricante y modelo).
	var destination: MIDIUniqueID? {
		get { (UserDefaults.standard.object(forKey: "deviceOut.\(key)") as? Int).map { MIDIUniqueID($0) } }
		set {
			UserDefaults.standard.set(newValue.map { Int($0) }, forKey: "deviceOut.\(key)")
			post()
		}
	}

	/// «Audition Ch» elegido para un Channel Set (nil: el canal más bajo del Channel Set).
	func auditionChannel(channelSet: String) -> Int? {
		UserDefaults.standard.object(forKey: "auditionCh.\(key)|\(channelSet)") as? Int
	}

	func setAuditionChannel(_ channel: Int?, channelSet: String) {
		UserDefaults.standard.set(channel, forKey: "auditionCh.\(key)|\(channelSet)")
		post()
	}

	/// «Test Note» (D-008): activada o no, por fabricante y modelo; desactivada si no se ha elegido.
	var testNoteEnabled: Bool {
		get { UserDefaults.standard.bool(forKey: "testNoteOn.\(key)") }
		set {
			UserDefaults.standard.set(newValue, forKey: "testNoteOn.\(key)")
			post()
		}
	}

	/// Nota, velocidad y duración de la nota de prueba (por fabricante y modelo).
	var testNote: TestNote {
		get {
			guard let a = UserDefaults.standard.array(forKey: "testNote.\(key)") as? [Int], a.count == 3 else { return .default }
			return TestNote(note: a[0], velocity: a[1], length: a[2])
		}
		set {
			UserDefaults.standard.set([newValue.note, newValue.velocity, newValue.length], forKey: "testNote.\(key)")
			post()
		}
	}

	private func post() { NotificationCenter.default.post(name: Self.didChange, object: self) }
}

// «Install in DP…» ([PROPUESTA P3], T-024): copia el documento a la carpeta donde DP busca los `.midnam`
// (`/Library/Audio/MIDI Devices/MOTU/<Fabricante>/`, EXP-002) y, si el modelo no está en ningún `.middev`, puede
// añadirlo a uno propio de la app para que salga en las listas de DP y de Configuración de Audio MIDI. El `.middev` no
// es imprescindible: con fabricante y modelo escritos a mano, exactos, DP usa el fichero igual (EXP-021).
// Nunca se modifican los `.middev` de MOTU, Digidesign o Apple: la app solo escribe en el suyo,
// «<Fabricante> (Midnamer).middev», que se puede borrar para deshacer. Los instalados antes del cambio de nombre
// (D-011) se llaman «<Fabricante> (CherryPicker).middev»: si existe, se sigue usando ese, para no repartir los modelos.
import Foundation
import MidnamKit

public enum InstallInDP {
	/// Carpeta de DP para los `.midnam` de un fabricante.
	public static func folder(manufacturer: String,
	                          root: URL = URL(fileURLWithPath: "/Library/Audio/MIDI Devices/MOTU")) -> URL {
		root.appendingPathComponent(safeFileName(manufacturer), isDirectory: true)
	}

	/// Nombre del `.middev` propio de la app para el fabricante.
	public static func middevName(manufacturer: String) -> String {
		"\(safeFileName(manufacturer)) (Midnamer).middev"
	}

	/// El `.middev` propio en `folder`: el del nombre anterior si ya existe y el nuevo no, si no el nuevo.
	public static func middevURL(manufacturer: String, in folder: URL,
	                             exists: (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }) -> URL {
		let current = folder.appendingPathComponent(middevName(manufacturer: manufacturer))
		let legacy = folder.appendingPathComponent("\(safeFileName(manufacturer)) (CherryPicker).middev")
		return !exists(current) && exists(legacy) ? legacy : current
	}

	/// Nombre del `.midnam`: es lo que DP muestra en *Master Names* (EXP-006).
	public static func midnamName(_ name: String) -> String {
		var base = name.trimmingCharacters(in: .whitespaces)
		if base.lowercased().hasSuffix(".midnam") { base = String(base.dropLast(7)) }
		return safeFileName(base.isEmpty ? "Untitled" : base) + ".midnam"
	}

	/// Sin «/» ni «:» (separadores de ruta) ni espacios al principio o al final.
	public static func safeFileName(_ s: String) -> String {
		s.trimmingCharacters(in: .whitespaces).map { $0 == "/" || $0 == ":" ? "-" : String($0) }.joined()
	}

	/// Texto del `.middev` con el modelo añadido (o nuevo si `existing` es nil). Si ya lo declara, se devuelve igual.
	/// Formato de los `.middev` de MOTU (MIDIDeviceTypes 0.3), como el de EXP-006.
	public static func middev(adding manufacturer: String, model: String, to existing: String?) -> String {
		if let existing, middevEntries(existing).contains(where: { $0.manufacturer == manufacturer && $0.model == model }) {
			return existing
		}
		let entry = """
			<MIDIDeviceType Manufacturer="\(escape(manufacturer))" Model="\(escape(model))" SupportsGeneralMIDI="false" SupportsMMC="false" IsSampler="false" IsDrumMachine="false" IsMixer="false" IsEffectUnit="false" >
				<DeviceID Min="1" Max="16" Default="1" Base="1" />
				<Receives MaxChannels="16" MTC="false" Clock="false" Notes="true" ProgramChanges="true" BankSelectMSB="true" BankSelectLSB="true" PanDisruptsStereo="false" />
				<Transmits MaxChannels="0" MTC="false" Clock="false" Notes="false" ProgramChanges="false" BankSelectMSB="false" BankSelectLSB="false" />
			</MIDIDeviceType>

		"""
		if let existing, let end = existing.range(of: "</MIDIDeviceTypes>", options: .backwards) {
			return existing.replacingCharacters(in: end.lowerBound..<end.lowerBound, with: entry)
		}
		return """
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE MIDIDeviceTypes PUBLIC "-//MIDI Manufacturers Association//DTD MIDIDeviceTypes 0.3//EN" "http://www.sonosphere.com/dtds/MIDIDeviceTypes.dtd">

		<MIDIDeviceTypes>
			<Author>Midnamer</Author>
		\(entry)</MIDIDeviceTypes>

		"""
	}

	private static func escape(_ s: String) -> String {
		s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
			.replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
	}
}

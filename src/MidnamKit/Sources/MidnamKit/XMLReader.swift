// Lector XML propio: XMLParser de Foundation no conserva el orden de los atributos ni el prólogo literal.
// Cubre lo que aparece en ficheros midnam/middev: declaración, DOCTYPE, comentarios, CDATA, elementos y entidades.

public struct XMLReadError: Error, Equatable, CustomStringConvertible {
	public var message: String
	public var offset: Int

	public var description: String { "\(message) (byte \(offset))" }
}

public enum XMLReader {
	public static func parse(_ text: String) throws -> XMLDocumentFile {
		var r = Reader(Array(text.utf8))
		return try r.document()
	}
}

private struct Reader {
	let b: [UInt8]
	var i = 0
	var rawApostrophe = false
	var rawQuoteInText = false

	init(_ bytes: [UInt8]) {
		b = bytes
		if b.starts(with: [0xEF, 0xBB, 0xBF]) { i = 3 }
	}

	func fail(_ m: String) -> XMLReadError { XMLReadError(message: m, offset: i) }

	func at(_ s: String) -> Bool {
		let u = Array(s.utf8)
		return i + u.count <= b.count && Array(b[i..<i + u.count]) == u
	}

	mutating func skip(past s: String) throws {
		let u = Array(s.utf8)
		while i + u.count <= b.count {
			if Array(b[i..<i + u.count]) == u { i += u.count; return }
			i += 1
		}
		throw fail("falta \(s)")
	}

	func string(_ from: Int, _ to: Int) -> String { String(decoding: b[from..<to], as: UTF8.self) }

	mutating func document() throws -> XMLDocumentFile {
		let start = i
		// Prólogo: declaración, DOCTYPE (con posible subconjunto interno), comentarios y espacios
		while true {
			while i < b.count, isSpace(b[i]) { i += 1 }
			if at("<?") { try skip(past: "?>") }
			else if at("<!--") { try skip(past: "-->") }
			else if at("<!DOCTYPE") { try skipDoctype() }
			else if at("<") { break }
			else { throw fail("contenido antes del elemento raíz") }
		}
		let prolog = string(start, i)
		let root = try element()
		let epilogStart = i
		while i < b.count {
			if isSpace(b[i]) { i += 1 }
			else if at("<!--") { try skip(past: "-->") }
			else { throw fail("contenido después del elemento raíz") }
		}
		let style = XMLWriteStyle(escapeApostrophe: !rawApostrophe, escapeQuoteInText: !rawQuoteInText)
		return XMLDocumentFile(prolog: prolog, root: root, epilog: string(epilogStart, b.count), style: style)
	}

	mutating func skipDoctype() throws {
		var depth = 0
		var quote: UInt8? = nil
		while i < b.count {
			let c = b[i]
			i += 1
			if let q = quote { if c == q { quote = nil }; continue }
			switch c {
			case UInt8(ascii: "\""), UInt8(ascii: "'"): quote = c
			case UInt8(ascii: "["): depth += 1
			case UInt8(ascii: "]"): depth -= 1
			case UInt8(ascii: ">") where depth == 0: return
			default: break
			}
		}
		throw fail("DOCTYPE sin cerrar")
	}

	mutating func name() throws -> String {
		let s = i
		while i < b.count, !isSpace(b[i]), !"/>=".utf8.contains(b[i]) { i += 1 }
		if s == i { throw fail("nombre esperado") }
		return string(s, i)
	}

	mutating func element() throws -> XMLElement {
		guard i < b.count, b[i] == UInt8(ascii: "<") else { throw fail("< esperado") }
		i += 1
		var e = XMLElement(try name())
		// Atributos
		while true {
			while i < b.count, isSpace(b[i]) { i += 1 }
			guard i < b.count else { throw fail("etiqueta sin cerrar") }
			if at("/>") { i += 2; return e }
			if b[i] == UInt8(ascii: ">") { i += 1; break }
			let n = try name()
			while i < b.count, isSpace(b[i]) { i += 1 }
			guard i < b.count, b[i] == UInt8(ascii: "=") else { throw fail("= esperado en \(n)") }
			i += 1
			while i < b.count, isSpace(b[i]) { i += 1 }
			guard i < b.count, b[i] == UInt8(ascii: "\"") || b[i] == UInt8(ascii: "'") else { throw fail("valor esperado en \(n)") }
			let q = b[i]
			i += 1
			let s = i
			while i < b.count, b[i] != q { i += 1 }
			guard i < b.count else { throw fail("atributo \(n) sin cerrar") }
			if b[s..<i].contains(UInt8(ascii: "'")) { rawApostrophe = true }
			e.attributes.append(XMLAttribute(n, try decode(s, i)))
			i += 1
		}
		// Contenido
		while true {
			guard i < b.count else { throw fail("falta </\(e.name)>") }
			if at("</") {
				i += 2
				let n = try name()
				guard n == e.name else { throw fail("se esperaba </\(e.name)> y llega </\(n)>") }
				while i < b.count, isSpace(b[i]) { i += 1 }
				guard i < b.count, b[i] == UInt8(ascii: ">") else { throw fail("> esperado") }
				i += 1
				return e
			} else if at("<!--") {
				let s = i + 4
				try skip(past: "-->")
				e.children.append(.comment(string(s, i - 3)))
			} else if at("<![CDATA[") {
				let s = i + 9
				try skip(past: "]]>")
				e.children.append(.text(string(s, i - 3)))
			} else if at("<?") {
				throw fail("instrucción de proceso dentro del documento: no soportada")
			} else if b[i] == UInt8(ascii: "<") {
				e.children.append(.element(try element()))
			} else {
				let s = i
				while i < b.count, b[i] != UInt8(ascii: "<") { i += 1 }
				if b[s..<i].allSatisfy(isSpace) { continue }
				if b[s..<i].contains(UInt8(ascii: "'")) { rawApostrophe = true }
				if b[s..<i].contains(UInt8(ascii: "\"")) { rawQuoteInText = true }
				e.children.append(.text(try decode(s, i)))
			}
		}
	}

	func decode(_ from: Int, _ to: Int) throws -> String {
		guard b[from..<to].contains(UInt8(ascii: "&")) else { return string(from, to) }
		var out = [UInt8]()
		var k = from
		while k < to {
			if b[k] != UInt8(ascii: "&") { out.append(b[k]); k += 1; continue }
			guard let semi = b[k..<to].firstIndex(of: UInt8(ascii: ";")) else {
				throw XMLReadError(message: "entidad sin ;", offset: k)
			}
			let ent = string(k + 1, semi)
			switch ent {
			case "amp": out.append(UInt8(ascii: "&"))
			case "lt": out.append(UInt8(ascii: "<"))
			case "gt": out.append(UInt8(ascii: ">"))
			case "apos": out.append(UInt8(ascii: "'"))
			case "quot": out.append(UInt8(ascii: "\""))
			default:
				let hex = ent.hasPrefix("#x") || ent.hasPrefix("#X")
				guard ent.hasPrefix("#"),
				      let v = UInt32(ent.dropFirst(hex ? 2 : 1), radix: hex ? 16 : 10),
				      let sc = Unicode.Scalar(v) else {
					throw XMLReadError(message: "entidad desconocida &\(ent);", offset: k)
				}
				out.append(contentsOf: Array(String(Character(sc)).utf8))
			}
			k = semi + 1
		}
		return String(decoding: out, as: UTF8.self)
	}
}

private func isSpace(_ c: UInt8) -> Bool {
	c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D
}

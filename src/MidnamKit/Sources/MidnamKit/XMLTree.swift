// Árbol XML mínimo con el orden de atributos e hijos conservado.
// Los nodos de texto que solo contienen espacios entre elementos no se guardan: el escritor regenera la sangría.

public struct XMLAttribute: Equatable, Sendable {
	public var name: String
	public var value: String

	public init(_ name: String, _ value: String) {
		self.name = name
		self.value = value
	}
}

public enum XMLNode: Equatable, Sendable {
	case element(XMLElement)
	case text(String)
	case comment(String)
}

public struct XMLElement: Equatable, Sendable {
	public var name: String
	public var attributes: [XMLAttribute]
	public var children: [XMLNode]

	public init(_ name: String, attributes: [XMLAttribute] = [], children: [XMLNode] = []) {
		self.name = name
		self.attributes = attributes
		self.children = children
	}

	public subscript(attribute name: String) -> String? {
		attributes.first { $0.name == name }?.value
	}

	/// Hijos que son elementos, en orden.
	public var elements: [XMLElement] {
		children.compactMap { if case .element(let e) = $0 { return e } else { return nil } }
	}

	/// Texto directo del elemento (concatenado), sin los hijos elemento.
	public var text: String {
		children.map { if case .text(let t) = $0 { return t } else { return "" } }.joined()
	}
}

/// Cómo se escribió el fichero de origen, para poder reescribirlo idéntico.
public struct XMLWriteStyle: Equatable, Sendable {
	/// CherryPicker escribe `'` como `&apos;`; los ficheros de MOTU lo dejan tal cual.
	public var escapeApostrophe: Bool
	/// `"` en el texto de un elemento (en atributos siempre se escapa).
	public var escapeQuoteInText: Bool

	public static let cherryPicker = XMLWriteStyle(escapeApostrophe: true, escapeQuoteInText: true)

	public init(escapeApostrophe: Bool, escapeQuoteInText: Bool) {
		self.escapeApostrophe = escapeApostrophe
		self.escapeQuoteInText = escapeQuoteInText
	}
}

/// Documento XML: lo que va antes y después del elemento raíz se conserva literal.
public struct XMLDocumentFile: Equatable, Sendable {
	public var prolog: String
	public var root: XMLElement
	public var epilog: String
	public var style: XMLWriteStyle

	public init(prolog: String, root: XMLElement, epilog: String = "\n", style: XMLWriteStyle = .cherryPicker) {
		self.prolog = prolog
		self.root = root
		self.epilog = epilog
		self.style = style
	}
}

// Modelo tipado de MIDINameDocument sobre XMLElement, sin pérdidas.
// Regla: un elemento se convierte en tipo solo si su forma coincide del todo (atributos conocidos, hijos elemento);
// si no, se guarda tal cual en `.other` en su posición. Los atributos no previstos van en `extraAttributes`.
// Los valores numéricos se guardan como texto: `Patch Number` es una etiqueta («  1», «065»), no un número (EXP-001).

public struct MIDINameDocument: Equatable, Sendable {
	public enum Item: Equatable, Sendable {
		case author(String)
		case masterDeviceNames(MasterDeviceNames)
		case other(XMLElement)
	}

	public var items: [Item]
	public var extraAttributes: [XMLAttribute] = []

	public init(items: [Item]) { self.items = items }

	public init(element e: XMLElement) throws {
		guard e.name == "MIDINameDocument" else {
			throw XMLReadError(message: "la raíz es <\(e.name)>, no <MIDINameDocument>", offset: 0)
		}
		extraAttributes = e.attributes
		items = e.children.map { node in
			guard case .element(let c) = node else { return .other(XMLElement("#nodo", children: [node])) }
			if let t = textValue(c, "Author") { return .author(t) }
			if let m = MasterDeviceNames(element: c) { return .masterDeviceNames(m) }
			return .other(c)
		}
	}

	public var element: XMLElement {
		XMLElement("MIDINameDocument", attributes: extraAttributes, children: items.map {
			switch $0 {
			case .author(let t): return .element(textElement("Author", t))
			case .masterDeviceNames(let m): return .element(m.element)
			case .other(let o): return unwrap(o)
			}
		})
	}

	public var author: String? {
		for case .author(let t) in items { return t }
		return nil
	}

	public var masterDeviceNames: [MasterDeviceNames] {
		items.compactMap { if case .masterDeviceNames(let m) = $0 { return m } else { return nil } }
	}
}

public struct MasterDeviceNames: Equatable, Sendable {
	public enum Item: Equatable, Sendable {
		case manufacturer(String)
		case model(String)
		case customDeviceMode(CustomDeviceMode)
		case channelNameSet(ChannelNameSet)
		case patchNameList(PatchNameList)
		case controlNameList(ControlNameList)
		case other(XMLElement)
	}

	public var items: [Item]
	public var extraAttributes: [XMLAttribute] = []

	public init(items: [Item]) { self.items = items }

	init?(element e: XMLElement) {
		guard e.name == "MasterDeviceNames", let kids = onlyElements(e) else { return nil }
		extraAttributes = e.attributes
		items = kids.map { c in
			if let t = textValue(c, "Manufacturer") { return .manufacturer(t) }
			if let t = textValue(c, "Model") { return .model(t) }
			if let x = CustomDeviceMode(element: c) { return .customDeviceMode(x) }
			if let x = ChannelNameSet(element: c) { return .channelNameSet(x) }
			if let x = PatchNameList(element: c), x.name != nil { return .patchNameList(x) }
			if let x = ControlNameList(element: c) { return .controlNameList(x) }
			return .other(c)
		}
	}

	public var element: XMLElement {
		XMLElement("MasterDeviceNames", attributes: extraAttributes, children: items.map {
			switch $0 {
			case .manufacturer(let t): return .element(textElement("Manufacturer", t))
			case .model(let t): return .element(textElement("Model", t))
			case .customDeviceMode(let x): return .element(x.element)
			case .channelNameSet(let x): return .element(x.element)
			case .patchNameList(let x): return .element(x.element)
			case .controlNameList(let x): return .element(x.element)
			case .other(let o): return .element(o)
			}
		})
	}

	public var manufacturer: String? {
		for case .manufacturer(let t) in items { return t }
		return nil
	}

	public var models: [String] {
		items.compactMap { if case .model(let t) = $0 { return t } else { return nil } }
	}

	public var customDeviceModes: [CustomDeviceMode] {
		items.compactMap { if case .customDeviceMode(let x) = $0 { return x } else { return nil } }
	}

	public var channelNameSets: [ChannelNameSet] {
		items.compactMap { if case .channelNameSet(let x) = $0 { return x } else { return nil } }
	}

	public var patchNameLists: [PatchNameList] {
		items.compactMap { if case .patchNameList(let x) = $0 { return x } else { return nil } }
	}

	public var controlNameLists: [ControlNameList] {
		items.compactMap { if case .controlNameList(let x) = $0 { return x } else { return nil } }
	}
}

public struct CustomDeviceMode: Equatable, Sendable {
	public enum Item: Equatable, Sendable {
		case channelNameSetAssignments([ChannelNameSetAssign])
		case other(XMLElement)
	}

	public var name: String
	public var items: [Item]
	public var extraAttributes: [XMLAttribute] = []

	public init(name: String, items: [Item]) {
		self.name = name
		self.items = items
	}

	init?(element e: XMLElement) {
		guard e.name == "CustomDeviceMode", let kids = onlyElements(e),
		      let (v, extra) = split(e, ["Name"]), let n = v[0] else { return nil }
		name = n
		extraAttributes = extra
		items = kids.map { c in
			if c.name == "ChannelNameSetAssignments", c.attributes.isEmpty, let ks = onlyElements(c) {
				let list = ks.compactMap(ChannelNameSetAssign.init(element:))
				if list.count == ks.count { return .channelNameSetAssignments(list) }
			}
			return .other(c)
		}
	}

	public var element: XMLElement {
		XMLElement("CustomDeviceMode", attributes: attrs([("Name", name)], extraAttributes), children: items.map {
			switch $0 {
			case .channelNameSetAssignments(let l):
				return .element(XMLElement("ChannelNameSetAssignments", children: l.map { .element($0.element) }))
			case .other(let o): return .element(o)
			}
		})
	}
}

public struct ChannelNameSetAssign: Equatable, Sendable {
	public var channel: String
	public var nameSet: String
	public var extraAttributes: [XMLAttribute] = []

	public init(channel: String, nameSet: String) {
		self.channel = channel
		self.nameSet = nameSet
	}

	init?(element e: XMLElement) {
		guard e.name == "ChannelNameSetAssign", e.children.isEmpty,
		      let (v, extra) = split(e, ["Channel", "NameSet"]), let c = v[0], let n = v[1] else { return nil }
		channel = c
		nameSet = n
		extraAttributes = extra
	}

	public var element: XMLElement {
		XMLElement("ChannelNameSetAssign", attributes: attrs([("Channel", channel), ("NameSet", nameSet)], extraAttributes))
	}
}

public struct ChannelNameSet: Equatable, Sendable {
	public enum Item: Equatable, Sendable {
		case availableForChannels([AvailableChannel])
		case usesControlNameList(String)
		case usesNoteNameList(String)
		case patchBank(PatchBank)
		case other(XMLElement)
	}

	public var name: String
	public var items: [Item]
	public var extraAttributes: [XMLAttribute] = []

	public init(name: String, items: [Item]) {
		self.name = name
		self.items = items
	}

	init?(element e: XMLElement) {
		guard e.name == "ChannelNameSet", let kids = onlyElements(e),
		      let (v, extra) = split(e, ["Name"]), let n = v[0] else { return nil }
		name = n
		extraAttributes = extra
		items = kids.map { c in
			if c.name == "AvailableForChannels", c.attributes.isEmpty, let ks = onlyElements(c) {
				let list = ks.compactMap(AvailableChannel.init(element:))
				if list.count == ks.count { return .availableForChannels(list) }
			}
			if let n = usesName(c, "UsesControlNameList") { return .usesControlNameList(n) }
			if let n = usesName(c, "UsesNoteNameList") { return .usesNoteNameList(n) }
			if let b = PatchBank(element: c) { return .patchBank(b) }
			return .other(c)
		}
	}

	public var element: XMLElement {
		XMLElement("ChannelNameSet", attributes: attrs([("Name", name)], extraAttributes), children: items.map {
			switch $0 {
			case .availableForChannels(let l):
				return .element(XMLElement("AvailableForChannels", children: l.map { .element($0.element) }))
			case .usesControlNameList(let n): return .element(usesElement("UsesControlNameList", n))
			case .usesNoteNameList(let n): return .element(usesElement("UsesNoteNameList", n))
			case .patchBank(let b): return .element(b.element)
			case .other(let o): return .element(o)
			}
		})
	}

	public var patchBanks: [PatchBank] {
		items.compactMap { if case .patchBank(let b) = $0 { return b } else { return nil } }
	}
}

public struct AvailableChannel: Equatable, Sendable {
	public var channel: String
	public var available: String
	public var extraAttributes: [XMLAttribute] = []

	public init(channel: String, available: Bool) {
		self.channel = channel
		self.available = available ? "true" : "false"
	}

	init?(element e: XMLElement) {
		guard e.name == "AvailableChannel", e.children.isEmpty,
		      let (v, extra) = split(e, ["Channel", "Available"]), let c = v[0], let a = v[1] else { return nil }
		channel = c
		available = a
		extraAttributes = extra
	}

	public var element: XMLElement {
		XMLElement("AvailableChannel", attributes: attrs([("Channel", channel), ("Available", available)], extraAttributes))
	}
}

public struct PatchBank: Equatable, Sendable {
	public enum Item: Equatable, Sendable {
		/// Bank select del banco (CC0/CC32); puede faltar: banco solo de agrupación.
		case midiCommands([MIDICommand])
		case usesPatchNameList(String)
		case patchNameList(PatchNameList)
		case other(XMLElement)
	}

	public var name: String
	public var rom: String?
	public var items: [Item]
	public var extraAttributes: [XMLAttribute] = []

	public init(name: String, rom: String? = nil, items: [Item]) {
		self.name = name
		self.rom = rom
		self.items = items
	}

	init?(element e: XMLElement) {
		guard e.name == "PatchBank", let kids = onlyElements(e),
		      let (v, extra) = split(e, ["Name", "ROM"]), let n = v[0] else { return nil }
		name = n
		rom = v[1]
		extraAttributes = extra
		items = kids.map { c in
			if let l = midiCommands(c, "MIDICommands") { return .midiCommands(l) }
			if let n = usesName(c, "UsesPatchNameList") { return .usesPatchNameList(n) }
			if let l = PatchNameList(element: c), l.name == nil { return .patchNameList(l) }
			return .other(c)
		}
	}

	public var element: XMLElement {
		XMLElement("PatchBank", attributes: attrs([("Name", name), ("ROM", rom)], extraAttributes), children: items.map {
			switch $0 {
			case .midiCommands(let l): return .element(XMLElement("MIDICommands", children: l.map { .element($0.element) }))
			case .usesPatchNameList(let n): return .element(usesElement("UsesPatchNameList", n))
			case .patchNameList(let l): return .element(l.element)
			case .other(let o): return .element(o)
			}
		})
	}
}

public enum MIDICommand: Equatable, Sendable {
	case controlChange(control: String, value: String)
	case programChange(number: String)
	case other(XMLElement)

	init(element e: XMLElement) {
		if e.name == "ControlChange", e.children.isEmpty, let (v, extra) = split(e, ["Control", "Value"]),
		   extra.isEmpty, let c = v[0], let val = v[1] {
			self = .controlChange(control: c, value: val)
		} else if e.name == "ProgramChange", e.children.isEmpty, let (v, extra) = split(e, ["Number"]),
		          extra.isEmpty, let n = v[0] {
			self = .programChange(number: n)
		} else {
			self = .other(e)
		}
	}

	public var element: XMLElement {
		switch self {
		case .controlChange(let c, let v):
			return XMLElement("ControlChange", attributes: [XMLAttribute("Control", c), XMLAttribute("Value", v)])
		case .programChange(let n):
			return XMLElement("ProgramChange", attributes: [XMLAttribute("Number", n)])
		case .other(let o):
			return o
		}
	}
}

/// Con nombre bajo MasterDeviceNames; sin nombre dentro de un PatchBank.
public struct PatchNameList: Equatable, Sendable {
	public enum Item: Equatable, Sendable {
		case patch(Patch)
		case other(XMLElement)
	}

	public var name: String?
	public var items: [Item]
	public var extraAttributes: [XMLAttribute] = []

	public init(name: String?, items: [Item]) {
		self.name = name
		self.items = items
	}

	init?(element e: XMLElement) {
		guard e.name == "PatchNameList", let kids = onlyElements(e),
		      let (v, extra) = split(e, ["Name"]) else { return nil }
		name = v[0]
		extraAttributes = extra
		items = kids.map { c in Patch(element: c).map(Item.patch) ?? .other(c) }
	}

	public var element: XMLElement {
		XMLElement("PatchNameList", attributes: attrs([("Name", name)], extraAttributes), children: items.map {
			switch $0 {
			case .patch(let p): return .element(p.element)
			case .other(let o): return .element(o)
			}
		})
	}

	public var patches: [Patch] {
		items.compactMap { if case .patch(let p) = $0 { return p } else { return nil } }
	}
}

public struct Patch: Equatable, Sendable {
	public enum Item: Equatable, Sendable {
		/// Bank select y Program Change propios del preset (M3000, EXP-001).
		case patchMIDICommands([MIDICommand])
		case usesNoteNameList(String)
		case other(XMLElement)
	}

	/// Etiqueta que se ve en el menú, tal cual (puede llevar espacios o ceros a la izquierda).
	public var number: String
	public var name: String
	public var programChange: String?
	public var items: [Item]
	public var extraAttributes: [XMLAttribute] = []

	public init(number: String, name: String, programChange: String?, items: [Item] = []) {
		self.number = number
		self.name = name
		self.programChange = programChange
		self.items = items
	}

	init?(element e: XMLElement) {
		guard e.name == "Patch", let kids = onlyElements(e),
		      let (v, extra) = split(e, ["Number", "Name", "ProgramChange"]), let num = v[0], let n = v[1] else { return nil }
		number = num
		name = n
		programChange = v[2]
		extraAttributes = extra
		items = kids.map { c in
			if let l = midiCommands(c, "PatchMIDICommands") { return .patchMIDICommands(l) }
			if let n = usesName(c, "UsesNoteNameList") { return .usesNoteNameList(n) }
			return .other(c)
		}
	}

	public var element: XMLElement {
		XMLElement("Patch", attributes: attrs([("Number", number), ("Name", name), ("ProgramChange", programChange)], extraAttributes),
		           children: items.map {
			switch $0 {
			case .patchMIDICommands(let l): return .element(XMLElement("PatchMIDICommands", children: l.map { .element($0.element) }))
			case .usesNoteNameList(let n): return .element(usesElement("UsesNoteNameList", n))
			case .other(let o): return .element(o)
			}
		})
	}
}

public struct ControlNameList: Equatable, Sendable {
	public enum Item: Equatable, Sendable {
		case control(Control)
		case other(XMLElement)
	}

	public var name: String
	public var items: [Item]
	public var extraAttributes: [XMLAttribute] = []

	public init(name: String, items: [Item]) {
		self.name = name
		self.items = items
	}

	init?(element e: XMLElement) {
		guard e.name == "ControlNameList", let kids = onlyElements(e),
		      let (v, extra) = split(e, ["Name"]), let n = v[0] else { return nil }
		name = n
		extraAttributes = extra
		items = kids.map { c in Control(element: c).map(Item.control) ?? .other(c) }
	}

	public var element: XMLElement {
		XMLElement("ControlNameList", attributes: attrs([("Name", name)], extraAttributes), children: items.map {
			switch $0 {
			case .control(let c): return .element(c.element)
			case .other(let o): return .element(o)
			}
		})
	}
}

/// Control con nombre. Los hijos (valores con nombre, DTD 1.0) se conservan sin interpretar por ahora.
public struct Control: Equatable, Sendable {
	public var type: String
	public var number: String
	public var name: String
	public var children: [XMLNode] = []
	public var extraAttributes: [XMLAttribute] = []

	public init(type: String = "7bit", number: String, name: String) {
		self.type = type
		self.number = number
		self.name = name
	}

	init?(element e: XMLElement) {
		guard e.name == "Control", let (v, extra) = split(e, ["Type", "Number", "Name"]),
		      let t = v[0], let num = v[1], let n = v[2] else { return nil }
		type = t
		number = num
		name = n
		children = e.children
		extraAttributes = extra
	}

	public var element: XMLElement {
		XMLElement("Control", attributes: attrs([("Type", type), ("Number", number), ("Name", name)], extraAttributes),
		           children: children)
	}
}

// MARK: - Ayudas

/// Valores de los atributos conocidos (en el orden pedido) y el resto en su orden original.
/// nil si los conocidos no están en orden canónico: así la ida y vuelta conserva el orden del fichero.
private func split(_ e: XMLElement, _ known: [String]) -> ([String?], [XMLAttribute])? {
	let present = e.attributes.map(\.name).filter(known.contains)
	guard present == known.filter(present.contains),
	      e.attributes.prefix(present.count).map(\.name) == present else { return nil }
	return (known.map { e[attribute: $0] }, e.attributes.filter { !known.contains($0.name) })
}

private func attrs(_ known: [(String, String?)], _ extra: [XMLAttribute]) -> [XMLAttribute] {
	known.compactMap { k, v in v.map { XMLAttribute(k, $0) } } + extra
}

private func onlyElements(_ e: XMLElement) -> [XMLElement]? {
	let els = e.elements
	return els.count == e.children.count ? els : nil
}

private func textValue(_ e: XMLElement, _ name: String) -> String? {
	guard e.name == name, e.attributes.isEmpty, !e.children.isEmpty,
	      e.children.allSatisfy({ if case .text = $0 { return true } else { return false } }) else { return nil }
	return e.text
}

private func textElement(_ name: String, _ text: String) -> XMLElement {
	XMLElement(name, children: [.text(text)])
}

private func usesName(_ e: XMLElement, _ name: String) -> String? {
	guard e.name == name, e.children.isEmpty, e.attributes.count == 1, e.attributes[0].name == "Name" else { return nil }
	return e.attributes[0].value
}

private func usesElement(_ name: String, _ value: String) -> XMLElement {
	XMLElement(name, attributes: [XMLAttribute("Name", value)])
}

private func midiCommands(_ e: XMLElement, _ name: String) -> [MIDICommand]? {
	guard e.name == name, e.attributes.isEmpty, let ks = onlyElements(e) else { return nil }
	return ks.map(MIDICommand.init(element:))
}

/// Nodos sueltos (texto o comentario) directamente bajo la raíz se envuelven en un pseudo-elemento.
private func unwrap(_ o: XMLElement) -> XMLNode {
	if o.name == "#nodo", let n = o.children.first { return n }
	return .element(o)
}

// MARK: - Fichero

public struct MidnamFile: Equatable, Sendable {
	public var xml: XMLDocumentFile
	public var document: MIDINameDocument

	public init(text: String) throws {
		xml = try XMLReader.parse(text)
		document = try MIDINameDocument(element: xml.root)
	}

	/// Texto con el estilo del fichero de origen (o el de CherryPicker si es nuevo).
	public func text() -> String {
		var x = xml
		x.root = document.element
		return XMLWriter.write(x)
	}
}

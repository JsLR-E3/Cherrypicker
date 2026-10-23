// Hojas de la pestaña Device (nibs AddChSet y ReassignCS; textos de docs/20 §3.3; T-020).
import AppKit
import CherryPickerCore

/// «New Channel Set» (AddChSet): «Name», «Channels» (`1-9, 11-16`) y «Free:» con los canales libres del modo.
final class NewChannelSetSheet: SheetController {
	let name: NSTextField
	let channels: NSTextField
	var onCommit: ((_ name: String, _ channels: String) throws -> Void)?

	init(name initial: String, free: [Int]) {
		name = Self.field(initial, width: 200)
		channels = Self.field(formatChannels(free), width: 200)
		channels.placeholderString = "1-9, 11-16"
		channels.toolTip = "Channels for the new set, e.g. 1-9, 11-16"
		super.init(title: "New Channel Set", rows: [
			[Self.label("Name"), name],
			[Self.label("Channels"), channels],
			[Self.label("Free:"), Self.label(formatChannels(free))],
		], okTitle: "Add")
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	override func commit() throws { try onCommit?(name.stringValue, channels.stringValue) }
}

/// «Reassign Banks To» (ReassignCS): Channel Set al que pasan los bancos del que se borra.
final class ReassignBanksSheet: SheetController {
	let channelSet = NSPopUpButton()
	var onCommit: ((_ setIndex: Int) throws -> Void)?

	init(channelSets: [(index: Int, name: String)], preferred: Int?) {
		for s in channelSets {
			channelSet.addItem(withTitle: s.name)
			channelSet.lastItem?.tag = s.index
		}
		if let preferred { channelSet.selectItem(withTag: preferred) }
		super.init(title: "Reassign Banks To", rows: [[Self.label("Channel Set"), channelSet]], okTitle: "OK")
	}

	required init?(coder: NSCoder) { fatalError("no se usa con nib") }

	override func commit() throws { try onCommit?(channelSet.selectedTag()) }
}

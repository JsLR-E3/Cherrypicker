// Lista las ventanas en pantalla de un proceso: id, título y tamaño (para capturar solo esas con screencapture -l).
import CoreGraphics
import Foundation
let owner = CommandLine.arguments.dropFirst().first ?? "Midnamer"
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
for w in list where (w[kCGWindowOwnerName as String] as? String) == owner && (w[kCGWindowLayer as String] as? Int) == 0 {
	let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
	print(w[kCGWindowNumber as String] ?? 0, "\t", w[kCGWindowName as String] ?? "", "\t", b["Width"] ?? 0, "x", b["Height"] ?? 0)
}

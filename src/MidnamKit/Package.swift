// swift-tools-version:5.9
// MidnamKit: lectura y escritura sin pérdidas de ficheros .midnam (MIDINameDocument), T-007.
import PackageDescription

let package = Package(
	name: "MidnamKit",
	platforms: [.macOS(.v13)],
	products: [
		.library(name: "MidnamKit", targets: ["MidnamKit"]),
	],
	targets: [
		.target(name: "MidnamKit"),
		.executableTarget(name: "midnam-prueba", dependencies: ["MidnamKit"]),
		.testTarget(name: "MidnamKitTests", dependencies: ["MidnamKit"]),
	]
)

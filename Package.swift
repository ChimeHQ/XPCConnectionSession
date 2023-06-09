// swift-tools-version: 5.6

import PackageDescription

let package = Package(
	name: "XPCConnectionSession",
	platforms: [.macOS(.v11), .iOS(.v14)],
	products: [
		.library(name: "XPCConnectionSession", targets: ["XPCConnectionSession"]),
	],
	targets: [
		.target(
			name: "XPCConnectionSession"),
		.testTarget(
			name: "XPCConnectionSessionTests",
			dependencies: ["XPCConnectionSession"]),
	]
)

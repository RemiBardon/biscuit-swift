// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
	.define("CRYPTO_IN_SWIFTPM"),
	// To develop this on Apple platforms, uncomment this define.
	.define("CRYPTO_IN_SWIFTPM_FORCE_BUILD_API"),
]

let package = Package(
	name: "biscuit",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13),
	],
	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(name: "Biscuit", targets: ["Datalog", "BiscuitCrypto"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-collections", .upToNextMinor(from: "0.0.2")),
		.package(url: "https://github.com/apple/swift-crypto", .upToNextMinor(from: "1.1.6")),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages this package depends on.
		.target(
			name: "Datalog",
			dependencies: [
				.product(name: "OrderedCollections", package: "swift-collections"),
			]
		),
		.testTarget(name: "DatalogTests", dependencies: ["Datalog"]),
		.target(
			name: "BiscuitCrypto",
			dependencies: [
				.product(name: "Crypto", package: "swift-crypto"),
			]
		),
		.testTarget(name: "BiscuitCryptoTests", dependencies: ["BiscuitCrypto"]),
	]
)

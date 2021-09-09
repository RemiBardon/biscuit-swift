// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "biscuit",
	platforms: [
		.macOS(.v10_12),
		.iOS(.v10),
	],
	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(name: "Biscuit", targets: ["Datalog"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-collections", from: "0.0.2"),
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
	]
)

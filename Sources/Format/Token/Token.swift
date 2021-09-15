//
//  Token.swift
//  Token
//
//  Created by Rémi Bardon on 09/09/2021.
//

import Foundation
import Datalog
import BiscuitCrypto

/// maximum supported version of the serialization format
public let MAX_SCHEMA_VERSION: UInt32 = 2

/// Some symbols are predefined and available in every implementation,
/// to avoid transmitting them with every token.
public func defaultSymbolTable() -> SymbolTable {
	var syms = SymbolTable()
	syms.insert("authority")
	syms.insert("ambient")
	syms.insert("resource")
	syms.insert("operation")
	syms.insert("right")
	syms.insert("current_time")
	syms.insert("revocation_id")
	
	return syms
}

/// This structure represents a valid Biscuit token
///
/// It contains multiple `Block` elements, the associated symbol table,
/// and a serialized version of this data
///
/// ```rust
/// extern crate biscuit_auth as biscuit
///
/// use biscuit::{crypto::KeyPair, token::{Biscuit, builder::*}}
///
/// fn main() {
///   let root = KeyPair()
///
///   // first we define the authority block for global data,
///   // like access rights
///   // data from the authority block cannot be created in any other block
///   var builder = Biscuit::builder(&root)
///   builder.add_authority_fact(fact("right", &[string("/a/file1.txt"), s("read")]))
///
///   // facts and rules can also be parsed from a string
///   builder.add_authority_fact("right(\"/a/file1.txt\", \"read\")").expect("parse error")
///
///   let token1 = builder.build().unwrap()
///
///   // we can create a new block builder from that token
///   var builder2 = token1.create_block()
///   builder2.check_operation("read")
///
///   let keyPair2 = KeyPair()
///   let token2 = token1.append(&keyPair2, builder2).unwrap()
/// }
/// ```
public struct Biscuit {
	
	internal let rootKeyId: UInt32?
	internal let authority: Token_Block
	internal let blocks: [Token_Block]
	internal let symbols: SymbolTable
	/// Internal representation of the token
	public let container: SerializedBiscuit?
	
	private init(
		rootKeyId: UInt32?,
		authority: Token_Block,
		blocks: [Token_Block],
		symbols: SymbolTable,
		container: SerializedBiscuit?
	) {
		self.rootKeyId = rootKeyId
		self.authority = authority
		self.blocks = blocks
		self.symbols = symbols
		self.container = container
	}
	
	/// Creates a new token.
	///
	/// The public part of the root KeyPair must be used for verification.
	///
	/// The block is an authority block: its index must be 0 and all of its facts must have the authority tag.
	public init(
		rootKeyId: UInt32?,
		root: KeyPair,
		symbolTable: SymbolTable,
		authority: Token_Block
	) throws {
		#warning("Could not use rng seeds")
		let h1 = Set(symbolTable.symbols)
		let h2 = Set(authority.symbols.symbols)
		
		if !h1.isDisjoint(with: h2) {
			throw TokenError.symbolTableOverlap
		}
		
		var symbolTable = symbolTable
		symbolTable.symbols.append(contentsOf: authority.symbols.symbols)
		
		let container = try SerializedBiscuit(
			rootKeyId: rootKeyId,
			rootKeyPair: root,
			nextKeyPair: KeyPair(),
			authority: authority
		)
		
		self.init(
			rootKeyId: rootKeyId,
			authority: authority,
			blocks: [],
			symbols: symbolTable,
			container: container
		)
	}
	
	/// Deserializes a token and validates the signature using the root public key,
	/// with an optional custom symbol table
	public static func from(
		data: Data,
		rootKeyIdHandler: (UInt32?) -> PublicKey,
		symbolTable: SymbolTable = defaultSymbolTable()
	) throws -> Self {
		let container = try SerializedBiscuit.fromData(data, rootKeyIdHandler: rootKeyIdHandler)
		
		func deserialize(_ data: Data, or errorDescription: StaticString) throws -> Token_Block {
			do {
				return try Proto_Block(serializedData: data).tokenBlock()
			} catch let formatError as FormatError {
				throw TokenError.format(formatError)
			} catch {
				throw FormatError.blockDeserializationError("\(errorDescription): \(error)")
			}
		}
		
		let authority = try deserialize(container.authority.data, or: "Error deserializing authority block")
		
		var blocks = [Token_Block]()
		for block in container.blocks {
			blocks.append(try deserialize(block.data, or: "Error deserializing block"))
		}
		
		var symbolTable = symbolTable
		symbolTable
			.symbols
			.append(contentsOf: authority.symbols.symbols)
		
		for block in blocks {
			symbolTable
				.symbols
				.append(contentsOf: block.symbols.symbols)
		}
		
		let rootKeyId = container.rootKeyId
		
		return Self(
			rootKeyId: rootKeyId,
			authority: authority,
			blocks: blocks,
			symbols: symbolTable,
			container: container
		)
	}
	
	/// Deserializes a token and validates the signature using the root public key,
	/// with an optional custom symbol table
	public static func fromBase64(
		_ data: Data,
		rootKeyIdHandler: (UInt32?) -> PublicKey,
		symbols: SymbolTable = defaultSymbolTable()
	) throws -> Self {
		guard let decoded = Data(base64Encoded: data) else {
			throw TokenError.format(.blockDeserializationError("Could not decode Base64 data"))
		}
		
		return try Biscuit.from(data: decoded, rootKeyIdHandler: rootKeyIdHandler, symbolTable: symbols)
	}
	
	/// Serializes the token
	public func serializedData() throws -> Data {
		guard let container = self.container else {
			throw TokenError.internalError
		}
		
		return try container.proto.serializedData()
	}
	
	/// Serializes the token
	public func serializedSize() throws -> Int {
		return try self.serializedData().count
	}
	
	/// Serializes a sealed version of the token
	public func seal() throws -> Data {
		guard let container = self.container else {
			throw TokenError.internalError
		}
		
		return try container.seal().proto.serializedData()
	}
	
	/// Creates a verifier from this token
	public func verify() -> Verifier {
		return Verifier(fromToken: self)
	}
	
	#warning("Use builder")
	/// Creates a new block builder
//	public static func createBlock() -> BlockBuilder {
//		return BlockBuilder()
//	}
	
	#warning("Use builder")
	/// Create the first block's builder
	///
	/// Call [`builder::BiscuitBuilder::build`] to create the token
//	public static func builder(root: KeyPair) -> BiscuitBuilder {
//		return Self.builderWithSymbols(root, defaultSymbolTable())
//	}
	
	#warning("Use builder")
	/// Create the first block's builder, sing a provided symbol table
//	public static func builderWithSymbols(root: KeyPair, symbols: SymbolTable) -> BiscuitBuilder {
//		return BiscuitBuilder(root, symbols)
//	}
	
	#warning("Use builder")
	/// Adds a new block to the token
	///
	/// Since the public key is integrated into the token, the keyPair can be
	/// discarded right after calling this function
//	public func append(
//		keyPair: KeyPair,
//		blockBuilder: BlockBuilder
//	) throws -> Self {
//		#warning("Could not use rng seeds")
//		guard let container = self.container else {
//			throw TokenError.sealed
//		}
//
//		let block = blockBuilder.build(self.symbols)
//
//		let h1 = Set(self.symbols.symbols)
//		let h2 = Set(block.symbols.symbols)
//
//		if !h1.isDisjoint(with: h2) {
//			throw TokenError.symbolTableOverlap
//		}
//
//		var blocks = self.blocks
//		var symbols = self.symbols
//
//		symbols.symbols.append(contentsOf: block.symbols.symbols)
//		blocks.append(block)
//
//		return Biscuit(
//			rootKeyId: self.rootKeyId,
//			authority: self.authority,
//			blocks: blocks,
//			symbols: symbols,
//			container: container
//		)
//	}
	
	/// Returns the list of context elements of each block
	///
	/// The context is a free form text field in which application specific data can be stored
	public var context: [String?] {
		return [self.authority.context] + self.blocks.map(\.context)
	}
	
	/// Returns a list of revocation identifiers for each block, in order
	///
	/// If a token is generated with the same keys and the same content,
	/// those identifiers will stay the same
	public var revocationIdentifiers: [Data] {
		if let token = self.container {
			return [token.authority.signature] + token.blocks.map(\.signature)
		} else {
			return []
		}
	}
	
	/// Pretty printer for this token
	public var prettyPrinted: String {
		let authority = prettyPrint(block: self.authority, symbolTable: self.symbols)
		let blocks = self.blocks.map { prettyPrint(block: $0, symbolTable: self.symbols) }
		
		return """
		Biscuit {{
			symbols: \(self.symbols.symbols),
			authority: \(authority),
			blocks: \(indented(prettyArray(blocks)))
		}}
		"""
	}
	
}

private func prettyArray(_ array: [String]) -> String {
	if array.isEmpty {
		return "[]"
	} else {
		return """
		[
			\(array.joined(separator: ",\n\t"))
		]
		"""
	}
}

private func indented(_ string: String) -> String {
	return string.replacingOccurrences(of: "\n", with: "\n\t")
}

private func prettyPrint(block: Token_Block, symbolTable: SymbolTable) -> String {
	let facts = prettyArray(block.facts.map(symbolTable.printFact))
	let rules = prettyArray(block.rules.map(symbolTable.printRule))
	let checks = prettyArray(block.checks.map(symbolTable.printCheck))
	
	return """
	Block {{
		symbols: \(block.symbols.symbols),
		version: \(block.version),
		context: \(block.context ?? "\"\""),
		facts: \(indented(facts)),
		rules: \(indented(rules)),
		checks: \(indented(checks))
	}}
	"""
}

/// A block contained in a token.
public struct Token_Block {
	
	/// List of symbols introduced by this block
	public private(set) var symbols: SymbolTable
	/// List of facts provided by this block
	public let facts: [Fact]
	/// List of rules provided by this block
	public let rules: [Rule]
	/// Checks that the token and ambient data must validate
	public let checks: [Check]
	/// Contextual information that can be looked up before the verification
	/// (as an example, a user id to query rights into a database)
	public let context: String?
	/// Format version used to generate this block
	public let version: UInt32
	
	internal init(
		symbolTable: SymbolTable,
		facts: [Fact],
		rules: [Rule],
		checks: [Check],
		context: String?,
		version: UInt32
	) {
		self.symbols = symbolTable
		self.facts = facts
		self.rules = rules
		self.checks = checks
		self.context = context
		self.version = version
	}
	
	/// Creates a new block.
	///
	/// Blocks should be created through the `BlockBuilder` interface instead, to avoid mistakes.
	public init(baseSymbols: SymbolTable) {
		self.init(
			symbolTable: baseSymbols,
			facts: [],
			rules: [],
			checks: [],
			context: nil,
			version: MAX_SCHEMA_VERSION
		)
	}
	
	public mutating func symbolAdd(s: String) -> ID {
		self.symbols.add(s)
	}
	
	public mutating func symbolInsert(s: String) -> SymbolIndex {
		self.symbols.insert(s)
	}
	
}

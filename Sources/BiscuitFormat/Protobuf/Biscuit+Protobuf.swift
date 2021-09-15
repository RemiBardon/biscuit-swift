//
//  Biscuit+Protobuf.swift
//  Biscuit
//
//  Created by Rémi Bardon on 15/09/2021.
//

import Foundation
import BiscuitShared
import BiscuitDatalog
import BiscuitCrypto

extension Biscuit {
	
	/// Deserializes a token and validates the signature using the root public key,
	/// with an optional custom symbol table
	public init(
		fromData data: Data,
		rootKeyIdHandler: (UInt32?) -> PublicKey,
		symbolTable: SymbolTable = .defaultTable
	) throws {
		let container = try SerializedBiscuit(fromData: data, rootKeyIdHandler: rootKeyIdHandler)
		
		func deserialize(_ data: Data, or errorDescription: StaticString) throws -> Token_Block {
			do {
				return try Proto_Block(serializedData: data).tokenBlock()
			} catch let formatError as FormatError {
				throw BiscuitError.format(formatError)
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
		symbolTable.add(contentsOf: authority.symbols.symbols)
		
		for block in blocks {
			symbolTable.add(contentsOf: block.symbols.symbols)
		}
		
		let rootKeyId = container.rootKeyId
		
		self.init(
			rootKeyId: rootKeyId,
			authority: authority,
			blocks: blocks,
			symbols: symbolTable,
			container: container
		)
	}
	
	/// Deserializes a token and validates the signature using the root public key,
	/// with an optional custom symbol table
	public init(
		fromBase64 data: Data,
		rootKeyIdHandler: (UInt32?) -> PublicKey,
		symbols: SymbolTable = .defaultTable
	) throws {
		guard let decoded = Data(base64Encoded: data) else {
			throw BiscuitError.format(.blockDeserializationError("Could not decode Base64 data"))
		}
		
		try self.init(fromData: decoded, rootKeyIdHandler: rootKeyIdHandler, symbolTable: symbols)
	}
	
	/// Serializes the token
	public func serializedData() throws -> Data {
		guard let container = self.container else {
			throw BiscuitError.internalError
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
			throw BiscuitError.internalError
		}
		
		return try container.seal().proto.serializedData()
	}
	
}

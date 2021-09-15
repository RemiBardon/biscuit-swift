//
//  SerializedBiscuit.swift
//  Biscuit
//
//  Created by Rémi Bardon on 09/09/2021.
//

import Foundation
import BiscuitCrypto

/// token serialization/deserialization
///
/// Biscuit tokens are serialized to Protobuf. There are two levels of serialization:
///
/// - serialization of Biscuit blocks to Protobuf then `Vec<u8>`
/// - serialization of a wrapper structure containing serialized blocks and the signature

public typealias CryptoBlock = BiscuitCrypto.Block

/// Intermediate structure for token serialization
///
/// This structure contains the blocks serialized to byte arrays. Those arrays
/// will be used for the signature
public struct SerializedBiscuit {
	
	public let rootKeyId: UInt32?
	public let authority: CryptoBlock
	public var blocks: [CryptoBlock]
	public let proof: NextToken
	
	private init(
		rootKeyId: UInt32?,
		authority: CryptoBlock,
		blocks: [CryptoBlock],
		proof: NextToken
	) {
		self.rootKeyId = rootKeyId
		self.authority = authority
		self.blocks = blocks
		self.proof = proof
	}
	
	public init(fromData data: Data, rootKeyIdHandler: (UInt32?) -> PublicKey) throws {
		let biscuit: Proto_Biscuit
		do {
			biscuit = try Proto_Biscuit(serializedData: data)
		} catch {
			throw FormatError.deserializationError("\(error)")
		}
		
		/// Verify signature size
		func verifySignatureSize(_ signature: Signature) throws {
			guard signature.count == 64 else {
				throw FormatError.invalidSignatureSize(signature.count)
			}
		}
		
		func verifiedSignature(_ signature: Signature) throws -> Signature {
			try verifySignatureSize(signature)
			return signature
		}
		
		let authority = CryptoBlock(
			data: biscuit.authority.block,
			nextKey: try PublicKey(rawRepresentation: biscuit.authority.nextKey),
			signature: try verifiedSignature(biscuit.authority.signature)
		)
		
		var blocks = [CryptoBlock]()
		for block in biscuit.blocks {
			blocks.append(CryptoBlock(
				data: block.block,
				nextKey: try PublicKey(rawRepresentation: block.nextKey),
				signature: try verifiedSignature(block.signature)
			))
		}
		
		let proof: NextToken = try {
			guard let content = biscuit.proof.content else {
				throw FormatError.deserializationError("Could not find proof")
			}
			switch content {
			case let .nextSecret(data):
				return .secret(try PrivateKey(rawRepresentation: data))
			case let .finalSignature(data):
				return .seal(try verifiedSignature(data))
			}
		}()
		
		self.init(
			rootKeyId: biscuit.rootKeyId,
			authority: authority,
			blocks: blocks,
			proof: proof
		)
		
		let root = rootKeyIdHandler(self.rootKeyId)
		try self.verify(with: root)
	}
	
	/// Serializes the token
	internal var proto: Proto_Biscuit {
		let authority = Proto_SignedBlock.with {
			$0.block = self.authority.data
			$0.nextKey = self.authority.nextKey.rawRepresentation
			$0.signature = self.authority.signature
		}
		
		var blocks = [Proto_SignedBlock]()
		for block in self.blocks {
			let b = Proto_SignedBlock.with {
				$0.block = block.data
				$0.nextKey = block.nextKey.rawRepresentation
				$0.signature = block.signature
			}
			
			blocks.append(b)
		}
		
		return Proto_Biscuit.with {
			$0.rootKeyId = self.rootKeyId
			$0.authority = authority
			$0.blocks = blocks
			$0.proof = Proto_Proof.with {
				switch self.proof {
				case let .seal(signature):
					$0.content = .finalSignature(signature)
				case let .secret(privateKey):
					$0.content = .nextSecret(privateKey.rawRepresentation)
				}
			}
		}
	}
	
	public func serializedSize() throws -> Int {
		return try self.proto.serializedData().count
	}
	
	/// Creates a new token
	public init(
		rootKeyId: UInt32?,
		rootKeyPair: KeyPair,
		nextKeyPair: KeyPair,
		authority: Token_Block
	) throws {
		let data: Data
		do {
			data = try authority.proto.serializedData()
		} catch {
			throw FormatError.serializationError(error)
		}
		
		let signature = try sign(data, with: rootKeyPair, nextKey: nextKeyPair)
		
		self.init(
			rootKeyId: rootKeyId,
			authority: CryptoBlock(data: data, nextKey: nextKeyPair.publicKey, signature: signature),
			blocks: [],
			proof: .secret(nextKeyPair.privateKey)
		)
	}
	
	/// Adds a new block, serializes it and sign a new token
	public func append(nextKeyPair: KeyPair, block: Token_Block) throws -> Self {
		let keyPair = try self.proof.keyPair()
		
		let data: Data
		do {
			data = try block.proto.serializedData()
		} catch {
			throw FormatError.serializationError(error)
		}
		
		let signature = try sign(data, with: keyPair, nextKey: nextKeyPair)
		
		// Add new block
		var blocks = self.blocks
		blocks.append(CryptoBlock(
			data: data,
			nextKey: nextKeyPair.publicKey,
			signature: signature
		))
		
		return Self(
			rootKeyId: self.rootKeyId,
			authority: self.authority,
			blocks: blocks,
			proof: .secret(nextKeyPair.privateKey)
		)
	}
	
	/// Checks the signature on a deserialized token
	public func verify(with root: PublicKey) throws {
		// FIXME: Try batched signature verification
		var currentPub = root
		
		try self.authority.verifySignature(with: currentPub)
		
		currentPub = self.authority.nextKey
		
		// Verify all blocks
		for block in self.blocks {
			try block.verifySignature(with: currentPub)
			currentPub = block.nextKey
		}
		
		switch self.proof {
		case let .secret(privateKey):
			if currentPub.rawRepresentation != privateKey.publicKey.rawRepresentation {
				throw CryptoError.signature(.invalidSignature("The last public key does not match the private"))
			}
		case let .seal(signature):
			// FIXME: Replace with SHA512 hashing
			var toVerify = Data()
			
			let block = self.blocks.last ?? self.authority
			toVerify.append(block.data)
			toVerify.append(block.nextKey.rawRepresentation)
			toVerify.append(block.signature)
			
			guard currentPub.isValidSignature(signature, for: toVerify) else {
				throw CryptoError.signature(.invalidSignature("Block signature is invalid"))
			}
		}
	}
	
	public func seal() throws -> Self {
		let keyPair = try self.proof.keyPair()
		
		var toSign = Data()
		let block = self.blocks.last ?? self.authority
		toSign.append(block.data)
		toSign.append(block.nextKey.rawRepresentation)
		toSign.append(block.signature)
		
		let signature = try sign(toSign, with: keyPair)
		
		return SerializedBiscuit(
			rootKeyId: self.rootKeyId,
			authority: self.authority,
			blocks: self.blocks,
			proof: .seal(signature)
		)
	}
	
}

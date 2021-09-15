//
//  BiscuitCrypto.swift
//  BiscuitCrypto
//
//  Created by Rémi Bardon on 09/09/2021.
//

import Foundation
import Crypto

/// cryptographic operations
///
/// Biscuit tokens are based on a chain of Ed25519 signatures.
/// This provides the fundamental operation for offline delegation: from a message
/// and a valid signature, it is possible to add a new message and produce a valid
/// signature for the whole.
///
/// The implementation is based on [ed25519_dalek](https://github.com/dalek-cryptography/ed25519-dalek).

public typealias PrivateKey = Curve25519.Signing.PrivateKey
public typealias PublicKey = Curve25519.Signing.PublicKey
public typealias Signature = Data

public struct KeyPair {
	
	public let privateKey: PrivateKey
	public var publicKey: PublicKey { privateKey.publicKey }
	
	public init() {
		self.privateKey = .init()
	}
	
	public init(from privateKey: PrivateKey) {
		self.privateKey = privateKey
	}
	
}

#warning("Could not implement `zeroize`")

//impl Drop for KeyPair {
//	fn drop(&mut self) {
//		self.kp.secret.zeroize()
//	}
//}

//impl Drop for PrivateKey {
//	fn drop(&mut self) {
//		self.0.zeroize()
//	}
//}

public struct Block {
	
	#warning("data is not a constant because one test needs to change it… we should avoid this")
	public var data: Data
	public let nextKey: PublicKey
	public let signature: Signature
	
	public init(data: Data, nextKey: PublicKey, signature: Signature) {
		self.data = data
		self.nextKey = nextKey
		self.signature = signature
	}
	
}

public struct Token {
	
	public let root: PublicKey
	#warning("setter is internal and not private because one test needs to change it… we should avoid this")
	public internal(set) var blocks: [Block]
	public let next: NextToken
	
	private init(root: PublicKey, blocks: [Block], next: NextToken) {
		self.root = root
		self.blocks = blocks
		self.next = next
	}
	
	public init(keyPair: KeyPair, nextKey: KeyPair, message: Data) throws {
		let signature = try sign(keyPair: keyPair, nextKey: nextKey, message: message)
		let block = Block(data: message, nextKey: nextKey.publicKey, signature: signature)
		
		self.init(root: keyPair.publicKey, blocks: [block], next: .secret(nextKey.privateKey))
	}
	
	public func append(nextKey: KeyPair, message: Data) throws -> Self {
		let keyPair = try self.next.keyPair()
		
		let signature = try sign(keyPair: keyPair, nextKey: nextKey, message: message)
		let block = Block(data: message, nextKey: nextKey.publicKey, signature: signature)
		
		var newToken = Token(root: self.root, blocks: self.blocks, next: .secret(nextKey.privateKey))
		newToken.blocks.append(block)
		
		return newToken
	}
	
	public func verify(with root: PublicKey) throws {
		// FIXME: Try batched signature verification
		var currentPub = root
		
		// Verify all blocks
		for block in self.blocks {
			try verifyBlockSignature(of: block, with: currentPub)
			
			currentPub = block.nextKey
		}
		
		switch self.next {
		case let .secret(privateKey):
			if currentPub.rawRepresentation != privateKey.publicKey.rawRepresentation {
				throw FormatError.signature(.invalidSignature("The last public key does not match the private key"))
			}
		case let .seal(signature):
			// FIXME: Replace with SHA512 hashing
			var toVerify = Data()
			for block in self.blocks {
				toVerify.append(block.data)
				toVerify.append(block.nextKey.rawRepresentation)
			}
			
			guard currentPub.isValidSignature(signature, for: toVerify) else {
				throw FormatError.signature(.invalidSignature("Block signature is invalid"))
			}
		}
	}
	
}

public enum NextToken {
	
	case secret(PrivateKey), seal(Signature)
	
	public func keyPair() throws -> KeyPair {
		switch self {
		case .seal:
			throw TokenError.sealed
		case let .secret(privateKey):
			return KeyPair(from: privateKey)
		}
	}
	
}

public func sign(keyPair: KeyPair, nextKey: KeyPair, message: Data) throws -> Signature {
	var toSign = message
	toSign.append(nextKey.publicKey.rawRepresentation)

	return try sign(keyPair: keyPair, message: toSign)
}

public func sign(keyPair: KeyPair, message: Data) throws -> Signature {
	// FIXME: replace with SHA512 hashing
	do {
		return try keyPair.privateKey.signature(for: message)
	} catch {
		throw FormatError.signature(.invalidSignatureGeneration(error))
	}
}

public func verifyBlockSignature(of block: Block, with publicKey: PublicKey) throws {
	// FIXME: Replace with SHA512 hashing
	var toVerify = block.data
	toVerify.append(block.nextKey.rawRepresentation)

	guard publicKey.isValidSignature(block.signature, for: toVerify) else {
		throw FormatError.signature(.invalidSignature("The block has not been signed with the correct key"))
	}
}

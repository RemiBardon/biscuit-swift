//
//  BiscuitCrypto.swift
//  Biscuit
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
	
	public init(from privateKey: PrivateKey = PrivateKey()) {
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
	
	public func verifySignature(with publicKey: PublicKey) throws {
		var toVerify = self.data
		toVerify.append(self.nextKey.rawRepresentation)
		
		// FIXME: Replace with SHA512 hashing
		guard publicKey.isValidSignature(self.signature, for: toVerify) else {
			throw CryptoError.signature(.invalidSignature("The block has not been signed with the correct key"))
		}
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
	
	public init(with message: Data, signedBy keyPair: KeyPair, nextKey: KeyPair) throws {
		let signature = try sign(message, with: keyPair, nextKey: nextKey)
		let block = Block(data: message, nextKey: nextKey.publicKey, signature: signature)
		
		self.init(root: keyPair.publicKey, blocks: [block], next: .secret(nextKey.privateKey))
	}
	
	public func append(_ message: Data, nextKey: KeyPair) throws -> Self {
		let signature = try sign(message, with: self.next.keyPair(), nextKey: nextKey)
		let block = Block(data: message, nextKey: nextKey.publicKey, signature: signature)
		
		var newToken = Token(root: self.root, blocks: self.blocks, next: .secret(nextKey.privateKey))
		newToken.blocks.append(block)
		
		return newToken
	}
	
	public func verify(with rootPublicKey: PublicKey) throws {
		// Verify all blocks
		let lastPublicKey: PublicKey = try {
			var currentPublicKey = rootPublicKey
			
			// FIXME: Try batched signature verification
			for block in self.blocks {
				try block.verifySignature(with: currentPublicKey)
				currentPublicKey = block.nextKey
			}
			
			return currentPublicKey
		}()
		
		switch self.next {
		case .secret(let privateKey):
			guard lastPublicKey.rawRepresentation == privateKey.publicKey.rawRepresentation else {
				throw CryptoError.signature(.invalidSignature("The last public key does not match the private key"))
			}
		case .seal(let signature):
			var toVerify = Data()
			for block in self.blocks {
				toVerify.append(block.data)
				toVerify.append(block.nextKey.rawRepresentation)
			}
			
			// FIXME: Replace with SHA512 hashing
			guard lastPublicKey.isValidSignature(signature, for: toVerify) else {
				throw CryptoError.signature(.invalidSignature("Block signature is invalid"))
			}
		}
	}
	
}

public enum NextToken {
	
	case secret(PrivateKey), seal(Signature)
	
	public func keyPair() throws -> KeyPair {
		switch self {
		case .seal:
			throw CryptoError.sealed
		case let .secret(privateKey):
			return KeyPair(from: privateKey)
		}
	}
	
}

public func sign(_ message: Data, with keyPair: KeyPair, nextKey: KeyPair) throws -> Signature {
	var toSign = message
	toSign.append(nextKey.publicKey.rawRepresentation)
	
	return try sign(toSign, with: keyPair)
}

public func sign(_ message: Data, with keyPair: KeyPair) throws -> Signature {
	// FIXME: replace with SHA512 hashing
	do {
		return try keyPair.privateKey.signature(for: message)
	} catch {
		throw CryptoError.signature(.invalidSignatureGeneration(error))
	}
}

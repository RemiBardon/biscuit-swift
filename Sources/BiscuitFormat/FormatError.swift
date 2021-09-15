//
//  FormatError.swift
//  Biscuit
//
//  Created by Rémi Bardon on 15/09/2021.
//

import Foundation
import BiscuitShared

extension BiscuitError {
	
	internal static func format(_ error: FormatError) -> Self {
		.error(prefix: "Error deserializing or verifying the token", error: error)
	}
	
}

/// Errors related to the token's serialization format or cryptographic signature
public enum FormatError: Error, CustomStringConvertible {
	
	case sealedSignature
	case emptyKeys
	case unknownPublicKey
	case deserializationError(String)
	case serializationError(Error)
	case blockDeserializationError(String)
	case blockSerializationError(Error)
	case version(maximum: UInt32, actual: UInt32)
	case invalidKeySize(Int)
	case invalidSignatureSize(Int)
	case invalidKey(String)
	
	public var description: String {
		switch self {
		case .sealedSignature:
			return "Failed verifying the signature of a sealed token"
		case .emptyKeys:
			return "The token does not provide intermediate public keys"
		case .unknownPublicKey:
			return "The root public key was not recognized"
		case let .deserializationError(error):
			return "Could not deserialize the wrapper object: \(error)"
		case let .serializationError(error):
			return "Could not serialize the wrapper object: \(error)"
		case let .blockDeserializationError(error):
			return "Could not deserialize the block: \(error)"
		case let .blockSerializationError(error):
			return "Could not serialize the block: \(error)"
		case let .version(maximum, actual):
			return "Block format version is higher than supported (\(actual)>\(maximum)"
		case let .invalidKeySize(size):
			return "Invalid key size: \(size)"
		case let .invalidSignatureSize(size):
			return "Invalid signature size: \(size)"
		case let .invalidKey(key):
			return "Invalid key: \(key)"
		}
	}
	
}

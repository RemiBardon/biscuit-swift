//
//  TokenError.swift
//  BiscuitCrypto
//
//  Created by Rémi Bardon on 09/09/2021.
//

import Foundation

/// The global error type for Biscuit
public enum TokenError: Error, CustomStringConvertible {
	
	case internalError
	case format(FormatError)
	case invalidAuthorityIndex(UInt32)
	case invalidBlockIndex(InvalidBlockIndex)
	case symbolTableOverlap
	case sealed
//	case failedLogic(LogicError)
	case parseError
//	case runLimit(RunLimitsError)
	case conversionError(Error)
//	case base64(base64::DecodeError)
	
	public var description: String {
		switch self {
		case .internalError:
			return "Internal error"
		case .format:
			return "Error deserializing or verifying the token"
		case .invalidAuthorityIndex:
			return "The authority block must have the index 0"
		case let .invalidBlockIndex(index):
			return "The block index does not match its position: expected \(index.expected), found \(index.found)"
		case .symbolTableOverlap:
			return "Multiple blocks declare the same symbols"
		case .sealed:
			return "Tried to append a block to a sealed token"
//		case .failedLogic:
//			return "Check validation failed"
		case .parseError:
			return "Datalog parsing error"
//		case .runLimit:
//			return "Reached Datalog execution limits"
		case let .conversionError(error):
			return "Cannot convert from Term: \(error)"
//		case .base64(let error):
//			return "Cannot decode base64 token: \(error)"
		}
	}
	
}

public struct InvalidBlockIndex {
	public let expected: UInt32
	public let found: UInt32
}

/// Errors related to the token's serialization format or cryptographic signature
public enum FormatError: Error, CustomStringConvertible {
	
	case signature(SignatureError)
	case sealedSignature
	case emptyKeys
	case unknownPublicKey
	case deserializationError(Error)
	case serializationError(Error)
	case blockDeserializationError(Error)
	case blockSerializationError(Error)
	case version(maximum: UInt32, actual: UInt32)
	case invalidKeySize(Int)
	case invalidSignatureSize(Int)
	case invalidKey(String)
	
	public var description: String {
		switch self {
		case let .signature(error):
			return "Failed verifying the signature: \(error)"
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

/// Signature errors
public enum SignatureError: Error, CustomStringConvertible {
	
	case invalidFormat
	case invalidSignature(String)
	case invalidSignatureGeneration(Error)
	
	public var description: String {
		switch self {
		case .invalidFormat:
			return "Could not parse the signature elements"
		case let .invalidSignature(error):
			return "The signature did not match: \(error)"
		case let .invalidSignatureGeneration(error):
			return "Could not sign: \(error)"
		}
	}
	
}

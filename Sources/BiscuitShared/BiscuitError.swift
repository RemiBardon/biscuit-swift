//
//  BiscuitError.swift
//  Biscuit
//
//  Created by Rémi Bardon on 09/09/2021.
//

import Foundation

/// The global error type for Biscuit
public enum BiscuitError: Error, CustomStringConvertible {
	
	case message(String)
	case error(prefix: StaticString, error: Error)
	case internalError
//	case invalidAuthorityIndex(UInt32)
//	case invalidBlockIndex(InvalidBlockIndex)
	case symbolTableOverlap
	case missingSymbols
//	case parseError
//	case conversionError(Error)
//	case base64(base64::DecodeError)
	
	public var description: String {
		switch self {
		case .message(let message):
			return message
		case let .error(prefix, error):
			return "\(prefix): \(error)"
		case .internalError:
			return "Internal error"
//		case .invalidAuthorityIndex:
//			return "The authority block must have the index 0"
//		case let .invalidBlockIndex(index):
//			return "The block index does not match its position: expected \(index.expected), found \(index.found)"
		case .symbolTableOverlap:
			return "Multiple blocks declare the same symbols"
		case .missingSymbols:
			return "The symbol table is missing either \"authority\" or \"ambient\""
//		case .parseError:
//			return "Datalog parsing error"
//		case let .conversionError(error):
//			return "Cannot convert from Term: \(error)"
//		case .base64(let error):
//			return "Cannot decode base64 token: \(error)"
		}
	}
	
}

//public struct InvalidBlockIndex {
//	public let expected: UInt32
//	public let found: UInt32
//}

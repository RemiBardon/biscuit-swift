//
//  CryptoError.swift
//  Biscuit
//
//  Created by Rémi Bardon on 15/09/2021.
//

import Foundation
import BiscuitShared

extension BiscuitError {
	
	internal static func crypto(_ error: CryptoError) -> Self {
		return Self.error(prefix: "Error in the token's cryptographic signature", error: error)
	}
	
}

/// Errors related to the token's cryptographic signature
public enum CryptoError: Error, CustomStringConvertible {
	
	case signature(SignatureError)
	case sealed
	
	public var description: String {
		switch self {
		case .signature(let error):
			return "Failed verifying the signature: \(error)"
		case .sealed:
			return "Tried to append a block to a sealed token"
		}
	}
	
}

/// Signature errors
public enum SignatureError: Error, CustomStringConvertible {
	
//	case invalidFormat
	case invalidSignature(String)
	case invalidSignatureGeneration(Error)
	
	public var description: String {
		switch self {
//		case .invalidFormat:
//			return "Could not parse the signature elements"
		case .invalidSignature(let error):
			return "The signature did not match: \(error)"
		case .invalidSignatureGeneration(let error):
			return "Could not sign: \(error)"
		}
	}
	
}

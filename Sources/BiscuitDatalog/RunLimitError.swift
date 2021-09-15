//
//  RunLimitError.swift
//  Biscuit
//
//  Created by Rémi Bardon on 15/09/2021.
//

import Foundation
import BiscuitShared

extension BiscuitError {
	
	#warning("Should find a way to mark this as `internal`")
	public static func runLimit(_ error: RunLimitError) -> Self {
		Self.error(prefix: "Reached Datalog execution limit", error: error)
	}
	
}

/// Runtime limits errors
public enum RunLimitError: Error, CustomStringConvertible {
	
	case tooManyFacts
	case tooManyIterations
	case timeout
	
	public var description: String {
		switch self {
		case .tooManyFacts:
			return "Too many facts generated"
		case .tooManyIterations:
			return "Too many engine iterations"
		case .timeout:
			return "Spent too much time verifying"
		}
	}
	
}

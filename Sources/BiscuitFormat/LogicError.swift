//
//  LogicError.swift
//  Biscuit
//
//  Created by Rémi Bardon on 15/09/2021.
//

import Foundation
import BiscuitShared

extension BiscuitError {
	
	internal static func failedLogic(_ error: LogicError) -> Self {
		.error(prefix: "Check validation failed", error: error)
	}
	
}

/// Errors in the Datalog evaluation
public enum LogicError: Error, CustomStringConvertible {
	
	case invalidAuthorityFact(String)
	case invalidAmbientFact(String)
	case invalidBlockFact(UInt32, String)
	case invalidBlockRule(UInt32, String)
	case failedChecks([FailedCheckError])
	case verifierNotEmpty
	case deny(Int)
	case noMatchingPolicy
	
	public var description: String {
		switch self {
		case let .invalidAuthorityFact(fact):
			return "A fact of the authority block did not have the authority tag: \(fact)"
		case let .invalidAmbientFact(fact):
			return "A fact provided or generated by the verifier did not have the ambient tag: \(fact)"
		case let .invalidBlockFact(index, fact):
			return "A fact provided or generated by a block had the authority or ambient tag: \(index) \(fact)"
		case let .invalidBlockRule(index, fact):
			return "A rule provided by a block is generating facts with the authority or ambient tag, or has head variables not used in its body: \(index) \(fact)"
		case let .failedChecks(errors):
			return "List of checks that failed validation: \(errors)"
		case .verifierNotEmpty:
			return "The verifier already contains a token"
		case let .deny(index):
			return "Denied by policy \(index)"
		case .noMatchingPolicy:
			return "No matching policy was found"
		}
	}
	
}

/// Check errors
public enum FailedCheckError: Error, CustomStringConvertible {
	
	// Rule = Pretty print of the rule that failed
	case block(blockId: UInt32, checkId: UInt32, rule: String)
	// Rule = Pretty print of the rule that failed
	case verifier(checkId: UInt32, rule: String)
	
	public var description: String {
		switch self {
		case let .block(blockId, checkId, rule):
			return "Check \(checkId) in block \(blockId) failed: \(rule)"
		case let .verifier(checkId, rule):
			return "Check \(checkId) provided by the verifier failed: \(rule)"
		}
	}
	
}
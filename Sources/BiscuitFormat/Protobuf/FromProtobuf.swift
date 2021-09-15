//
//  FromProtobuf.swift
//  Biscuit
//
//  Created by Rémi Bardon on 14/09/2021.
//

import Foundation
import OrderedCollections
import BiscuitDatalog
import BiscuitCrypto

extension Proto_Block {
	
	func tokenBlock() throws -> Token_Block {
		try ProtobufToTokenTransformer.tokenBlock(from: self)
	}
	
}

struct ProtobufToTokenTransformer {
	
	static func tokenBlock(from block: Proto_Block) throws -> Token_Block {
		let version = block.version // Note: Defaults to 0
		if version > MAX_SCHEMA_VERSION {
			throw FormatError.version(maximum: MAX_SCHEMA_VERSION, actual: version)
		}
		
		if version == 2 {
			return Token_Block(
				symbolTable: SymbolTable(symbols: block.symbols),
				facts: try block.factsV2.map(tokenFact(from:)),
				rules: try block.rulesV2.map(tokenRule(from:)),
				checks: try block.checksV2.map(tokenCheck(from:)),
				context: block.optContext,
				version: version
			)
		} else {
			return Token_Block(
				symbolTable: SymbolTable(symbols: block.symbols),
				facts: [],
				rules: [],
				checks: [],
				context: block.optContext,
				version: version
			)
		}
	}
	
	static func tokenFact(from fact: Proto_FactV2) throws -> Fact {
		Fact(predicate: try tokenPredicate(from: fact.predicate))
	}
	
	static func tokenRule(from rule: Proto_RuleV2) throws -> Rule {
		Rule(
			head: try tokenPredicate(from: rule.head),
			body: try rule.body.map(tokenPredicate(from:)),
			expressions: try rule.expressions.map(tokenExpression(from:))
		)
	}
	
	static func tokenCheck(from check: Proto_CheckV2) throws -> Check {
		Check(queries: try check.queries.map(tokenRule(from:)))
	}
	
	static func tokenPredicate(from predicate: Proto_PredicateV2) throws -> Predicate {
		Predicate(
			name: predicate.name,
			ids: try predicate.ids.map(tokenId(from:))
		)
	}
	
	static func tokenExpression(from expression: Proto_ExpressionV2) throws -> Expression {
		Expression(ops: try expression.ops.map(tokenOperation(from:)))
	}
	
	static func tokenOperation(from operation: Proto_Op) throws -> BiscuitDatalog.Operation {
		guard let content = operation.content else {
			throw FormatError.deserializationError("Operation is empty")
		}
		
		switch content {
		case .value(let id):
			return .value(try tokenId(from: id))
		case .unary(let unary):
			return .unary(try tokenUnaryOperation(from: unary))
		case .binary(let binary):
			return .binary(try tokenBinaryOperation(from: binary))
		}
	}
	
	static func tokenUnaryOperation(from unaryOperation: Proto_OpUnary) throws -> UnaryOperation {
		guard let kind = unaryOperation.optKind else {
			throw FormatError.deserializationError("Unary operation is empty")
		}
		
		switch kind {
		case .negate:
			return .negate
		case .parens:
			return .parens
		case .length:
			return .length
		}
	}
	
	static func tokenBinaryOperation(from binaryOperation: Proto_OpBinary) throws -> BinaryOperation {
		guard let kind = binaryOperation.optKind else {
			throw FormatError.deserializationError("Binary operation is empty")
		}
		
		switch kind {
		case .lessThan:
			return .lessThan
		case .greaterThan:
			return .greaterThan
		case .lessOrEqual:
			return .lessOrEqual
		case .greaterOrEqual:
			return .greaterOrEqual
		case .equal:
			return .equal
		case .contains:
			return .contains
		case .prefix:
			return .prefix
		case .suffix:
			return .suffix
		case .regex:
			return .regex
		case .add:
			return .add
		case .sub:
			return .sub
		case .mul:
			return .mul
		case .div:
			return .div
		case .and:
			return .and
		case .or:
			return .or
		case .intersection:
			return .intersection
		case .union:
			return .union
		}
	}
	
	static func tokenId(from id: Proto_IDV2) throws -> ID {
		guard let content = id.content else {
			throw FormatError.deserializationError("ID content enum is empty")
		}
		
		switch content {
		case .variable(let index):
			return .variable(index)
		case .integer(let i):
			return .integer(i)
		case .string(let s):
			return .string(s)
		case .date(let uInt64):
			return .date(uInt64)
		case .bytes(let data):
			return .bytes(data)
		case .bool(let b):
			return .bool(b)
		case .set(let idSet):
			return .set(try tokenIdSet(from: idSet))
		}
	}
	
	static func tokenIdSet(from idSet: Proto_IDSet) throws -> OrderedSet<ID> {
		var result = OrderedSet<ID>.init(minimumCapacity: idSet.set.count)
		var kind: UInt8? = nil
		
		for id in idSet.set {
			guard let content = id.content else {
				throw FormatError.deserializationError("ID content enum is empty")
			}
			
			// Make sure the kind of elements stays the same in the whole set
			let newKind: UInt8 = try {
				switch content {
				case .variable:
					throw FormatError.deserializationError("Sets cannot contain variables")
				case .integer:
					return 2
				case .string:
					return 3
				case .date:
					return 4
				case .bytes:
					return 5
				case .bool:
					return 6
				case .set:
					throw FormatError.deserializationError("Sets cannot contain other sets")
				}
			}()
			if let kind = kind {
				guard newKind == kind else {
					throw FormatError.deserializationError("Sets elements must have the same type")
				}
			} else {
				kind = newKind
			}
			
			result.append(try tokenId(from: id))
		}
		
		return result
	}
	
}

extension ProtobufToTokenTransformer {
	
	static func tokenVerifier(from verifier: Proto_VerifierPolicies) throws -> VerifierPolicies {
		VerifierPolicies(
			version: verifier.version,
			symbols: SymbolTable(symbols: verifier.symbols),
			facts: try verifier.facts.map(tokenFact(from:)),
			rules: try verifier.rules.map(tokenRule(from:)),
			checks: try verifier.checks.map(tokenCheck(from:)),
			policies: try verifier.policies.map(tokenPolicy(from:))
		)
	}
	
	static func tokenPolicy(from policy: Proto_Policy) throws -> Policy {
		guard let kind = policy.optKind else {
			throw FormatError.deserializationError("Policy kind is empty")
		}
		
		return Policy(
			queries: try policy.queries.map(tokenRule(from:)),
			kind: tokenPolicyKind(from: kind)
		)
	}
	
	static func tokenPolicyKind(from kind: Proto_Policy.Kind) -> PolicyKind {
		switch kind {
		case .allow:
			return .allow
		case .deny:
			return .deny
		}
	}
	
}

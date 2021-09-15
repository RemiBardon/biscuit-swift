//
//  ToProtobuf.swift
//  Biscuit
//
//  Created by Rémi Bardon on 14/09/2021.
//

import Foundation
import BiscuitDatalog

extension Token_Block {
	
	var proto: Proto_Block {
		TokenToProtobufTransformer.protoBlock(from: self)
	}
	
}

struct TokenToProtobufTransformer {
	
	static func protoBlock(from block: Token_Block) -> Proto_Block {
		Proto_Block.with {
			$0.symbols = Array(block.symbols.symbols)
			$0.optContext = block.context
			$0.version = block.version
			$0.factsV2 = block.facts.map(protoFact(from:))
			$0.rulesV2 = block.rules.map(protoRule(from:))
			$0.checksV2 = block.checks.map(protoCheck(from:))
		}
	}
	
	static func protoFact(from fact: Fact) -> Proto_FactV2 {
		Proto_FactV2.with {
			$0.predicate = protoPredicate(from: fact.predicate)
		}
	}
	
	static func protoRule(from rule: Rule) -> Proto_RuleV2 {
		Proto_RuleV2.with {
			$0.head = protoPredicate(from: rule.head)
			$0.body = rule.body.map(protoPredicate(from:))
			$0.expressions = rule.expressions.map(protoExpression(from:))
		}
	}
	
	static func protoCheck(from check: Check) -> Proto_CheckV2 {
		Proto_CheckV2.with {
			$0.queries = check.queries.map(protoRule(from:))
		}
	}
	
	static func protoPredicate(from pred: Predicate) -> Proto_PredicateV2 {
		Proto_PredicateV2.with {
			$0.name = pred.name
			$0.ids = pred.ids.map(protoId(from:))
		}
	}
	
	static func protoExpression(from expression: Expression) -> Proto_ExpressionV2 {
		Proto_ExpressionV2.with {
			$0.ops = expression.ops.map(protoOperation(from:))
		}
	}
	
	static func protoOperation(from op: BiscuitDatalog.Operation) -> Proto_Op {
		Proto_Op.with {
			switch op {
			case .value(let id):
				$0.content = .value(protoId(from: id))
			case .unary(let unary):
				$0.content = .unary(protoUnaryOperation(from: unary))
			case .binary(let binary):
				$0.content = .binary(protoBinaryOperation(from: binary))
			}
		}
	}
	
	static func protoUnaryOperation(from unaryOperation: UnaryOperation) -> Proto_OpUnary {
		Proto_OpUnary.with {
			switch unaryOperation {
			case .negate:
				$0.optKind = .negate
			case .parens:
				$0.optKind = .parens
			case .length:
				$0.optKind = .length
			}
		}
	}
	
	static func protoBinaryOperation(from binaryOperation: BinaryOperation) -> Proto_OpBinary {
		Proto_OpBinary.with {
			switch binaryOperation {
			case .lessThan:
				$0.optKind = .lessThan
			case .greaterThan:
				$0.optKind = .greaterThan
			case .lessOrEqual:
				$0.optKind = .lessOrEqual
			case .greaterOrEqual:
				$0.optKind = .greaterOrEqual
			case .equal:
				$0.optKind = .equal
			case .contains:
				$0.optKind = .contains
			case .prefix:
				$0.optKind = .prefix
			case .suffix:
				$0.optKind = .suffix
			case .regex:
				$0.optKind = .regex
			case .add:
				$0.optKind = .add
			case .sub:
				$0.optKind = .sub
			case .mul:
				$0.optKind = .mul
			case .div:
				$0.optKind = .div
			case .and:
				$0.optKind = .and
			case .or:
				$0.optKind = .or
			case .intersection:
				$0.optKind = .intersection
			case .union:
				$0.optKind = .union
			}
		}
	}
	
	static func protoId(from id: ID) -> Proto_IDV2 {
		Proto_IDV2.with {
			switch id {
			case .variable(let v):
				$0.content = .variable(v)
			case .integer(let i):
				$0.content = .integer(i)
			case .string(let symbolIndex):
				$0.content = .string(symbolIndex)
			case .date(let uInt64):
				$0.content = .date(uInt64)
			case .bytes(let data):
				$0.content = .bytes(data)
			case .bool(let b):
				$0.content = .bool(b)
			case .set(let orderedSet):
				$0.content = .set(Proto_IDSet.with {
					$0.set = orderedSet.map(protoId(from:))
				})
			}
		}
	}
	
}

extension VerifierPolicies {
	
	var proto: Proto_VerifierPolicies {
		TokenToProtobufTransformer.protoVerifier(from: self)
	}
	
}

extension TokenToProtobufTransformer {
	
	static func protoVerifier(from verifier: VerifierPolicies) -> Proto_VerifierPolicies {
		Proto_VerifierPolicies.with {
			$0.symbols = Array(verifier.symbols.symbols)
			$0.version = verifier.version
			$0.facts = verifier.facts.map(protoFact(from:))
			$0.rules = verifier.rules.map(protoRule(from:))
			$0.checks = verifier.checks.map(protoCheck(from:))
			$0.policies = verifier.policies.map { protoPolicy(from: $0, symbols: verifier.symbols) }
		}
	}
	
	static func protoPolicy(from policy: Policy, symbols: SymbolTable) -> Proto_Policy {
		Proto_Policy.with {
			$0.queries = policy.queries.map(protoRule(from:))
		}
	}
	
}

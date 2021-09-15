//
//  Expression.swift
//  Datalog
//
//  Created by Rémi Bardon on 10/05/2021.
//

import Foundation

public enum Op {
	case value(ID)
	case unary(UnaryOp)
	case binary(BinaryOp)
}

public enum UnaryOp {
	
	case negate, parens, length
	
	func evaluate(_ value: ID, symbols: SymbolTable) -> ID? {
		switch (self, value) {
		case let (.negate, .bool(b)):
			return ID.bool(!b)
		case let (.parens, i):
			return i
		case let (.length, .string(i)):
			return symbols.getSymbol(i).map { ID.integer(Int64($0.count)) }
		case let (.length, .bytes(s)):
			return ID.integer(Int64(s.count))
		case let (.length, .set(s)):
			return ID.integer(Int64(s.count))
		default:
			assertionFailure("Unexpected value type on the stack")
			return nil
		}
	}
	
	public func print(_ value: String, _symbols: SymbolTable) -> String {
		switch self {
		case .negate:
			return "!\(value)"
		case .parens:
			return "(\(value))"
		case .length:
			return "\(value).count"
		}
	}
	
}

public enum BinaryOp {
	
	case lessThan, greaterThan, lessOrEqual, greaterOrEqual, equal, contains, prefix, suffix, regex
	case add, sub, mul, div, and, or, intersection, union
	
	public func evaluate(left: ID, right: ID, symbols: SymbolTable) -> ID? {
		switch (self, left, right) {
		// Integer
		case let (.lessThan, .integer(i), .integer(j)):
			return .bool(i < j)
		case let (.greaterThan, .integer(i), .integer(j)):
			return .bool(i > j)
		case let (.lessOrEqual, .integer(i), .integer(j)):
			return .bool(i <= j)
		case let (.greaterOrEqual, .integer(i), .integer(j)):
			return .bool(i >= j)
		case let (.equal, .integer(i), .integer(j)):
			return .bool(i == j)
		case let (.add, .integer(i), .integer(j)):
			return i.checkedAdd(j).map(ID.integer)
		case let (.sub, .integer(i), .integer(j)):
			return i.checkedSub(j).map(ID.integer)
		case let (.mul, .integer(i), .integer(j)):
			return i.checkedMult(j).map(ID.integer)
		case let (.div, .integer(i), .integer(j)):
			return i.checkedDiv(j).map(ID.integer)
		
		// String
		case let (.prefix, .string(s), .string(pref)):
			if let s = symbols.getSymbol(s), let pref = symbols.getSymbol(pref) {
				return .bool(s.hasPrefix(pref))
			} else {
				return nil
			}
		case let (.suffix, .string(s), .string(suff)):
			if let s = symbols.getSymbol(s), let suff = symbols.getSymbol(suff) {
				return .bool(s.hasSuffix(suff))
			} else {
				return nil
			}
		case let (.regex, .string(s), .string(r)):
			if let s = symbols.getSymbol(s), let r = symbols.getSymbol(r) {
				return .bool(s ~= r)
			} else {
				return nil
			}
		case let (.equal, .string(i), .string(j)):
			return .bool(i == j)
		
		// Date
		case let (.lessThan, .date(i), .date(j)):
			return .bool(i < j)
		case let (.greaterThan, .date(i), .date(j)):
			return .bool(i > j)
		case let (.lessOrEqual, .date(i), .date(j)):
			return .bool(i <= j)
		case let (.greaterOrEqual, .date(i), .date(j)):
			return .bool(i >= j)
		case let (.equal, .date(i), .date(j)):
			return .bool(i == j)
		
		// Byte array
		case let (.equal, .bytes(i), .bytes(j)):
			return .bool(i == j)
		
		// Set
		case let (.equal, .set(set), .set(s)):
			return .bool(set == s)
		case let (.intersection, .set(set), .set(s)):
			return .set(set.intersection(s))
		case let (.union, .set(set), .set(s)):
			return .set(set.union(s))
		case let (.contains, .set(set), .set(s)):
			return .bool(set.isSuperset(of: s))
		case let (.contains, .set(set), .integer(i)):
			return .bool(set.contains(.integer(i)))
		case let (.contains, .set(set), .date(i)):
			return .bool(set.contains(.date(i)))
		case let (.contains, .set(set), .bool(i)):
			return .bool(set.contains(.bool(i)))
		case let (.contains, .set(set), .string(i)):
			return .bool(set.contains(.string(i)))
		case let (.contains, .set(set), .bytes(i)):
			return .bool(set.contains(.bytes(i)))
		
		// Boolean
		case let (.and, .bool(i), .bool(j)):
			return .bool(i && j)
		case let (.or, .bool(i), .bool(j)):
			return .bool(i || j)
		default:
			assertionFailure("Unexpected value type on the stack")
			return nil
		}
	}
	
	public func print(left: String, right: String, _symbols: SymbolTable) -> String {
		switch self {
		case .lessThan:
			return "\(left) < \(right)"
		case .greaterThan:
			return "\(left) > \(right)"
		case .lessOrEqual:
			return "\(left) <= \(right)"
		case .greaterOrEqual:
			return "\(left) >= \(right)"
		case .equal:
			return "\(left) == \(right)"
		case .contains:
			return "\(left).contains(\(right))"
		case .prefix:
			return "\(left).hasPreffix(\(right))"
		case .suffix:
			return "\(left).hasSuffix(\(right))"
		case .regex:
			return "\(left).matches(\(right))"
		case .add:
			return "\(left) + \(right)"
		case .sub:
			return "\(left) - \(right)"
		case .mul:
			return "\(left) * \(right)"
		case .div:
			return "\(left) / \(right)"
		case .and:
			return "\(left) && \(right)"
		case .or:
			return "\(left) || \(right)"
		case .intersection:
			return "\(left).intersection(\(right))"
		case .union:
			return "\(left).union(\(right)"
		}
	}
	
}

public struct Expression {
	
	public let ops: [Op]
	
	public init(ops: [Op]) {
		self.ops = ops
	}
	
	public func evaluate(_ values: Dictionary<UInt32, ID>, symbols: SymbolTable) -> ID? {
		var stack = [ID]()
		
		for op in self.ops {
//			print("op: \(op)\t| stack: \(stack)")
			switch op {
			case let .value(.variable(i)):
				switch values[i] {
				case let .some(id):
					stack.append(id)
				case .none:
					assertionFailure("Unknown variable: \(i)")
					return nil
				}
			case let .value(id):
				stack.append(id)
			case let .unary(unary):
				switch stack.popLast() {
				case .none:
					assertionFailure("Expected a value on the stack")
					return nil
				case let .some(id):
					switch unary.evaluate(id, symbols: symbols) {
					case let .some(res): stack.append(res)
					case .none: return nil
					}
				}
			case let .binary(binary):
				switch (stack.popLast(), stack.popLast()) {
				case let (.some(rightId), .some(leftId)):
					switch binary.evaluate(left: leftId, right: rightId, symbols: symbols) {
					case let .some(res): stack.append(res)
					case .none: return nil
					}
				default:
					assertionFailure("Expected two values on the stack")
					return nil
				}
			}
		}
		
		if stack.count == 1, let first = stack.first {
			return first
		} else {
			return nil
		}
	}
	
	public func print(symbols: SymbolTable) -> String? {
		var stack = [String]()
		
		for op in self.ops {
//			print("op: \(op)\t| stack: \(stack)")
			switch op {
			case let .value(i):
				stack.append(symbols.printId(i))
			case let .unary(unary):
				switch stack.popLast() {
				case .none:
					return nil
				case let .some(s):
					stack.append(unary.print(s, _symbols: symbols))
				}
			case let .binary(binary):
				switch (stack.popLast(), stack.popLast()) {
				case let (.some(right), .some(left)):
					stack.append(binary.print(left: left, right: right, _symbols: symbols))
				default:
					return nil
				}
			}
		}
		
		if stack.count == 1, let first = stack.first {
			return first
		} else {
			return nil
		}
	}
	
}

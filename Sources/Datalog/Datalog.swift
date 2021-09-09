//
//  Datalog.swift
//  Datalog
//
//  Created by Rémi Bardon on 10/05/2021.
//

import Foundation
import OrderedCollections

public enum ID: Hashable {
	case variable(UInt32)
	case integer(Int64)
	case string(SymbolIndex)
	case date(UInt64)
	case bytes([UInt8])
	case bool(Bool)
	case set(OrderedSet<ID>)
}

public struct Predicate: Hashable {
	
	public let name: SymbolIndex
	public var ids: [ID]
	
	public init(name: SymbolIndex, ids: [ID]) {
		self.name = name
		self.ids = ids
	}
	
}

public struct Fact: Hashable, CustomStringConvertible {
	
	public let predicate: Predicate
	
	public var description: String {
		"\(self.predicate.name)(\(self.predicate.ids))"
	}
	
	public init(predicate: Predicate) {
		self.predicate = predicate
	}
	
	public init(name: SymbolIndex, ids: [ID]) {
		self.predicate = Predicate(name: name, ids: ids)
	}
	
}

public struct Rule {
	
	public let head: Predicate
	public let body: [Predicate]
	public let expressions: [Expression]
	
	/// Gather all of the variables used in that rule
	private var variablesSet: Set<UInt32> {
		Set(self.body.flatMap { pred in
			pred.ids.compactMap { id in
				switch id {
				case let .variable(i):
					return i
				default:
					return nil
				}
			}
		})
	}
	
	public func apply(facts: Set<Fact>, symbols: SymbolTable) -> [Fact] {
		let variables = MatchedVariables(self.variablesSet)
		
		return CombineIt(
			variables: variables,
			predicates: self.body,
			expressions: self.expressions,
			facts: facts,
			symbols: symbols
		).compactMap { h -> Fact? in
			var p = self.head
			for index in 0..<p.ids.count {
				switch p.ids[index] {
				case let .variable(i):
					switch h[i] {
					case let .some(val):
						p.ids[index] = val
					case .none:
						print("error: variables that appear in the head should appear in the body and constraints as well")
						return nil
					}
				default:
					continue
				}
			}
			
			return Fact(predicate: p)
		}
	}
	
	public func findMatch(facts: Set<Fact>, symbols: SymbolTable) -> Bool {
		let it = self.apply(facts: facts, symbols: symbols)
		return !it.isEmpty
	}
	
}

public struct Check {
	public let queries: [Rule]
}

/// Recursive iterator for rule application
public struct CombineIt {
	
	let variables: MatchedVariables
	let predicates: [Predicate]
	let expressions: [Expression]
	var allFacts: Set<Fact>
	let symbols: SymbolTable
	var currentFactsIterator: Set<Fact>.Iterator
	@Indirect var currentIt: CombineIt?
	
	public init(
		variables: MatchedVariables,
		predicates: [Predicate],
		expressions: [Expression],
		facts: Set<Fact>,
		symbols: SymbolTable
	) {
		let currentFacts: Set<Fact> = {
			if predicates.isEmpty {
				return facts
			} else {
				let p = predicates[0]
				return facts.filter { fact in matchPreds(rulePred: p, factPred: fact.predicate) }
			}
		}()
		
		self.variables = variables
		self.predicates = predicates
		self.expressions = expressions
		self.allFacts = facts
		self.symbols = symbols
		self.currentFactsIterator = currentFacts.makeIterator()
		self.currentIt = nil
	}
	
}

extension CombineIt: Sequence, IteratorProtocol {
	
	public mutating func next() -> [UInt32: ID]? {
		// If we're the last iterator in the recursive chain, stop here
		if self.predicates.isEmpty {
//			return nil
//			return self.variables.complete
			guard let variables = self.variables.complete else {
				return nil
			}
			// We got a complete set of variables, let's test the expressions
//			print("predicates empty, will test variables: \(String(reflecting: variables))")
			
			let valid = self.expressions.allSatisfy { e in
				let res = e.evaluate(variables, symbols: self.symbols)
//				print("expr returned \(String(reflecting: res))")
				return res == .bool(true)
			}
			
			if valid {
				return variables
			} else {
				return nil
			}
		}
		
		repeat {
			if self.currentIt == nil {
				// Fix the first predicate
				let pred = self.predicates[0]
				
				repeat {
					if let currentFact = self.currentFactsIterator.next() {
						// Create a new `MatchedVariables` in which we fix variables we could unify
						// from our first predicate and the current fact
						var vars = self.variables
						var matchIds = true
						for (key, id) in zip(pred.ids, currentFact.predicate.ids) {
							if case let (.variable(k), id) = (key, id) {
								if !vars.insert(key: k, value: id) {
									matchIds = false
								}
								
								if !matchIds {
									break
								}
							}
						}
						
						if !matchIds {
							continue
						}
						
						if self.predicates.count == 1 {
							switch vars.complete {
							case .none:
//								print("variables not complete, continue")
								continue
								// We got a complete set of variables, let's test the expressions
							case .some(let variables):
//								print("will test with variables: \(String(reflecting: variables))")
								let valid = self.expressions.allSatisfy { e in
									let res = e.evaluate(variables, symbols: self.symbols)
//									print("expr returned \(String(reflecting: res))")
									return res == .bool(true)
								}
								
								if valid {
									return variables
								} else {
									continue
								}
							}
						} else {
							// Create a new iterator with the matched variables, the rest of the predicates,
							// and all of the facts
							#warning("Creating new `CombineIt` passing parameters as value types will lead to memory issues")
							self.currentIt = CombineIt(
								variables: vars,
								predicates: Array(self.predicates.dropFirst()),
								expressions: self.expressions,
								facts: self.allFacts,
								symbols: self.symbols
							)
							break
						}
					} else {
						return nil
					}
				} while true
			}
			
			if self.currentIt == nil {
				return nil
			}
			
			if let val = self.currentIt?.next() {
				return val
			} else {
				self.currentIt = nil
			}
		} while true
	}
	
}

public struct MatchedVariables {
	
	private var dict: [UInt32: ID?]
	
	public init(_ set: Set<UInt32>) {
		self.dict = Dictionary(uniqueKeysWithValues: set.map { ($0, nil) })
	}
	
	public mutating func insert(key: UInt32, value: ID) -> Bool {
		switch self.dict[key] {
		case .some(.none):
			self.dict[key] = value
			return true
		case let .some(.some(v)):
			return value == v
		case .none:
			return false
		}
	}
	
	public var isComplete: Bool {
		self.dict.values.allSatisfy { $0 != nil }
	}
	
	public var complete: [UInt32: ID]? {
		var result = [UInt32: ID]()
		for (k, v) in self.dict {
			switch v {
			case let .some(value):
				result[k] = value
			case .none:
				return nil
			}
		}
		return result
	}
	
}

public func fact(_ name: SymbolIndex, _ ids: [ID]) -> Fact {
	Fact(predicate: Predicate(name: name, ids: ids))
}

public func pred(_ name: SymbolIndex, _ ids: [ID]) -> Predicate {
	Predicate(name: name, ids: ids)
}

public func rule(_ headName: SymbolIndex, _ headIds: [ID], _ predicates: [Predicate]) -> Rule {
	Rule(head: pred(headName, headIds), body: predicates, expressions: Array())
}

public func expressedRule(
	_ headName: SymbolIndex,
	_ headIds: [ID],
	_ predicates: [Predicate],
	_ expressions: [Expression]
) -> Rule {
	Rule(head: pred(headName, headIds), body: predicates, expressions: expressions)
}

public func int(_ i: Int64) -> ID {
	ID.integer(i)
}

/*public func string(s: &str) -> ID {
 .str(s.to_string())
 }*/

public func date(_ t: Date) -> ID {
	let seconds = t.timeIntervalSince1970
	return ID.date(UInt64(seconds))
}

public func `var`(_ syms: inout SymbolTable, _ name: String) -> ID {
	let id = syms.insert(name)
	return ID.variable(UInt32(id))
}

public func matchPreds(rulePred: Predicate, factPred: Predicate) -> Bool {
	rulePred.name == factPred.name
		&& rulePred.ids.count == factPred.ids.count
		&& zip(rulePred.ids, factPred.ids)
			.allSatisfy { fid, pid in
				switch (fid, pid) {
				case (_, .variable):
					// The fact should not contain variables
					return false
				case (.variable, _):
					return true
				case let (.integer(i), .integer(j)):
					return i == j
				case let (.string(i), .string(j)):
					return i == j
				case let (.date(i), .date(j)):
					return i == j
				case let (.bytes(i), .bytes(j)):
					return i == j
				case let (.bool(i), .bool(j)):
					return i == j
				case let (.set(i), .set(j)):
					return i == j
				default:
					return false
				}
			}
}

public struct World {
	
	public private(set) var facts: Set<Fact>
	public private(set) var rules: [Rule]
	
	public init() {
		self.facts = Set<Fact>()
		self.rules = [Rule]()
	}
	
	public mutating func addFact(_ fact: Fact) {
		self.facts.insert(fact)
	}
	
	public mutating func addRule(_ rule: Rule) {
		self.rules.append(rule)
	}
	
	public mutating func run(symbols: SymbolTable) throws {
		try self.runWithLimits(symbols: symbols, limits: RunLimits())
	}
	
	public mutating func runWithLimits(symbols: SymbolTable, limits: RunLimits) throws {
		let start = Date()
		let timeLimit = start + limits.maxTime
		var index = 0
		
		repeat {
			var newFacts = [Fact]()
			
			for rule in self.rules {
				newFacts.append(contentsOf: rule.apply(facts: self.facts, symbols: symbols))
//				print("newFacts after applying \(String(reflecting: rule)):\n\(String(reflecting: newFacts))")
			}
			
			let count = self.facts.count
			self.facts.formUnion(newFacts)
			if self.facts.count == count {
				break
			}
			
			index += 1
			if index == limits.maxIterations {
				throw RunLimitError.tooManyIterations
			}
			
			if self.facts.count >= limits.maxFacts {
				throw RunLimitError.tooManyFacts
			}
			
			let now = Date()
			if now >= timeLimit {
				throw RunLimitError.timeout
			}
		} while true
	}
	
	public func query(_ pred: Predicate) -> [Fact] {
		self.facts
			.filter { f in
				f.predicate.name == pred.name
					&& zip(f.predicate.ids, pred.ids).allSatisfy { (fid, pid) in
						switch (fid, pid) {
//						case (.symbol, .variable):
//							return true
//						case let (.symbol(i), .symbol(j)):
//							return i == j
						case (_, .variable):
							return true
						case let (.integer(i), .integer(j)):
							return i == j
						case let (.string(i), .string(j)):
							return i == j
						case let (.date(i), .date(j)):
							return i == j
						case let (.bytes(i), .bytes(j)):
							return i == j
						case let (.bool(i), .bool(j)):
							return i == j
						case let (.set(i), .set(j)):
							return i == j
						default:
							return false
						}
					}
			}
	}
	
	public mutating func queryRule(_ rule: Rule, symbols: SymbolTable) -> [Fact] {
		rule.apply(facts: self.facts, symbols: symbols)
	}
	
	public mutating func queryMatch(_ rule: Rule, symbols: SymbolTable) -> Bool {
		rule.findMatch(facts: self.facts, symbols: symbols)
	}
	
}

public struct RunLimits {
	
	public let maxFacts: UInt32
	public let maxIterations: UInt32
	/// Max time **in seconds**
	public let maxTime: TimeInterval
	
	init() {
		self.maxFacts = 1000
		self.maxIterations = 100
		// FIXME: I had to increase `maxTime` to 2ms otherwise some tests would not succeed
		self.maxTime = 0.002
	}
	
}

public enum RunLimitError: Error, CustomStringConvertible {
	
	case tooManyFacts, tooManyIterations, timeout
	
	public var description: String {
		switch self {
		case .tooManyFacts:
			return "too many facts generated"
		case .tooManyIterations:
			return "too many engine iterations"
		case .timeout:
			return "spent too much time verifying"
		}
	}
	
}

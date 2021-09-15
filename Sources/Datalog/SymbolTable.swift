//
//  SymbolTable.swift
//  Datalog
//
//  Created by Rémi Bardon on 10/05/2021.
//

import Foundation

public typealias SymbolIndex = UInt64

public struct SymbolTable {
	
	public var symbols: [String]
	
	public init(symbols: [String] = []) {
		self.symbols = symbols
	}
	
	public mutating func insert(_ s: String) -> SymbolIndex {
		if let index = self.symbols.firstIndex(of: s) {
			return UInt64(index)
		} else {
			self.symbols.append(s)
			return UInt64(self.symbols.count - 1)
		}
	}
	
	public mutating func add(_ s: String) -> ID {
		let id = self.insert(s)
		return .string(id)
	}
	
	public func get(_ s: String) -> SymbolIndex? {
		self.symbols.firstIndex(of: s).map(SymbolIndex.init)
	}
	
	public func getSymbol(_ i: SymbolIndex) -> String? {
		self.symbols[Int(i)]
	}
	
	public func printSymbol(_ i: SymbolIndex) -> String {
		self.symbols[Int(i), default: "<\(i)?>"]
	}
	
	public func printWorld(_ w: World) -> String {
		let facts = w.facts.map(self.printFact)
		let rules = w.rules.map(self.printRule)
		
		return "World {{\n  facts: \(facts)\n  rules: \(rules)\n}}"
	}
	
	public func printId(_ id: ID) -> String {
		switch id {
		case let .variable(i):
			return "$\(self.printSymbol(UInt64(i)))"
		case let .integer(i):
			return "\(i)"
		case let .string(index):
			return "\"\(index)\""
		case let .date(d):
			let date = Date(timeIntervalSince1970: TimeInterval(d))
			return ISO8601DateFormatter().string(from: date)
		case let .bytes(s):
			return "hex:\(Data(s).hexEncodedString())"
		case let .bool(b):
			return "\(b)"
		case let .set(s):
			let ids = s.map(self.printId)
			return "[\(ids.joined(separator: ", "))]"
		}
	}
	
	public func printFact(_ f: Fact) -> String {
		self.printPredicate(f.predicate)
	}
	
	public func printPredicate(_ p: Predicate) -> String {
		let strings = p.ids.map(self.printId)
		
		return String(
			format: "%@(%@)",
			self.symbols[Int(p.name), default: "<?>"],
			strings.joined(separator: ", ")
		)
	}
	
	public func printExpression(_ e: Expression) -> String {
		e.print(symbols: self) ?? "<invalid expression: \(e.ops)>"
	}
	
	public func printRuleBody(_ r: Rule) -> String {
		let preds = r.body.map(self.printPredicate)
		let expressions = r.expressions.map(self.printExpression)
		
		return "\((preds + expressions).joined(separator: ", "))"
	}
	
	public func printRule(_ r: Rule) -> String {
		let res = self.printPredicate(r.head)
		
		return "\(res) <- \(self.printRuleBody(r))"
	}
	
	public func printCheck(_ c: Check) -> String {
		let queries = c.queries.map(self.printRuleBody)
		
		return "check if \(queries.joined(separator: " or "))"
	}
	
}

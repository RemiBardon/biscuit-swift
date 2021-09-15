//
//  SymbolTable.swift
//  Biscuit
//
//  Created by Rémi Bardon on 10/05/2021.
//

import Foundation
import OrderedCollections

public typealias SymbolIndex = UInt64

public struct SymbolTable {
	
	public typealias Element = String
	
	public private(set) var symbols: OrderedSet<Element>
	
	public init(symbols: [Element] = []) {
		self.symbols = OrderedSet(symbols)
	}
	
	@discardableResult public mutating func insert(_ s: String) -> SymbolIndex {
		return SymbolIndex(self.symbols.append(s).index)
	}
	
	@discardableResult public mutating func insert<S: Sequence>(
		contentsOf elements: S
	) -> [SymbolIndex] where S.Element == Element {
		return elements.map { self.insert($0) }
	}
	
	@discardableResult public mutating func add(_ s: String) -> ID {
		return .string(self.insert(s))
	}
	
	@discardableResult public mutating func add<S: Sequence>(
		contentsOf elements: S
	) -> [ID] where S.Element == Element {
		return elements.map { self.add($0) }
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

extension SymbolTable {
	
	/// Some symbols are predefined and available in every implementation,
	/// to avoid transmitting them with every token.
	public static var defaultTable: Self {
		var syms = SymbolTable()
		
		syms.insert("authority")
		syms.insert("ambient")
		syms.insert("resource")
		syms.insert("operation")
		syms.insert("right")
		syms.insert("current_time")
		syms.insert("revocation_id")
		
		return syms
	}
	
}

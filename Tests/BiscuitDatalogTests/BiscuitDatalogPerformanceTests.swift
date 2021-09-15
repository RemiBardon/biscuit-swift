//
//  BiscuitDatalogPerformanceTests.swift
//  Biscuit
//
//  Created by Rémi Bardon on 08/09/2021.
//

import XCTest
@testable import BiscuitDatalog

final class BiscuitDatalogPerformanceTests: XCTestCase {
	
	func testFamilyOn1MillionPeople() throws {
		throw XCTSkip("Too long")
		var w = World.empty
		var syms = SymbolTable()
		
		var ids = [Int: ID]()
		for i in 1...1_000_000 {
			ids[i] = syms.add("Person \(i)")
			if i.isMultiple(of: 100) {
				print("Inserted \(i) people")
			}
		}
		let parent = syms.insert("parent")
		let grandparent = syms.insert("grandparent")
		
		let grandparentRule = rule(
			grandparent,
			[`var`(&syms, "grandparent"), `var`(&syms, "grandchild")],
			[
				pred(
					parent,
					[`var`(&syms, "grandparent"), `var`(&syms, "parent")]
				),
				pred(
					parent,
					[`var`(&syms, "parent"), `var`(&syms, "grandchild")]
				),
			]
		)
		
		measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
			_ = w.queryRule(grandparentRule, symbols: syms)
		}
	}
	
}

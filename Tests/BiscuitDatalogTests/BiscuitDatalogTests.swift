//
//  BiscuitDatalogTests.swift
//  Biscuit
//
//  Created by Rémi Bardon on 11/05/2021.
//

import XCTest
@testable import BiscuitDatalog

final class BiscuitDatalogTests: XCTestCase {
	
	func testFamily() throws {
		var w = World.empty
		var syms = SymbolTable()
		
		let a = syms.add("A")
		let b = syms.add("B")
		let c = syms.add("C")
		let d = syms.add("D")
		let e = syms.add("e")
		let parent = syms.insert("parent")
		let grandparent = syms.insert("grandparent")
		
		w.addFact(fact(parent, [a, b]))
		w.addFact(fact(parent, [b, c]))
		w.addFact(fact(parent, [c, d]))
		
		let r1 = rule(
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
		
		print("symbols: \(syms)")
		print("testing r1: \(syms.printRule(r1))")
		let queryRuleResult = w.queryRule(r1, symbols: syms)
		print("grandparents queryRules: \(queryRuleResult)")
		print("current facts: \(w.facts)")
		
		let r2 = rule(
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
		
		print("adding r2: \(syms.printRule(r2))")
		w.addRule(r2)
		
		try w.run(symbols: syms)
		
		print("parents:")
		let res = w.query(pred(
			parent,
			[`var`(&syms, "parent"), `var`(&syms, "child")]
		))
		for fact in res {
			print("\t\(syms.printFact(fact))")
		}
		
		print(String(
			format: "parents of B: %@",
			w.query(pred(
				parent,
				[`var`(&syms, "parent"), b]
			))
		))
		print(String(
			format: "grandparents: %@",
			w.query(pred(
				grandparent,
				[`var`(&syms, "grandparent"), `var`(&syms, "grandchild")]
			))
		))
		w.addFact(fact(parent, [c, e]))
		try w.run(symbols: syms)
		do {
			let res = w.query(pred(
				grandparent,
				[`var`(&syms, "grandparent"), `var`(&syms, "grandchild")]
			))
			print("grandparents after inserting parent(C, E): {:?}", res)
			
			let expected = Set([
				fact(grandparent, [a,c]),
				fact(grandparent, [b,d]),
				fact(grandparent, [b,e]),
			])
			XCTAssertEqual(expected, Set(res))
		}
		
		/*w.add_rule(rule("siblings", [var("A"), var("B")], [
		  pred(parent, [var(parent), var("A")]),
		  pred(parent, [var(parent), var("B")])
		]))
		w.run()
		print("siblings: {:#?}", w.query(pred("siblings", [var("A"), var("B")])))
		*/
	}
	
	func testNumbers() {
		var w = World.empty
		var syms = SymbolTable()
		
		let abc = syms.add("abc")
		let def = syms.add("def")
		let ghi = syms.add("ghi")
		let jkl = syms.add("jkl")
		let mno = syms.add("mno")
		let aaa = syms.add("AAA")
		let bbb = syms.add("BBB")
		let ccc = syms.add("CCC")
		let t1 = syms.insert("t1")
		let t2 = syms.insert("t2")
		let join = syms.insert("join")
		
		w.addFact(fact(t1, [int(0), abc]))
		w.addFact(fact(t1, [int(1), def]))
		w.addFact(fact(t1, [int(2), ghi]))
		w.addFact(fact(t1, [int(3), jkl]))
		w.addFact(fact(t1, [int(4), mno]))
		
		w.addFact(fact(t2, [int(0), aaa, int(0)]))
		w.addFact(fact(t2, [int(1), bbb, int(0)]))
		w.addFact(fact(t2, [int(2), ccc, int(1)]))
		
		let res = w.queryRule(rule(
			join,
			[`var`(&syms, "left"), `var`(&syms, "right")],
			[
				pred(t1, [`var`(&syms, "id"), `var`(&syms, "left")]),
				pred(
					t2,
					[
						`var`(&syms, "t2_id"),
						`var`(&syms, "right"),
						`var`(&syms, "id"),
					]
				)
			]
		), symbols: syms)
		for fact in res {
			print("\t\(syms.printFact(fact))")
		}
		
		let expected = Set([
			fact(join, [abc, aaa]),
			fact(join, [abc, bbb]),
			fact(join, [def, ccc]),
		])
		XCTAssertEqual(expected, Set(res))
		
		do {
			// test constraints
			let res = w.queryRule(expressedRule(
				join,
				[`var`(&syms, "left"), `var`(&syms, "right")],
				[
					pred(t1, [`var`(&syms, "id"), `var`(&syms, "left")]),
					pred(
						t2,
						[
							`var`(&syms, "t2_id"),
							`var`(&syms, "right"),
							`var`(&syms, "id"),
						]
					),
				],
				[
					Expression(ops: [
						.value(`var`(&syms, "id")),
						.value(.integer(1)),
						.binary(.lessThan),
					]),
				]
			), symbols: syms)
			for fact in res {
				print("\t\(syms.printFact(fact))")
			}
			
			let expected = Set([fact(join, [abc, aaa]), fact(join, [abc, bbb])])
			XCTAssertEqual(expected, Set(res))
		}
	}
	
	func testString() {
		var w = World.empty
		var syms = SymbolTable()
		
		let app0 = syms.add("app_0")
		let app1 = syms.add("app_1")
		let app2 = syms.add("app_2")
		let route = syms.insert("route")
		let suff = syms.insert("route suffix")
		let example = syms.add("example.com")
		let testCom = syms.add("test.com")
		let testFr = syms.add("test.fr")
		let wwwExample = syms.add("www.example.com")
		let mxExample = syms.add("mx.example.com")
		
		w.addFact(fact(route, [int(0), app0, example]))
		w.addFact(fact(route, [int(1), app1, testCom]))
		w.addFact(fact(route, [int(2), app2, testFr]))
		w.addFact(fact(route, [int(3), app0, wwwExample]))
		w.addFact(fact(route, [int(4), app1, mxExample]))
		
		func testSuffix(
			w: inout World,
			syms: inout SymbolTable,
			suff: SymbolIndex,
			route: SymbolIndex,
			suffix: String
		) -> [Fact] {
			let idSuff = syms.add(suffix)
			return w.queryRule(expressedRule(
				suff,
				[`var`(&syms, "app_id"), `var`(&syms, "domain_name")],
				[
					pred(
						route,
						[
							`var`(&syms, "route_id"),
							`var`(&syms, "app_id"),
							`var`(&syms, "domain_name"),
						]
					),
				],
				[
					Expression(ops: [
						.value(`var`(&syms, "domain_name")),
						.value(idSuff),
						.binary(.suffix),
					]),
				]
			), symbols: syms)
		}
		
		let res = testSuffix(w: &w, syms: &syms, suff: suff, route: route, suffix: ".fr")
		for fact in res {
			print("\t\(syms.printFact(fact))")
		}
		
		do {
			let expected = Set([fact(suff, [app2, testFr])])
			XCTAssertEqual(expected, Set(res))
		}
		
		do {
			let res = testSuffix(w: &w, syms: &syms, suff: suff, route: route, suffix: "example.com")
			for fact in res {
				print("\t\(syms.printFact(fact))")
			}
			
			let expected = Set([
				fact(suff, [app0, example]),
				fact(suff, [app0, wwwExample]),
				fact(suff, [app1, mxExample]),
			])
			XCTAssertEqual(expected, Set(res))
		}
	}
	
	func testDateConstraint() {
		var w = World.empty
		var syms = SymbolTable()
		
		let t1 = Date()
		print("t1 = \(t1)")
		let t2 = t1 + TimeInterval(10)
		print("t2 = \(t2)")
		let t3 = t2 + TimeInterval(30)
		print("t3 = \(t3)")
		
		let t2Timestamp = t2.timeIntervalSince1970
		
		let abc = syms.add("abc")
		let def = syms.add("def")
		let x = syms.insert("x")
		let before = syms.insert("before")
		let after = syms.insert("after")
		
		w.addFact(fact(x, [date(t1), abc]))
		w.addFact(fact(x, [date(t3), def]))
		
		let r1 = expressedRule(
			before,
			[`var`(&syms, "date"), `var`(&syms, "val")],
			[pred(x, [`var`(&syms, "date"), `var`(&syms, "val")])],
			[
				Expression(ops: [
					.value(`var`(&syms, "date")),
					.value(.date(UInt64(t2Timestamp))),
					.binary(.lessOrEqual),
				]),
				Expression(ops: [
					.value(`var`(&syms, "date")),
					.value(.date(0)),
					.binary(.greaterOrEqual),
				]),
			]
		)
		
		print("testing r1: \(syms.printRule(r1))")
		let res = w.queryRule(r1, symbols: syms)
		for fact in res {
			print("\t\(syms.printFact(fact))")
		}
		
		let expected = Set([fact(before, [date(t1), abc])])
		XCTAssertEqual(expected, Set(res))
		
		let r2 = expressedRule(
			after,
			[`var`(&syms, "date"), `var`(&syms, "val")],
			[pred(x, [`var`(&syms, "date"), `var`(&syms, "val")])],
			[
				Expression(ops: [
					.value(`var`(&syms, "date")),
					.value(.date(UInt64(t2Timestamp))),
					.binary(.greaterOrEqual),
				]),
				Expression(ops: [
					.value(`var`(&syms, "date")),
					.value(.date(0)),
					.binary(.greaterOrEqual),
				]),
			]
		)
		
		do {
			print("testing r2: \(syms.printRule(r2))")
			let res = w.queryRule(r2, symbols: syms)
			for fact in res {
				print("\t\(syms.printFact(fact))")
			}
			
			let expected = Set([fact(after, [date(t3), def])])
			XCTAssertEqual(expected, Set(res))
		}
	}
	
	func testSetConstraint() {
		var w = World.empty
		var syms = SymbolTable()
		
		let abc = syms.add("abc")
		let def = syms.add("def")
		let x = syms.insert("x")
		let intSet = syms.insert("int_set")
		let symbolSet = syms.insert("symbol_set")
		let stringSet = syms.insert("string_set")
		let test = syms.add("test")
		let hello = syms.add("hello")
		let aaa = syms.add("zzz")
		
		w.addFact(fact(x, [abc, int(0), test]))
		w.addFact(fact(x, [def, int(2), hello]))
		
		let res = w.queryRule(expressedRule(
			intSet,
			[`var`(&syms, "sym"), `var`(&syms, "str")],
			[pred(x, [`var`(&syms, "sym"), `var`(&syms, "int"), `var`(&syms, "str")])],
			[
				Expression(ops: [
					.value(.set([.integer(0), .integer(1)])),
					.value(`var`(&syms, "int")),
					.binary(.contains),
				]),
			]
		), symbols: syms)
		
		for fact in res {
			print("\t\(syms.printFact(fact))")
		}
		
		let expected = Set([fact(intSet, [abc, test])])
		XCTAssertEqual(expected, Set(res))
		
		let abcSymId = syms.add("abc")
		let ghiSymId = syms.add("ghi")
		
		do {
			let res = w.queryRule(expressedRule(
				symbolSet,
				[`var`(&syms, "symbol"), `var`(&syms, "int"), `var`(&syms, "str")],
				[pred(x, [`var`(&syms, "symbol"), `var`(&syms, "int"), `var`(&syms, "str")])],
				[
					Expression(ops: [
						.value(.set([abcSymId, ghiSymId])),
						.value(`var`(&syms, "symbol")),
						.binary(.contains),
						.unary(.negate),
					]),
				]
			), symbols: syms)
			
			for fact in res {
				print("\t\(syms.printFact(fact))")
			}
			
			let expected = Set([fact(symbolSet, [def, int(2), hello])])
			XCTAssertEqual(expected, Set(res))
		}
		
		do {
			let res = w.queryRule(expressedRule(
				stringSet,
				[`var`(&syms, "sym"), `var`(&syms, "int"), `var`(&syms, "str")],
				[pred(x, [`var`(&syms, "sym"), `var`(&syms, "int"), `var`(&syms, "str")])],
				[
					Expression(ops: [
						.value(.set([test, aaa])),
						.value(`var`(&syms, "str")),
						.binary(.contains),
					]),
				]
			), symbols: syms)
			for fact in res {
				print("\t\(syms.printFact(fact))")
			}
			
			let expected = Set([fact(stringSet, [abc, int(0), test])])
			XCTAssertEqual(expected, Set(res))
		}
	}
	
	func testResource() {
		var w = World.empty
		var syms = SymbolTable()
		
		let resource = syms.insert("resource")
		let operation = syms.insert("operation")
		let right = syms.insert("right")
		let file1 = syms.add("file1")
		let file2 = syms.add("file2")
		let read = syms.add("read")
		let write = syms.add("write")
		let check1 = syms.insert("check1")
		let check2 = syms.insert("check2")
		
		w.addFact(fact(resource, [file2]))
		w.addFact(fact(operation, [write]))
		w.addFact(fact(right, [file1, read]))
		w.addFact(fact(right, [file2, read]))
		w.addFact(fact(right, [file1, write]))
		
		do {
			let res = w.queryRule(rule(
				check1,
				[file1],
				[pred(resource, [file1])]
			), symbols: syms)
			
			for fact in res {
				print("\t{}", syms.printFact(fact))
			}
			
			XCTAssert(res.isEmpty)
		}
		
		do {
			let res = w.queryRule(rule(
				check2,
				[.variable(0)],
				[
					pred(resource, [.variable(0)]),
					pred(operation, [read]),
					pred(right, [.variable(0), read]),
				]
			), symbols: syms)
			
			for fact in res {
				print("\t\(syms.printFact(fact))")
			}
			
			XCTAssert(res.isEmpty)
		}
	}
	
	func testIntExpr() {
		var w = World.empty
		var syms = SymbolTable()
		
		let abc = syms.add("abc")
		let def = syms.add("def")
		let x = syms.insert("x")
		let lessThan = syms.insert("less_than")
		
		w.addFact(fact(x, [int(-2), abc]))
		w.addFact(fact(x, [int(0), def]))
		
		let r1 = expressedRule(
			lessThan,
			[`var`(&syms, "nb"), `var`(&syms, "val")],
			[pred(x, [`var`(&syms, "nb"), `var`(&syms, "val")])],
			[
				Expression(ops: [
					.value(.integer(5)),
					.value(.integer(-4)),
					.binary(.add),
					.value(.integer(-1)),
					.binary(.mul),
					.value(`var`(&syms, "nb")),
					.binary(.lessThan),
				]),
			]
		)
		
		print("world:\n\(syms.printWorld(w))\n")
		print("\ntesting r1: \(syms.printRule(r1))\n")
		let res = w.queryRule(r1, symbols: syms)
		for fact in res {
			print("\t\(syms.printFact(fact))")
		}
		
		print("got res: \(Set(res))")
		let expected = Set([fact(lessThan, [int(0), def])])
		XCTAssertEqual(expected, Set(res))
	}
	
}

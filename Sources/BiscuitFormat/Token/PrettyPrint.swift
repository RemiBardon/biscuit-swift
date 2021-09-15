//
//  PrettyPrint.swift
//  Biscuit
//
//  Created by Rémi Bardon on 15/09/2021.
//

import Foundation
import BiscuitDatalog

extension Biscuit {
	
	/// Pretty printer for this token
	public var prettyPrinted: String {
		let authority = prettyPrint(block: self.authority, symbolTable: self.symbols)
		let blocks = self.blocks.map { prettyPrint(block: $0, symbolTable: self.symbols) }
		
		return """
		Biscuit {{
			symbols: \(self.symbols.symbols),
			authority: \(authority),
			blocks: \(indented(prettyArray(blocks)))
		}}
		"""
	}
	
}

extension Verifier {
	
	/// Print the content of the verifier
	public func printWorld() -> String {
		var facts = self.world.facts.map(self.symbols.printFact)
		facts.sort()
		
		var rules = self.world.rules.map(self.symbols.printRule)
		rules.sort()
		
		var checks = [String]()
		for (index, check) in self.checks.enumerated() {
			checks.append("Verifier[\(index)]: \(check)")
		}
		
		for (i, blockChecks) in self.tokenChecks.enumerated() {
			for (j, check) in blockChecks.enumerated() {
				checks.append("Block[\(i)][\(j)]: \(self.symbols.printCheck(check))")
			}
		}
		
		var policies = [String]()
		for policy in self.policies {
			policies.append(String(describing: policy))
		}
		
		return """
		World {{
			facts: \(indented(prettyArray(facts)))
			rules: \(indented(prettyArray(rules)))
			checks: \(indented(prettyArray(checks)))
			policies: \(indented(prettyArray(policies)))
		}}
		"""
	}
	
}

private func prettyArray(_ array: [String]) -> String {
	if array.isEmpty {
		return "[]"
	} else {
		return """
		[
			\(array.joined(separator: ",\n\t"))
		]
		"""
	}
}

private func indented(_ string: String) -> String {
	return string.replacingOccurrences(of: "\n", with: "\n\t")
}

private func prettyPrint(block: Token_Block, symbolTable: SymbolTable) -> String {
	let facts = prettyArray(block.facts.map(symbolTable.printFact))
	let rules = prettyArray(block.rules.map(symbolTable.printRule))
	let checks = prettyArray(block.checks.map(symbolTable.printCheck))
	
	return """
	Block {{
		symbols: \(block.symbols.symbols),
		version: \(block.version),
		context: \(block.context ?? "\"\""),
		facts: \(indented(facts)),
		rules: \(indented(rules)),
		checks: \(indented(checks))
	}}
	"""
}

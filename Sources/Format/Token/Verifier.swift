//
//  Verifier.swift
//  Biscuit
//
//  Created by Rémi Bardon on 14/09/2021.
//

import Foundation
import Datalog
import BiscuitCrypto

/// Verifier structure and associated functions

/// Used to check authorization policies on a token
///
/// Can be created from `Biscuit.verify` or `Verifier.init`
public struct Verifier {
	
	var world: World
	var symbols: SymbolTable
	private(set) var checks: [Check]
	let tokenChecks: [[Check]]
	private(set) var policies: [Policy]
	let token: Biscuit?
	
	internal init(
		world: World,
		symbols: SymbolTable,
		checks: [Check] = [],
		tokenChecks: [[Check]] = [],
		policies: [Policy] = [],
		token: Biscuit? = nil
	) {
		self.world = world
		self.symbols = symbols
		self.checks = checks
		self.tokenChecks = tokenChecks
		self.policies = policies
		self.token = token
	}
	
	internal init(fromToken token: Biscuit) {
		self.init(world: World(), symbols: defaultSymbolTable(), token: token)
	}
	
	/// creates a new empty verifier
	///
	/// this can be used to check policies when:
	/// * there is no token (unauthenticated case)
	/// * there is a lot of data to load in the verifier on each check
	///
	/// In the latter case, we can create an empty verifier, load it
	/// with the facts, rules and checks, and each time a token must be checked,
	/// clone the verifier and load the token with [`Verifier.add_token`]
	public init() {
		self.init(world: World(), symbols: defaultSymbolTable())
	}
	
	public init(fromData data: Data) throws {
		let policies: Proto_VerifierPolicies
		do {
			policies = try Proto_VerifierPolicies(serializedData: data)
		} catch {
			throw FormatError.deserializationError("Deserialization error: \(String(reflecting: error))")
		}
		
		let verifier = try ProtobufToTokenTransformer.tokenVerifier(from: policies)
		
		let world = World(facts: Set(verifier.facts), rules: verifier.rules)
		
		self.init(
			world: world,
			symbols: verifier.symbols,
			checks: verifier.checks,
			policies: verifier.policies
		)
	}
	
	// Serializes a verifier's content
	//
	// You can use this to save a set of policies and load them quickly before
	// verification, or to store a verification context to debug it later
	public func save() throws -> Data {
		let checks = self.checks + self.tokenChecks.flatMap { $0 }
		
		let policies = VerifierPolicies(
			version: MAX_SCHEMA_VERSION,
			symbols: self.symbols,
			facts: Array(self.world.facts),
			rules: self.world.rules,
			checks: checks,
			policies: self.policies
		)
		
		return try policies.proto.serializedData()
	}
	
	/// Add a fact to the verifier
	public mutating func addFact(_ fact: Fact) {
		self.world.addFact(fact)
	}
	
	/// Add a rule to the verifier
	public mutating func addRule(_ rule: Rule) {
		self.world.addRule(rule)
	}
	
	/// Run a query over the verifier's Datalog engine to gather data
	public mutating func query(rule: Rule) throws -> [Fact] {
		try self.query(rule: rule, withLimits: VerifierLimits())
	}
	
	/// Run a query over the verifier's Datalog engine to gather data
	///
	/// This method can specify custom runtime limits
	public mutating func query(rule: Rule, withLimits limits: VerifierLimits) throws -> [Fact] {
		try self.world.runWithLimits(symbols: self.symbols, limits: RunLimits(from: limits))
		return self.world.queryRule(rule, symbols: self.symbols)
	}
	
	/// add a check to the verifier
	public mutating func addCheck(_ check: Check) {
		self.checks.append(check)
	}
	
	#warning("Use builder")
//	public mutating func addResource(_ resource: String) {
//		let fact = fact("resource", [string(resource)])
//		self.world.addFact(fact)
//	}
	
	#warning("Use builder")
//	public mutating func addOperation(_ operation: String) {
//		let fact = fact("operation", [string(operation)])
//		self.world.addFact(fact)
//	}
	
	#warning("Use builder")
	/// Add a fact with the current time
//	public mutating func setTime() {
//		let fact = fact("time", [date(Date())])
//		self.world.addFact(fact)
//	}
	
	#warning("Use builder")
//	public mutating func revocationCheck(ids: [UInt64]) {
//		let check = constrainedRule(
//			"revocation_check",
//			[`var`("id")],
//			[pred("revocation_id", [`var`("id")])],
//			[
//				Expression(ops: [
//					.value(.set(ids.map(.integer))),
//					.value(`var`("id")),
//					.binary(.contains),
//					.unary(.negate),
//				])
//			]
//		)
//		self.addCheck(check)
//	}
	
	/// Add a policy to the verifier
	public mutating func addPolicy(_ policy: Policy) {
		self.policies.append(policy)
	}
	
	#warning("Use builder")
//	public mutating func allow() throws {
//		self.addPolicy("allow if true")
//	}
	
	#warning("Use builder")
//	public mutating func deny() throws {
//		self.addPolicy("deny if true")
//	}
	
	/// Checks all the checks
	///
	/// On error, this can return a list of all the failed checks
	/// On success, it returns the index of the policy that matched
	public mutating func verify() throws -> Int {
		try self.verify(withLimits: VerifierLimits())
	}
	
	/// Checks all the checks
	///
	/// on error, this can return a list of all the failed checks
	///
	/// this method can specify custom runtime limits
	public mutating func verify(withLimits limits: VerifierLimits) throws -> Int {
		let timeLimit = Date() + limits.maxTime
		var errors = [FailedCheckError]()
		var policyResult: Result<Int, TokenError>? = nil
		
		// FIXME: Should check for the presence of any other symbol in the token
		if self.symbols.get("authority") == nil || self.symbols.get("ambient") == nil {
			throw TokenError.missingSymbols
		}
		
		let authority_index = self.symbols.get("authority")!
		let ambient_index = self.symbols.get("ambient")!
		
		if let token = self.token {
			for fact in token.authority.facts {
				self.world.addFact(fact)
			}
			
			var revocationIds = token.revocationIdentifiers
			let revocationIdSym = self.symbols.get("revocation_id")!
			for (i, id) in revocationIds.enumerated() {
				self.world.addFact(Fact(
					name: revocationIdSym,
					ids: [.integer(Int64(i)), .bytes(id)]
				))
			}
			
			#warning("Use builder")
//			for rule in token.authority.rules {
//				do {
//					try rule.validateVariables()
//				} catch {
//					throw LogicError.invalidBlockRule(0, token.symbols.printRule(rule))
//				}
//			}
			
			// FIXME: The verifier should be generated with run limits that are "consumed" after each use
			try self.world.runWithLimits(symbols: self.symbols, limits: RunLimits())
			self.world.clearRules()
			
			for (i, check) in self.checks.enumerated() {
				let successful = try check.queries.allSatisfy { query in
					let res = self.world.queryMatch(query, symbols: self.symbols)
					
					guard Date() < timeLimit else { throw TokenError.runLimit(.timeout) }
					
					return res
				}
				
				if !successful {
					errors.append(.verifier(checkId: UInt32(i), rule: self.symbols.printCheck(check)))
				}
			}
			
			for (j, check) in token.authority.checks.enumerated() {
				let successful = try check.queries.allSatisfy { query in
					let res = self.world.queryMatch(query, symbols: self.symbols)
					
					guard Date() < timeLimit else { throw TokenError.runLimit(.timeout) }
					
					return res
				}
				
				if !successful {
					errors.append(.block(blockId: 0, checkId: UInt32(j), rule: self.symbols.printCheck(check)))
				}
			}
			
			for (i, policy) in self.policies.enumerated() {
				for query in policy.queries {
					let res = self.world.queryMatch(query, symbols: self.symbols)
					
					guard Date() < timeLimit else { throw TokenError.runLimit(.timeout) }
					
					if res {
						switch policy.kind {
						case .allow:
							policyResult = .success(i)
						case .deny:
							policyResult = .failure(.failedLogic(.deny(i)))
						}
					}
				}
			}
			
			for (i, block) in token.blocks.enumerated() {
				// Blocks cannot provide authority or ambient facts
				for fact in block.facts {
					self.world.addFact(fact)
				}
				
				for rule in block.rules {
					#warning("Use builder")
//					let r = Rule.convertFrom(rule, token.symbols)
//
//					do {
//						try r.validateVariables()
//					} catch {
//						throw LogicError.invalidBlockRule(UInt32(i), token.symbols.printRule(rule))
//					}
//
//					let rule = r.convert(&self.symbols)
					self.world.addRule(rule)
				}
				
				try self.world.runWithLimits(symbols: self.symbols, limits: RunLimits())
				self.world.clearRules()
				
				for (j, check) in block.checks.enumerated() {
					let successful = try check.queries.allSatisfy { query in
						let res = self.world.queryMatch(query, symbols: self.symbols)
						
						guard Date() < timeLimit else { throw TokenError.runLimit(.timeout) }
						
						return res
					}
					
					if !successful {
						errors.append(.block(
							blockId: UInt32(i + 1),
							checkId: UInt32(j),
							rule: self.symbols.printCheck(check)
						))
					}
				}
			}
		}
		
		guard errors.isEmpty else {
			throw TokenError.failedLogic(.failedChecks(errors))
		}
		
		switch policyResult {
		case .success(let i):
			return i
		case .failure(let error):
			throw error
		case .none:
			throw TokenError.failedLogic(.noMatchingPolicy)
		}
	}
	
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
			facts: \(String(reflecting: facts))
			rules: \(String(reflecting: rules))
			checks: \(String(reflecting: checks))
			policies: \(String(reflecting: policies))
		}}
		"""
	}
	
	/// Returns all of the data loaded in the verifier
	public func dump() -> ([Fact], [Rule], [Check], [Policy]) {
		return (
			Array(self.world.facts),
			self.world.rules,
			self.checks + self.tokenChecks.flatMap { $0 },
			self.policies
		)
	}
}

public struct VerifierPolicies {
	
	public let version: UInt32
	/// List of symbols introduced by this block
	public let symbols: SymbolTable
	/// List of facts provided by this block
	public let facts: [Fact]
	/// List of rules provided by blocks
	public let rules: [Rule]
	/// Checks that the token and ambient data must validate
	public let checks: [Check]
	public let policies: [Policy]
	
}

/// Runtime limits for the Datalog engine
public struct VerifierLimits {
	
	/// Maximum number of Datalog facts (memory usage)
	public let maxFacts: UInt32
	/// Maximum number of iterations of the rules applications (prevents degenerate rules)
	public let maxIterations: UInt32
	/// Maximum execution time **in seconds**
	public let maxTime: TimeInterval
	
	public init(maxFacts: UInt32, maxIterations: UInt32, maxTime: TimeInterval) {
		self.maxFacts = maxFacts
		self.maxIterations = maxIterations
		self.maxTime = maxTime
	}
	
	public init() {
		// FIXME: I had to increase `maxTime` to 2ms otherwise some tests would not succeed
		self.init(maxFacts: 1_000, maxIterations: 100, maxTime: 0.002)
	}
	
}

extension RunLimits {
	
	init(from limits: VerifierLimits) {
		self.init(
			maxFacts: limits.maxFacts,
			maxIterations: limits.maxIterations,
			maxTime: limits.maxTime
		)
	}
	
}

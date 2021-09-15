//
//  Verifier+Protobuf.swift
//  Biscuit
//
//  Created by Rémi Bardon on 15/09/2021.
//

import Foundation
import BiscuitDatalog

extension Verifier {
	
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
	
	/// Serializes a verifier's content
	///
	/// You can use this to save a set of policies and load them quickly before
	/// verification, or to store a verification context to debug it later
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
	
}

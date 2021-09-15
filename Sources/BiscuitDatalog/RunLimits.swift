//
//  RunLimits.swift
//  Biscuit
//
//  Created by Rémi Bardon on 15/09/2021.
//

import Foundation

public struct RunLimits {
	
	/// Maximum number of Datalog facts (memory usage)
	public let maxFacts: UInt32
	/// Maximum number of iterations of the rules applications (prevents degenerate rules)
	public let maxIterations: UInt32
	/// Maximum execution time **in seconds**
	public let maxTime: TimeInterval
	
	// FIXME: I had to increase `maxTime` to 2ms otherwise some tests would not succeed
	public init(
		maxFacts: UInt32 = 1_000,
		maxIterations: UInt32 = 100,
		maxTime: TimeInterval = 0.002
	) {
		self.maxFacts = maxFacts
		self.maxIterations = maxIterations
		self.maxTime = maxTime
	}
	
}

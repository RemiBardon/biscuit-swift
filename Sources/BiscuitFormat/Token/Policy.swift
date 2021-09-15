//
//  Policy.swift
//  Biscuit
//
//  Created by Rémi Bardon on 10/09/2021.
//

import BiscuitDatalog

public enum PolicyKind {

	case allow, deny
	
}

public struct Policy {
	
	public let queries: [Rule]
	public let kind: PolicyKind
	
	internal init(queries: [Rule], kind: PolicyKind) {
		self.queries = queries
		self.kind = kind
	}
	
}

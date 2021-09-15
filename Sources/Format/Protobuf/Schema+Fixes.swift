//
//  Schema+Fixes.swift
//  Schema+Fixes
//
//  Created by Rémi Bardon on 09/09/2021.
//

import Foundation

extension Proto_Biscuit {
	
	var rootKeyId: UInt32? {
		get { self.hasRootKeyID ? self.rootKeyID : nil }
		set {
			if let newValue = newValue {
				self.rootKeyID = newValue
			} else {
				self.clearRootKeyID()
			}
		}
	}
	
}

extension Proto_Block {
	
	var optContext: String? {
		get { return self.hasContext ? self.context : nil }
		set {
			if let context = newValue {
				self.context = context
			} else {
				self.clearContext()
			}
		}
	}
	
}

extension Proto_OpUnary {
	
	var optKind: Kind? {
		get { return self.hasKind ? self.kind : nil }
		set {
			if let kind = newValue {
				self.kind = kind
			} else {
				self.clearKind()
			}
		}
	}
	
}

extension Proto_OpBinary {
	
	var optKind: Kind? {
		get { return self.hasKind ? self.kind : nil }
		set {
			if let kind = newValue {
				self.kind = kind
			} else {
				self.clearKind()
			}
		}
	}
	
}

extension Proto_Policy {
	
	var optKind: Kind? {
		get { return self.hasKind ? self.kind : nil }
		set {
			if let kind = newValue {
				self.kind = kind
			} else {
				self.clearKind()
			}
		}
	}
	
}

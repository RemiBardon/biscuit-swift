//
//  Indirect.swift
//  Datalog
//
//  Created by Rémi Bardon on 07/09/2021.
//

import Foundation

/// Comes from [Using `indirect` modifier for `struct` properties](https://forums.swift.org/t/using-indirect-modifier-for-struct-properties/37600/16)
@propertyWrapper
final class Indirect<Value> {
	
	var value: Value
	
	init(wrappedValue initialValue: Value) {
		value = initialValue
	}
	
	var wrappedValue: Value {
		get { value }
		set { value = newValue }
	}
	
}

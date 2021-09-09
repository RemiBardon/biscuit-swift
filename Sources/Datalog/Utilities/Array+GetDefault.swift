//
//  Array+GetDefault.swift
//  Datalog
//
//  Created by Rémi Bardon on 10/05/2021.
//

import Foundation

extension Array {
	
	/// Safe subscript:
	///
	/// - Parameters:
	///   - index: Index of the element to find.
	///   - default: A default value as a closure. The closure will not be called if `index` is valid.
	/// - Returns: The element if `index` is valid, `default()` otherwise.
	///
	/// # Notes
	///
	/// - Comes from [How to make array access safer using a custom subscript](https://www.hackingwithswift.com/example-code/language/how-to-make-array-access-safer-using-a-custom-subscript)
	///
	/// # Example
	///
	/// ```
	/// let anon1 = names[-1, default: "Anonymous"]
	/// let anon2 = names[1, default: "Anonymous"]
	/// let anon3 = names[556, default: "Anonymous"]
	/// ```
	public subscript(index: Int, default defaultValue: @autoclosure () -> Element) -> Element {
		guard index >= 0, index < endIndex else {
			return defaultValue()
		}
		
		return self[index]
	}
	
}

//
//  Number+CheckedOperations.swift
//  Biscuit
//
//  Created by Rémi Bardon on 10/05/2021.
//

import Foundation

extension FixedWidthInteger {
	func checkedAdd(_ n: Self) -> Self? {
		return self + n
	}
	func checkedSub(_ n: Self) -> Self? {
		return self - n
	}
	func checkedMult(_ n: Self) -> Self? {
		return self * n
	}
	func checkedDiv(_ n: Self) -> Self? {
		return self / n
	}
}

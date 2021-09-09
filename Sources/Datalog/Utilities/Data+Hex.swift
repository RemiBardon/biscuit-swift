//
//  Data+Hex.swift
//  Datalog
//
//  Created by Rémi Bardon on 10/05/2021.
//

import Foundation

extension Data {
	
	struct HexEncodingOptions: OptionSet {
		let rawValue: Int
		static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
	}
	
	/// Comes from [How to convert Data to hex string in swift](https://stackoverflow.com/a/40089462/10967642)
	func hexEncodedString(options: HexEncodingOptions = []) -> String {
		let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
		return self.map { String(format: format, $0) }.joined()
	}
	
}

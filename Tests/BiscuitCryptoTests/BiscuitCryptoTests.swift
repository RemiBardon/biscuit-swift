//
//  BiscuitCryptoTests.swift
//  BiscuitCryptoTests
//
//  Created by Rémi Bardon on 09/09/2021.
//

import XCTest
@testable import BiscuitCrypto

final class DatalogTests: XCTestCase {
	
	func testBasicSignature()throws  {
		let message = Data("hello world".utf8)
#warning("Could not keep same rng seeds in tests")
		let keyPair = KeyPair()
		
		let signature = try keyPair.privateKey.signature(for: message)
		
		XCTAssert(keyPair.publicKey.isValidSignature(signature, for: message))
		XCTAssert(!keyPair.publicKey.isValidSignature(signature, for: Data("AAAA".utf8)))
	}
	
	func testThreeMessages() throws {
		let message1 = Data("hello".utf8)
#warning("Could not keep same rng seeds in tests")
		let keyPair1 = KeyPair()
		let keyPair2 = KeyPair()
		
		let token1 = try Token(keyPair: keyPair1, nextKey: keyPair2, message: message1)
		
		XCTAssertNoThrow(try token1.verify(with: keyPair1.publicKey), "Cannot verify first token")
		
		print("Will derive a second token")
		
		let message2 = Data("world".utf8)
		let keyPair3 = KeyPair()
		
		let token2 = try token1.append(nextKey: keyPair3, message: message2)
		
		XCTAssertNoThrow(try token2.verify(with: keyPair1.publicKey), "Cannot verify second token")
		
		print("Will derive a third token")
		
		let message3 = Data("!!!".utf8)
		let keyPair4 = KeyPair()
		
		let token3 = try token2.append(nextKey: keyPair4, message: message3)
		
		XCTAssertNoThrow(try token3.verify(with: keyPair1.publicKey), "Cannot verify third token")
	}
	
	func changeMessage() throws {
		let message1 = Data("hello".utf8)
		#warning("Could not keep same rng seeds in tests")
		let keyPair1 = KeyPair()
		let keyPair2 = KeyPair()
		
		let token1 = try Token(keyPair: keyPair1, nextKey: keyPair2, message: message1)
		
		XCTAssertNoThrow(try token1.verify(with: keyPair1.publicKey), "Cannot verify first token")
		
		print("will derive a second token")
		
		let message2 = Data("world".utf8)
		let keyPair3 = KeyPair()
		
		var token2 = try token1.append(nextKey: keyPair3, message: message2)
		token2.blocks[1].data = Data("you".utf8)
		
		XCTAssertThrowsError(
			try token2.verify(with: keyPair1.publicKey),
			"Second token should not be valid"
		) { error in
			switch error {
			case SignatureError.invalidSignature:
				break
			default:
				XCTFail("error should be SignatureError.invalidSignature (got \(error))")
			}
		}
		
		print("will derive a third token")
		
		let message3 = Data("!!!".utf8)
		let keyPair4 = KeyPair()
		
		let token3 = try token2.append(nextKey: keyPair4, message: message3)
		
		XCTAssertThrowsError(
			try token3.verify(with: keyPair1.publicKey),
			"Third token should not be valid"
		) { error in
			switch error {
			case SignatureError.invalidSignature:
				break
			default:
				XCTFail("error should be SignatureError.invalidSignature (got \(error))")
			}
		}
	}
	
}

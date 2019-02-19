//
//  ChainTypeTests.swift
//  TokenCoreTests
//
//  Created by James Chen on 2018/05/25.
//  Copyright © 2018 ConsenLabs. All rights reserved.
//

import XCTest
@testable import TokenCore

class ChainTypeTests: XCTestCase {
    func testPrivateKeySource() {
        XCTAssertEqual(ChainType.eth.privateKeyFrom, WalletFrom.privateKey)
        XCTAssertEqual(ChainType.btc.privateKeyFrom, WalletFrom.wif)
        XCTAssertEqual(ChainType.eos.privateKeyFrom, WalletFrom.wif)
    }
}

//
//  WalletMetaTests.swift
//  tokenTests
//
//  Created by James Chen on 2018/02/24.
//  Copyright © 2018 ConsenLabs. All rights reserved.
//

import XCTest
@testable import TokenCore

class WalletMetaTests: XCTestCase {
  func testCreate() {
    let meta = WalletMeta(chain: .btc, from: .privateKey)
    XCTAssertEqual(meta.chain, ChainType.btc)
    XCTAssertEqual(meta.walletFrom, WalletFrom.privateKey)
    XCTAssertEqual(meta.network, Network.mainnet)
  }

  func testIsMainnet() {
    XCTAssert(WalletMeta(from: .privateKey).isMainnet)
    XCTAssertFalse(WalletMeta(chain: .btc, from: .privateKey, network: .testnet).isMainnet)
  }

  func testMerge() {
    var meta = WalletMeta(chain: .btc, from: .privateKey)
//    let new = meta.mergeMeta("Second wallet", chainType: .eth)
//    XCTAssertEqual(new.chain, ChainType.eth)
  //todo implement tests
  }
}

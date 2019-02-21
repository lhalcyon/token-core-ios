//
// Created by lhalcyon on 2019-02-21.
// Copyright (c) 2019 imToken PTE. LTD. All rights reserved.
//

import XCTest
@testable import TokenCore

class IdentityTests: TestCase {

    func testCreateIdentity() {
        do {
            let mnemonicAndIdentity = try Identity.createIdentity(password: SampleKey.password, metadata: SampleKey.walletMeta)

            let mnemonic = mnemonicAndIdentity.0
            let identity = mnemonicAndIdentity.1

            print("mnemonic:\(mnemonic)")
            XCTAssertEqual(identity.keystore.wallets.count, 2, "Should has two wallets")
            XCTAssertEqual(identity.keystore.wallets[0].metadata.chain, ChainType.eth, "First wallet should be ethereum")
            XCTAssertEqual(identity.keystore.wallets[1].metadata.chain, ChainType.btc, "Second wallet should be Bitcoin")
            XCTAssertEqual(identity.keystore.wallets[1].metadata.network, .testnet, "Bitcoin wallet shoud be in testnet")
            let btcAddress: String = identity.bitcoinWallet.address
            let ethAddress: String = identity.ethereumWallet.address
            // check data below on https://iancoleman.io/bip39/#english
            print("btcAddress:\(btcAddress)")
            print("ethAddress:\(ethAddress)")
        } catch {
            print("create Identity fail , \(error)")
            XCTFail("create Identity fail!")
        }
    }

    func testRecoverIdentity() {
        do {
            let identity = try Identity.recoverIdentity(metadata: SampleKey.walletMeta, mnemonic: SampleKey.mnemonic, password: SampleKey.password)

            XCTAssertEqual(try identity.export(password: SampleKey.password), SampleKey.mnemonic,"Should be \(SampleKey.mnemonic)")
            XCTAssertEqual(identity.bitcoinWallet.address, SampleKey.mainBitcoinTestnetAddress,"Should be \(SampleKey.mainBitcoinTestnetAddress)")
            XCTAssertEqual(identity.ethereumWallet.address, SampleKey.mainEthereumAddress,"Should be \(SampleKey.mainEthereumAddress)")
        } catch {
            print("error: \(error)")
            XCTFail("recover Identity fail!")
        }
    }

    func testExportMnemonic(){
        do {
            let identity = try Identity.recoverIdentity(metadata: SampleKey.walletMeta, mnemonic: SampleKey.mnemonic, password: SampleKey.password)
            let mnemonic = try identity.export(password: SampleKey.password)
            XCTAssertEqual(mnemonic, SampleKey.mnemonic,"Should be \(mnemonic)")
        } catch {
            XCTFail("export mnemonic fail!")
        }
    }

    func testVerifyPassword(){
        do {
            let identity = try Identity.recoverIdentity(metadata: SampleKey.walletMeta, mnemonic: SampleKey.mnemonic, password: SampleKey.password)
            let verify: Bool = identity.keystore.verify(password: SampleKey.password)
            XCTAssertEqual(verify, true)
        } catch {
            XCTFail("export mnemonic fail!")
        }
    }
}
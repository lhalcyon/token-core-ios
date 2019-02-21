//
// Created by lhalcyon on 2019-02-21.
// Copyright (c) 2019 imToken PTE. LTD. All rights reserved.
//

import XCTest
@testable import TokenCore

class BitcoinWalletTests: TestCase {

    func testCreateHDWallet() {
        do {
            let identityAndMnemonic = try Identity.createIdentity(password: SampleKey.password, metadata: SampleKey.walletMeta)
            let identity: Identity = identityAndMnemonic.1

            let address: String = identity.bitcoinWallet.address
            XCTAssertEqual(address, SampleKey.mainBitcoinTestnetAddress)
        } catch {
            XCTFail("error:\(error)")
        }
    }

    func testRecoverHDWallet() {
        do {
            let identity = try Identity.recoverIdentity(metadata: SampleKey.walletMeta, mnemonic: SampleKey.mnemonic, password: SampleKey.password)
            let wallet: BasicWallet = identity.bitcoinWallet

            let address: String = identity.bitcoinWallet.address
            XCTAssertEqual(address, SampleKey.mainBitcoinTestnetAddress)
        } catch {
            XCTFail("error:\(error)")
        }
    }

    func testExportMnemonic() {
        do {
            let identity = try Identity.recoverIdentity(metadata: SampleKey.walletMeta, mnemonic: SampleKey.mnemonic, password: SampleKey.password)
            let wallet: BasicWallet = identity.bitcoinWallet

            let mnemonic: String = try wallet.exportMnemonic(password: SampleKey.password)
            XCTAssertEqual(mnemonic, SampleKey.mnemonic)
        } catch {
            XCTFail("error:\(error)")
        }
    }

    func testVerifyPassword() {
        do {
            let identity = try Identity.recoverIdentity(metadata: SampleKey.walletMeta, mnemonic: SampleKey.mnemonic, password: SampleKey.password)
            let wallet: BasicWallet = identity.bitcoinWallet

            let verify: Bool = wallet.keystore.verify(password: SampleKey.password)
            XCTAssertEqual(verify, true)
        } catch {
            XCTFail("error:\(error)")
        }
    }
    
    
    func testKeystore2Json(){
        do {
            let identity = try Identity.recoverIdentity(metadata: SampleKey.walletMeta, mnemonic: SampleKey.mnemonic, password: SampleKey.password)
            let wallet: BasicWallet = identity.bitcoinWallet
            let keystore: String = wallet.keystore.dump()
            print(keystore)
        } catch {
            XCTFail("error:\(error)")
        } 
    }

    func testExportPrivateKey(){
        do {
            let identity = try Identity.recoverIdentity(metadata: SampleKey.walletMeta, mnemonic: SampleKey.mnemonic, password: SampleKey.password)
            let wallet: BasicWallet = identity.bitcoinWallet
            let privateKey: String = try wallet.privateKey(password: SampleKey.password)
            print("privateKey:\(privateKey)")
            XCTAssertEqual(privateKey, SampleKey.wif)
        } catch {
            XCTFail("error:\(error)")
        }
    }


    func testImportPrivateKey() {
        do {
            let wallet = try BasicWallet.importFromPrivateKey(SampleKey.wif, encryptedBy: SampleKey.password, metadata: SampleKey.walletMeta)
            print("wallet metadata:\(wallet.metadata)")
            XCTAssertEqual(wallet.address, SampleKey.mainBitcoinTestnetAddress)
        } catch {
            XCTFail("error:\(error)")
        }
    }

    func testExportWif() {
        do {
            let wallet = try BasicWallet.importFromPrivateKey(SampleKey.wif, encryptedBy: SampleKey.password, metadata: SampleKey.walletMeta)
            let wif: String = try wallet.privateKey(password: SampleKey.password)
            XCTAssertEqual(wif, SampleKey.wif)
        } catch {
            XCTFail("error:\(error)")
        }
    }
    
}

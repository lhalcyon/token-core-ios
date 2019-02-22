//
// Created by lhalcyon on 2019-02-22.
// Copyright (c) 2019 imToken PTE. LTD. All rights reserved.
//

import XCTest
@testable import TokenCore

class BitcoinTransactionTests: TestCase {

    func testSign() {
        do {
            let amount : Int64 = 9000
            let fee : Int64 = 7000
            let to = "n4QyHicAPpidqHRtgr9MsaKqhMqq1kEDLn"
            let mnemonic = "hurt certain dash ankle cricket exist winner jelly dizzy diary embody radar"
            let identity = try Identity.recoverIdentity(metadata: SampleKey.walletMeta, mnemonic: mnemonic, password: SampleKey.password)
            let wallet: BasicWallet = identity.bitcoinWallet
            let outputs: [[String: Any]] = [
                [
                    "txHash": "2301b40a6f8d6de8b7f2dbea987748a8c02275ca209ad6c80426283e6260824c",
                    "vout": 0,
                    "amount": "5000",
                    "address": "ms9kSTDE9UPyCYN9j7nzcZyfLCCc6CK3Fx",
                    "scriptPubKey": "a91480b7abac1f5c44d45c76fb2a43a0a2f062bd8cd887",
                    "derivedPath": "0/0"
                ],
                [
                    "txHash": "7d082237e2cfa5ebe5323cee85a645a4956d4c15eb110329115570d660bece6a",
                    "vout": 0,
                    "amount": "5000",
                    "address": "ms9kSTDE9UPyCYN9j7nzcZyfLCCc6CK3Fx",
                    "scriptPubKey": "a91480b7abac1f5c44d45c76fb2a43a0a2f062bd8cd887",
                    "derivedPath": "0/0"
                ]
            ]
            let transaction = try WalletManager.btcSignTransaction(
                    wallet: wallet, to: to, amount: amount,
                    fee: fee, password: SampleKey.password, outputs: outputs, changeIdx: 0,
                    isTestnet: true, segWit: SegWit.none,isExternal: true)
            let signedTx: String = transaction.signedTx
            let txHash: String = transaction.txHash
            print("signedTx:\(signedTx)")
            print("txHash:\(txHash)")
            XCTAssertEqual(txHash, "3315032025bb05c1ce2ab5a8b55c5af2112084872199d69722e926feb11ec94f")
            XCTAssertEqual(signedTx,
                    "01000000024c8260623e282604c8d69a20ca7522c0a8487798eadbf2b7e86d8d6f0ab40123000000006b483045022100a7ba235b47258ebff6a45b2a50c18ea466645669ed1d4a1460abae4bf044138902206c945ed52fa865e9da52129b8e8632ca18389e22c1598b030c3568f32acf70a8012102ce52520652ca5b04aed0808a5d301c749f21a304885d11663f89859f9509f6eeffffffff6acebe60d6705511290311eb154c6d95a445a685ee3c32e5eba5cfe23722087d000000006a473044022016e45757d63bcf72fdb4760b98d47851ae977997eb629c2df823311aa91c8a1e0220125351ef2db933b7ea46aac886c8fc4c442ca092d49ef9872e6d4f03b5917064012102ce52520652ca5b04aed0808a5d301c749f21a304885d11663f89859f9509f6eeffffffff0128230000000000001976a914fb293a287ddcb136d5d2c86cd203feba5b58689e88ac00000000")
        } catch {
            XCTFail("error:\(error)")
        }
    }
}

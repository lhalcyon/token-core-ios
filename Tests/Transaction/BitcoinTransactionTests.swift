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
                    "txHash": "b438a3bb883e3108acb20f9f598341523a6d06f01ed955e98cd5c8dfd47bb53e",
                    "vout": 0,
                    "amount": "19878926",
                    "address": "ms9kSTDE9UPyCYN9j7nzcZyfLCCc6CK3Fx",
                    "scriptPubKey": "76a9147f9ee0c3ecb167027680c975ba2d4e161430afa688ac",
                    "derivedPath": "0/0"
                ],
                [
                    "txHash": "402829fc7f932834ee6c59c23d522755d922d29ab0dc85d15a068aabf606f507",
                    "vout": 0,
                    "amount": "17628860",
                    "address": "ms9kSTDE9UPyCYN9j7nzcZyfLCCc6CK3Fx",
                    "scriptPubKey": "76a9147f9ee0c3ecb167027680c975ba2d4e161430afa688ac",
                    "derivedPath": "0/0"
                ]
            ]
            let transaction = try WalletManager.btcSignTransaction(
                    wallet: wallet, to: to, amount: amount,
                    fee: fee, password: SampleKey.password, outputs: outputs, changeIdx: 0, isExternal: true)
            let signedTx: String = transaction.signedTx
            let txHash: String = transaction.txHash
            print("signedTx:\(signedTx)")
            print("txHash:\(txHash)" )
            XCTAssertEqual(txHash, "812a91ad0a53ac635f630e864cfe91cd60bd92739dddc8f7f93b86702ed64580")
            XCTAssertEqual(signedTx,
                    "01000000023eb57bd4dfc8d58ce955d91ef0066d3a524183599f0fb2ac08313e88bba338b4000000006a473044022018a196c2a714262259ff923d6f0ee6a2d0381b356fa45ce46ef4b0bfcae68b46022003cc5b1f7290aa7e5bc8781e814d67bfbbc679bd3554c34d4dc14d5dee9956c9012102ce52520652ca5b04aed0808a5d301c749f21a304885d11663f89859f9509f6eeffffffff07f506f6ab8a065ad185dcb09ad222d95527523dc2596cee3428937ffc292840000000006a47304402201fe0c63693303917a65262b921525fcca9387914148ec22a4ad992a0908c475502202ce46618bd4a361b2af7f1da973188e4b7fbe5cebb863e258bfd4c709e7c6f76012102ce52520652ca5b04aed0808a5d301c749f21a304885d11663f89859f9509f6eeffffffff0228230000000000001976a914fb293a287ddcb136d5d2c86cd203feba5b58689e88ac4a143c02000000001976a9147f9ee0c3ecb167027680c975ba2d4e161430afa688ac00000000")
        } catch {
            XCTFail("error:\(error)")
        }
    }
}

//
// Created by lhalcyon on 2019-02-22.
// Copyright (c) 2019 imToken PTE. LTD. All rights reserved.
//

import XCTest
@testable import TokenCore

class USDTTransactionTests : TestCase{


    func testPayload(){
        let payload = USDTUtil.getUSDTPayload(propertyId: 1, amountInSatoshi: 10000)
        print(payload)
        XCTAssertEqual(payload, "6a146f6d6e6900000000000000010000000000002710")
    }

    func testSign(){
        do {

            let fee : Int64 = 7000
            let amount : Int64 = 100000000
            let payload = USDTUtil.getUSDTPayload(propertyId: 1, amountInSatoshi: amount)
            print("payload:\(payload)")
            let to = "n4QyHicAPpidqHRtgr9MsaKqhMqq1kEDLn"
            let identity = try Identity.recoverIdentity(metadata: SampleKey.walletMeta, mnemonic: SampleKey.mnemonic, password: SampleKey.password)
            let wallet: BasicWallet = identity.bitcoinWallet
            let threshold:Int64 = 546
            let outputs: [[String: Any]] = [
                [
                    "txHash": "62b52eb657004cf9063c05b7b5ad3a21fa00851684dcd05d9e0efc35e0945e15",
                    "vout": 1,
                    "amount": "13855013",
                    "address": "myVftRaBb8Vy3upWaL8TueAhDE2QAsQy1h",
                    "scriptPubKey": "76a914c53426e51be95dad76937f064af20f8a52cda42688ac",
                    "derivedPath": "0/0"
                ],
                [
                    "txHash": "52c299ff4857b7713d1607e6e27a57f75645d3438d22c29d1043566bbdc3d300",
                    "vout": 1,
                    "amount": "9303353",
                    "address": "myVftRaBb8Vy3upWaL8TueAhDE2QAsQy1h",
                    "scriptPubKey": "76a914c53426e51be95dad76937f064af20f8a52cda42688ac",
                    "derivedPath": "0/0"
                ]
            ]
            let transaction = try WalletManager.usdtSignTransaction(
                    wallet: wallet, to: to, amount: threshold,
                    fee: fee, password: SampleKey.password,
                    outputs: outputs, changeIdx: 0,isExternal: true, usdtHex: payload
            )
            let signedTx: String = transaction.signedTx
            let txHash: String = transaction.txHash
            print("signedTx:\(signedTx)")
            print("txHash:\(txHash)" )
            // broadcast on https://live.blockcypher.com/btc-testnet/pushtx/ , then check the result
            XCTAssertEqual(txHash, "5d97f5c917a8a3bb23f0269d1700769957a1955b18188487344d83e07be00437")
            XCTAssertEqual(signedTx,
                    "0100000002155e94e035fc0e9e5dd0dc84168500fa213aadb5b7053c06f94c0057b62eb562010000006b483045022100973a7d0a418fd421437b22841e2b89e27a14f61225c1682758771036beae67f202206da9b4611bfd5604088e4a6035b7fa56934523f662372975693247af655427680121039a79cc2b21f8e75bd2bbd634693731dc5863b4b6152bb04d2ccb461442ee5259ffffffff00d3c3bd6b5643109dc2228d43d34556f7577ae2e607163d71b75748ff99c252010000006a47304402203cffa35f3c3f80e8219bd38e89e74e278b04de2bf4c94638a20dbb246370f4c8022078bd30c43a25e90bd1b29bd367da02cb9ecb343859d93daf4c5d3184319b90340121039a79cc2b21f8e75bd2bbd634693731dc5863b4b6152bb04d2ccb461442ee5259ffffffff0322020000000000001976a914fb293a287ddcb136d5d2c86cd203feba5b58689e88ace4406101000000001976a914c53426e51be95dad76937f064af20f8a52cda42688ac0000000000000000166a146f6d6e6900000000000000010000000005f5e10000000000")
        } catch {
            XCTFail("error:\(error)")
        }
    }
}

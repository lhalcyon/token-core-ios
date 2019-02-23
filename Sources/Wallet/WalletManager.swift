//
//  WalletManager.swift
//  token
//
//  Created by Kai Chen on 05/09/2017.
//  Copyright © 2017 imToken PTE. LTD. All rights reserved.
//

import Foundation
import CoreBitcoin

public struct WalletManager {
    public static func importFromMnemonic(_ mnemonic: String, metadata: WalletMeta, encryptBy password: String, at path: String) throws -> BasicWallet {
        let identity = try IdentityValidator().validate()
        return try identity.importFromMnemonic(mnemonic, metadata: metadata, encryptBy: password, at: path)
    }

    /**
     Import ETH keystore json to generate wallet

     - parameter keystore: JSON text
     - parameter password: Password of keystore
     - parameter metadata: Wallet metadata
     */
    public static func importFromKeystore(_ keystore: JSONObject, encryptedBy password: String, metadata: WalletMeta) throws -> BasicWallet {
        let identity = try IdentityValidator().validate()
        _ = try V3KeystoreValidator(keystore).validate()
        return try identity.importFromKeystore(keystore, encryptedBy: password, metadata: metadata)
    }


    public static func findWalletByPrivateKey(_ privateKey: String, on chainType: ChainType, network: Network? = nil, segWit: SegWit = .none) throws -> BasicWallet? {
        let identity = try IdentityValidator().validate()
        return try identity.findWalletByPrivateKey(privateKey, on: chainType, network: network, segWit: segWit)
    }

    public static func findWalletByMnemonic(_ mnemonic: String, on chainType: ChainType, path: String, network: Network? = nil, segWit: SegWit = .none) throws -> BasicWallet? {
        let identity = try IdentityValidator().validate()
        return try identity.findWalletByMnemonic(mnemonic, on: chainType, path: path, network: network, segWit: segWit)
    }

    public static func findWalletByKeystore(_ keystore: [String: Any], on chainType: ChainType, password: String) throws -> BasicWallet? {
        let identity = try IdentityValidator().validate()
        return try identity.findWalletByKeystore(keystore, on: chainType, password: password)
    }

    public static func findWalletByWalletID(_ walletID: String) throws -> BasicWallet {
        let identity = try IdentityValidator().validate()
        guard let wallet = identity.findWalletByWalletID(walletID) else {
            throw GenericError.walletNotFound
        }

        return wallet
    }

    public static func findWalletByAddress(_ address: String, on chainType: ChainType) throws -> BasicWallet {
        let identity = try IdentityValidator().validate()
        guard let wallet = identity.findWalletByAddress(address, on: chainType) else {
            throw GenericError.walletNotFound
        }

        return wallet
    }


    /**
     Sign transaction with given parameters

     - returns signed data
     */
    public static func ethSignTransaction(
            wallet: BasicWallet,
            nonce: String,
            gasPrice: String,
            gasLimit: String,
            to: String,
            value: String,
            data: String,
            password: String,
            chainID: Int
    ) throws -> TransactionSignedResult {

        let privateKey = try wallet.privateKey(password: password)

        let raw: [String: String] = [
            "nonce": nonce,
            "gasPrice": gasPrice,
            "gasLimit": gasLimit,
            "to": to,
            "value": value,
            "data": data
        ]
        let tx = ETHTransaction(raw: raw, chainID: chainID)
        _ = tx.sign(with: privateKey)

        return tx.signedResult
    }

    public static func btcSignTransaction(
            wallet: BasicWallet,
            to: String,
            amount: Int64,
            fee: Int64,
            password: String,
            outputs: [[String: Any]],
            changeIdx: Int,
            isExternal: Bool = false,
            usdtHex:String? = nil
    ) throws -> TransactionSignedResult {

        let isTestnet = !wallet.metadata.isMainnet
        let segWit = wallet.metadata.segWit

        guard let toAddress = BTCAddress(string: to) else {
            throw AddressError.invalid
        }

        let utxos: [UTXO] = try outputs.map { output in
            guard let utxo = UTXO(raw: output) else {
                throw GenericError.paramError
            }
            return utxo
        }

        let changeKey: BTCKey
        let privateKeys: [BTCKey]

        if wallet.metadata.walletFrom == .wif {
            let wif = try wallet.privateKey(password: password)
            changeKey = BTCKey(wif: wif)
            privateKeys = Array(repeating: changeKey, count: outputs.count)
        } else {
            let extendedKey = try wallet.privateKey(password: password)
            guard let keychain = BTCKeychain(extendedKey: extendedKey),
                  let key = isExternal ? keychain.externalKey(at: UInt32(changeIdx)) : keychain.changeKey(at: UInt32(changeIdx)) else {
                throw GenericError.unknownError
            }
            changeKey = key
            privateKeys = utxos.map { output in
                let pathWithSlash = "/\(output.derivedPath ?? "")"
                let key = keychain.key(withPath: pathWithSlash)!
                key.isPublicKeyCompressed = true
                return key
            }
        }

        let changeAddress = changeKey.address(on: isTestnet ? .testnet : .mainnet, segWit: segWit)
        let signer = try BTCTransactionSigner(utxos: utxos, keys: privateKeys, amount: amount, fee: fee, toAddress: toAddress, changeAddress: changeAddress)

        if segWit.isSegWit {
            return try signer.signSegWit()
        } else {
            return try signer.sign(usdtHex)
        }
    }

    public static func usdtSignTransaction(
            wallet: BasicWallet,
            to: String,
            amount: Int64,
            fee: Int64,
            password: String,
            outputs: [[String: Any]],
            changeIdx: Int,
            isExternal: Bool = false,
            usdtHex:String? = nil
    ) throws -> TransactionSignedResult {
        return try btcSignTransaction(wallet: wallet, to: to, amount: amount, fee: fee, password: password, outputs: outputs, changeIdx: changeIdx,isExternal: isExternal,usdtHex: usdtHex)
    }

    /// Allow BTC wallet to switch between legacy/SegWit.
    public static func switchBTCWalletMode(walletID: String, password: String, segWit: SegWit) throws -> BasicWallet {
        let wallet = try findWalletByWalletID(walletID)

        if wallet.metadata.chain != .btc {
            throw GenericError.operationUnsupported
        }

        if wallet.metadata.segWit == segWit {
            return wallet
        }

        let newKeystore: Keystore
        var metadata = wallet.metadata
        metadata.segWit = segWit
        let path = BIP44.path(for: metadata.network, segWit: segWit)

        if let mnemonicKeystore = wallet.keystore as? EncMnemonicKeystore {
            guard wallet.keystore.verify(password: password) else {
                throw PasswordError.incorrect
            }
            let mnemonic = mnemonicKeystore.decryptMnemonic(password)

            newKeystore = try BTCMnemonicKeystore(
                    password: password,
                    mnemonic: mnemonic,
                    path: path,
                    metadata: metadata,
                    id: walletID
            )
        } else {
            // private key export already verifies password
            let privateKey = try wallet.privateKey(password: password)
            newKeystore = try BTCKeystore(
                    password: password,
                    wif: privateKey,
                    metadata: metadata,
                    id: walletID
            )
        }
        // check if the new walle will override the wallet derived by identity
//    if Identity.currentIdentity?.findWalletByAddress(newKeystore.address, on: .btc) != nil {
//      throw AddressError.alreadyExist
//    }

        wallet.keystore = newKeystore
        return wallet
    }

    static func calcWif(_ password:String,wallet:BasicWallet) throws -> String {
        // get wallet via mnemonic , then
        let mnemonic: String = try wallet.exportMnemonic(password: password)
        let btcNetwork = wallet.metadata.isMainnet ? BTCNetwork.mainnet() : BTCNetwork.testnet()

        guard let btcMnemonic = BTCMnemonic(words: mnemonic.split(separator: " "), password: "", wordListType: .english),
              let seedData = btcMnemonic.seed else {
            throw MnemonicError.wordInvalid
        }

        let mnemonicPath = wallet.metadata.isMainnet ? BIP44.btcMainnet : BIP44.btcTestnet

        guard let masterKeychain = BTCKeychain(seed: seedData, network: btcNetwork),
              let accountKeychain = masterKeychain.derivedKeychain(withPath: mnemonicPath) else {
            throw GenericError.unknownError
        }
        accountKeychain.network = btcNetwork
        guard let _ = accountKeychain.extendedPrivateKey else {
            throw GenericError.unknownError
        }

//    crypto = Crypto(password: password, privateKey: rootPrivateKey.tk_toHexString(), cacheDerivedKey: true)
//    crypto.clearDerivedKey()
        let indexKey = accountKeychain.derivedKeychain(withPath: "/0/0").key!
        return indexKey.wifTestnet
    }
}

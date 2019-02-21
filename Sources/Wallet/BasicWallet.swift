//
//  BasicWallet.swift
//  token
//
//  Created by Kai Chen on 24/10/2017.
//  Copyright © 2017 ConsenLabs. All rights reserved.
//

import Foundation
import CoreBitcoin

public typealias WalletID = String

public class BasicWallet {
  public var walletID: WalletID
  public var keystore: Keystore
  public let chainType: ChainType?

  /**
 Import private key to generate wallet
 */
  static func importFromPrivateKey(_ privateKey: String, encryptedBy password: String, metadata: WalletMeta, accountName: String? = nil) throws -> BasicWallet {
    let keystore: Keystore
    switch metadata.chain! {
    case .btc:
      keystore = try BTCKeystore(password: password, wif: privateKey, metadata: metadata)
    case .eth:
      keystore = try ETHKeystore(password: password, privateKey: privateKey, metadata: metadata)
    case .eos:
      guard let accountName = accountName, !accountName.isEmpty else {
        throw GenericError.paramError
      }
      keystore = try EOSLegacyKeystore(password: password, wif: privateKey, metadata: metadata, accountName: accountName)
    }
    let wallet = BasicWallet(keystore)
    return wallet
  }


  public init(json: JSONObject) throws {
    do {
      guard
        let version = json["version"] as? Int,
        let meta = json[WalletMeta.key] as? JSONObject,
        let chainTypeStr = meta["chainType"] as? String,
        let chainType = ChainType(rawValue: chainTypeStr),
        let fromStr = meta["from"] as? String,
        let from = WalletFrom(rawValue: fromStr)
      else {
        throw KeystoreError.invalid
      }

      let mnemonicKeystoreSource: [WalletFrom] = [
        .mnemonic,
      ]

      switch version {
      case 3:
        switch chainType {
        case .eth:
          if mnemonicKeystoreSource.contains(from) {
            self.keystore = try ETHMnemonicKeystore(json: json)
          } else {
            self.keystore = try ETHKeystore(json: json)
          }
        case .btc:
          self.keystore = try BTCKeystore(json: json)
        case .eos:
          self.keystore = try EOSLegacyKeystore(json: json)
        }
      case BTCMnemonicKeystore.defaultVersion:
        self.keystore = try BTCMnemonicKeystore(json: json)
      case EOSKeystore.defaultVersion:
        self.keystore = try EOSKeystore(json: json)
      default:
        throw KeystoreError.invalid
      }
      self.chainType = chainType
    } catch {
      throw KeystoreError.invalid
    }
    self.walletID = self.keystore.id
  }

  public init(_ keystore: Keystore) {
    self.walletID = keystore.id
    self.keystore = keystore
    chainType = keystore.meta.chain
  }

  public var address: String {
    return keystore.address
  }

  public var metadata: WalletMeta {
    return keystore.meta
  }
}

public extension BasicWallet {
  
  func exportMnemonic(password: String) throws -> String {
    guard let mnemonicKeystore = self.keystore as? EncMnemonicKeystore else {
      throw GenericError.operationUnsupported
    }

    guard keystore.verify(password: password) else {
      throw PasswordError.incorrect
    }

    return mnemonicKeystore.decryptMnemonic(password)
  }

  func export() -> String {
    if let exportableKeystore = keystore as? ExportableKeystore {
      return exportableKeystore.export()
    }
    return ""
  }

  public func privateKey(password: String) throws -> String {
    guard keystore.verify(password: password) else {
      throw PasswordError.incorrect
    }

    if let pkKestore = keystore as? PrivateKeyCrypto {
      return pkKestore.decryptPrivateKey(password)
    } else if let wifKeystore = keystore as? WIFCrypto {
      return wifKeystore.decryptWIF(password)
    } else if let xprvKeystore = keystore as? XPrvCrypto {
      if metadata.walletFrom == .mnemonic && metadata.chain == .btc {
        // HD bitcoin wallet export wif
        return try calcWif(password)
      }
      return xprvKeystore.decryptXPrv(password)
    } else {
      throw GenericError.operationUnsupported
    }
  }

  fileprivate func calcWif(_ password:String) throws -> String {
    // get wallet via mnemonic , then
    let mnemonic: String = try self.exportMnemonic(password: password)
    let btcNetwork = metadata.isMainnet ? BTCNetwork.mainnet() : BTCNetwork.testnet()

    guard let btcMnemonic = BTCMnemonic(words: mnemonic.split(separator: " "), password: "", wordListType: .english),
          let seedData = btcMnemonic.seed else {
      throw MnemonicError.wordInvalid
    }

    let mnemonicPath = metadata.isMainnet ? BIP44.btcMainnet : BIP44.btcTestnet

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

  func privateKeys(password: String) throws -> [KeyPair] {
    guard keystore.verify(password: password) else {
      throw PasswordError.incorrect
    }

    if let eosKeystore = keystore as? EOSKeystore {
      return eosKeystore.exportKeyPairs(password)
    } else if let legacyEOSKeystore = keystore as? EOSLegacyKeystore {
      return legacyEOSKeystore.exportPrivateKeys(password)
    } else {
      throw GenericError.operationUnsupported
    }
  }

  func verifyPassword(_ password: String) -> Bool {
    return keystore.verify(password: password)
  }

  func serializeToMap() -> JSONObject {
    return keystore.serializeToMap()
  }

  func calcExternalAddress(at externalIdx: Int) throws -> String {
    guard let hdkeystore = self.keystore as? BTCMnemonicKeystore else {
      throw GenericError.operationUnsupported
    }

    return hdkeystore.calcExternalAddress(at: externalIdx)
  }
}

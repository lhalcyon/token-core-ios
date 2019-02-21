//
//  ExIdentity.swift
//  TokenCore
//
//  Created by lhalcyon on 2019/2/16.
//  Copyright © 2019 imToken PTE. LTD. All rights reserved.
//

import Foundation
import CoreBitcoin

public final class ExIdentity {
  
  public var keystore: IdentityKeystore
  public var identifier: String {
    return keystore.identifier
  }
  public var wallets: [BasicWallet] {
    return keystore.wallets
  }
  
  public var bitcoinWallet : BasicWallet {
    return keystore.wallets[0]
  }
  
  public var ethereumWallet : BasicWallet {
    return keystore.wallets[1]
  }
  init(metadata: WalletMeta, mnemonic: String, password: String) throws {
    keystore = try IdentityKeystore(metadata: metadata, mnemonic: mnemonic, password: password)
    _ = try deriveWallets(for: [.eth, .btc], mnemonic: mnemonic, password: password)
  }
  public init?(json: JSONObject) {
    guard let keystore = try? IdentityKeystore(json: json) else {
      return nil
    }
    self.keystore = keystore
    // TODO implement
//    self.keystore.wallets = Identity.storage.loadWalletByIDs(self.keystore.walletIds)
  }
  public func exportMnemonic(password: String) throws -> String {
    guard keystore.verify(password: password) else {
      throw PasswordError.incorrect
    }
    return try keystore.mnemonic(from: password)
  }
  public func deriveWallets(for chainTypes: [ChainType], password: String) throws -> [BasicWallet] {
    let mnemonic = try exportMnemonic(password: password)
    return try deriveWallets(for: chainTypes, mnemonic: mnemonic, password: password)
  }
}

// MARK: Factory And Storage
public extension ExIdentity {
  
  static func createIdentity(password: String, metadata: WalletMeta) throws -> (String, ExIdentity) {
    let mnemonic = MnemonicUtil.generateMnemonic()
    let identity = try ExIdentity(metadata: metadata, mnemonic: mnemonic, password: password)
    return (mnemonic, identity)
  }
  static func recoverIdentity(metadata: WalletMeta, mnemonic: String, password: String) throws -> ExIdentity {
    let identity = try ExIdentity(metadata: metadata, mnemonic: mnemonic, password: password)
    return identity
  }
}

// MARK: Wallet
extension ExIdentity {
  func append(_ newKeystore: Keystore) throws -> BasicWallet {
    let wallet = BasicWallet(newKeystore)
    keystore.wallets.append(wallet)
    keystore.walletIds.append(wallet.walletID)
    return wallet
  }


  func importFromMnemonic(_ mnemonic: String, metadata: WalletMeta, encryptBy password: String, at path: String) throws -> BasicWallet {
    if path.isEmpty {
      throw MnemonicError.pathInvalid
    }
    let keystore: Keystore
    switch metadata.chain! {
    case .btc:
      keystore = try BTCMnemonicKeystore(password: password, mnemonic: mnemonic, path: path, metadata: metadata)
    case .eth:
      keystore = try ETHMnemonicKeystore(password: password, mnemonic: mnemonic, path: path, metadata: metadata)
    case .eos:
      throw GenericError.operationUnsupported
    }
    return try append(keystore)
  }
  func importEOS(
    from mnemonic: String,
    accountName: String,
    permissions: [EOS.PermissionObject],
    metadata: WalletMeta,
    encryptBy password: String,
    at path: String
    ) throws -> BasicWallet {
    if path.isEmpty {
      throw MnemonicError.pathInvalid
    }
    if metadata.chain != .eos {
      throw GenericError.operationUnsupported
    }
    let keystore = try EOSKeystore(accountName: accountName, password: password, mnemonic: mnemonic, path: path, permissions: permissions, metadata: metadata)
    return try append(keystore)
  }
  func importEOS(
    from privateKeys: [String],
    accountName: String,
    permissions: [EOS.PermissionObject],
    encryptedBy password: String,
    metadata: WalletMeta
    ) throws -> BasicWallet {
    if metadata.chain != .eos {
      throw GenericError.operationUnsupported
    }
    let keystore = try EOSKeystore(accountName: accountName, password: password, privateKeys: privateKeys, permissions: permissions, metadata: metadata)
    return try append(keystore)
  }
  
  /**
   Import ETH keystore json to generate wallet
   
   - parameter keystore: JSON text
   - parameter password: Password of keystore
   - parameter metadata: Wallet metadata
   */
  func importFromKeystore(_ keystore: JSONObject, encryptedBy password: String, metadata: WalletMeta) throws -> BasicWallet {
    var keystore = try ETHKeystore(json: keystore)
    keystore.meta = metadata
    guard keystore.verify(password: password) else {
      throw KeystoreError.macUnmatch
    }
    
    let privateKey = keystore.decryptPrivateKey(password)
    do {
      _ = try PrivateKeyValidator(privateKey, on: .eth).validate()
    } catch let err as AppError {
      if err.message == PrivateKeyError.invalid.rawValue {
        throw KeystoreError.containsInvalidPrivateKey
      } else {
        throw err
      }
    }
    guard ETHKey(privateKey: keystore.decryptPrivateKey(password)).address == keystore.address else {
      throw KeystoreError.privateKeyAddressUnmatch
    }
    
    return try append(keystore)
  }
  
  /**
   Import private key to generate wallet
   */
  func importFromPrivateKey(_ privateKey: String, encryptedBy password: String, metadata: WalletMeta, accountName: String? = nil) throws -> BasicWallet {
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
    return try append(keystore)
  }
  
  func deriveWallets(for chainTypes: [ChainType], mnemonic: String, password: String) throws -> [BasicWallet] {
    return try chainTypes.map { chainType in
      var meta = WalletMeta(chain: chainType, from: keystore.meta.walletFrom)
  
      switch chainType {
      case .eth:
        return try importFromMnemonic(mnemonic, metadata: meta, encryptBy: password, at: BIP44.eth)
      case .btc:
        meta.network = keystore.meta.network
        meta.segWit = keystore.meta.segWit
        return try importFromMnemonic(mnemonic, metadata: meta, encryptBy: password, at: BIP44.path(for: meta.network, segWit: meta.segWit))
      case .eos:
        return try importEOS(from: mnemonic, accountName: "", permissions: [], metadata: meta, encryptBy: password, at: BIP44.eosLedger)
      }
    }
  }

}

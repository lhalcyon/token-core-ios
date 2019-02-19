//
//  WalletMeta+Enums.swift
//  TokenCore
//
//  Created by lhalcyon on 2019/2/19.
//  Copyright © 2019 imToken PTE. LTD. All rights reserved.
//

import Foundation

public enum WalletFrom:String {
  case mnemonic = "MNEMONIC"
  case keystore = "KEYSTORE"
  case privateKey = "PRIAVTE_KEY"
  case wif = "WIF"
  
}

public enum SegWit:String {
  case none = "NONE"
  case p2wpkh = "P2WPKH"
  
  public var isSegWit: Bool {
    return self == .p2wpkh
  }
}

public enum WalletType:String {
  case hd = "HD"
  case random = "RANDOM"
  case v3 = "V3"
}

public enum ChainType: String {
  case eth = "ETHEREUM"
  case btc = "BITCOIN"
  case eos = "EOS"
  
  public var privateKeyFrom: WalletFrom{
    if self == .eth {
      return .privateKey
    }
    return .wif
  }
}

public enum Network: String {
  case mainnet = "MAINNET"
  case testnet = "TESTNET"
  
  var isMainnet: Bool {
    return self == .mainnet
  }
}



//
//  WalletMeta.swift
//  token
//
//  Created by James Chen on 2017/01/03.
//  Copyright © 2017 imToken PTE. LTD. All rights reserved.
//

import Foundation



public struct WalletMeta {
  public static let key = "metadata"

  public var network: Network?
  public var chain: ChainType?
  public let walletFrom: WalletFrom?
  
  public var segWit = SegWit.none

  let timestamp: Double


  public init(from: WalletFrom) {
    self.walletFrom = from
    timestamp = WalletMeta.currentTime
  }

  public init(chain: ChainType, from: WalletFrom?, network: Network? = .mainnet,segwit: SegWit = .none) {
    self.walletFrom = from
    self.chain = chain
    self.network = network
    timestamp = WalletMeta.currentTime
    self.segWit = segwit
  }

  public init(_ map: [AnyHashable: Any], from: WalletFrom? = nil) {
    if let chainStr = map["chainType"] as? String, let chainType = ChainType(rawValue: chainStr) {
      chain = chainType
    }
    if let networkStr = map["network"] as? String, let network = Network(rawValue: networkStr) {
      self.network = network
    }
    if from != nil {
      self.walletFrom = from!
    } else if let fromStr = map["from"] as? String, let from = WalletFrom(rawValue: fromStr) {
      self.walletFrom = from
    } else {
      self.walletFrom = .mnemonic
    }

    if let segWitStr = map["segWit"] as? String, let segWit = SegWit(rawValue: segWitStr) {
      self.segWit = segWit
    }

    timestamp = WalletMeta.currentTime
  }

  public init(json: JSONObject) throws {
    if let from = WalletFrom(rawValue: (json["from"] as? String) ?? "") {
      self.walletFrom = from
    } else {
      self.walletFrom = .mnemonic
    }

    if let timestampString = json["timestamp"] as? String, let timestamp = Double(timestampString) {
      self.timestamp = timestamp
    } else {
      timestamp = WalletMeta.currentTime
    }

    if let chainStr = json["chainType"] as? String,
      let chain = ChainType(rawValue: chainStr) {
      self.chain = chain
    }

    if let networkStr = json["network"] as? String,
      let network = Network(rawValue: networkStr) {
      self.network = network
    }

    if let segWitStr = json["segWit"] as? String, let segWit = SegWit(rawValue: segWitStr) {
      self.segWit = segWit
    }

  }

  func mergeMeta(chainType: ChainType) -> WalletMeta {
    var metadata = self
    metadata.chain = chainType
    return metadata
  }

  func toJSON() -> JSONObject {
    var json: JSONObject = [
      "from": walletFrom?.rawValue ?? "",
      "timestamp": Int(timestamp),
    ]
    if chain != nil {
      json["chainType"] = chain!.rawValue
    }

    if network != nil {
      json["network"] = network!.rawValue
    }

    json["segWit"] = segWit.rawValue
    
    return json
  }
  
  public func toJSONString() -> String {
      let data = try! JSONSerialization.data(withJSONObject: toJSON(), options: [])
      return String(data: data, encoding: .utf8)!
  }

  var isSegWit: Bool {
    return segWit.isSegWit
  }

  var isMainnet: Bool {
    if let network = network {
      return network.isMainnet
    }
    return true
  }

  private static var currentTime: Double {
    return Double(Date().timeIntervalSince1970)
  }
}

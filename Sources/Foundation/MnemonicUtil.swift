//
//  MnemonicUtil.swift
//  token
//
//  Created by xyz on 2018/1/5.
//  Copyright © 2018 ConsenLabs. All rights reserved.
//

import Foundation
import CoreBitcoin

public enum Words:Int {

  case twelve = 128
  case fifteen = 160
  case eighteen = 192
  case twentyOne = 224
  case twentFour = 256
}


// MARK: - function
extension Words {
  
  public func byteLength() -> Int{
    return self.rawValue / 8
  }
  
}

public struct MnemonicUtil {
  static func btcMnemonicFromEngWords(_ words: String) -> BTCMnemonic {
    return BTCMnemonic(words: words.split(separator: " "), password: "", wordListType: BTCMnemonicWordListType.english)!
  }

  public static func generateMnemonic(words:Words = Words.twelve) -> String {
    let entropy = Data.tk_random(of: words.byteLength())
    let words = BTCMnemonic(entropy: entropy, password: "", wordListType: .english).words as! [String]
    return words.joined(separator: " ")
  }
}



//
// Created by lhalcyon on 2019-02-22.
// Copyright (c) 2019 imToken PTE. LTD. All rights reserved.
//

import Foundation

class USDTUtil {

    static func getUSDTPayload(propertyId:Int,amountInSatoshi:Int64) -> String {
        let prefix = "6a146f6d6e69"
        return String.init(format: "\(prefix)%016x%016x", arguments: [propertyId,amountInSatoshi])
    }
}

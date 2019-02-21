//
//  IdentityValidator.swift
//  token
//
//  Created by xyz on 2018/1/6.
//  Copyright © 2018 ConsenLabs. All rights reserved.
//

import Foundation

public struct IdentityValidator: Validator {
    public typealias Result = Identity
    // some wallet api doesn't have identifier
    private let identifier: String?

    private let identity: Identity?


    public init(_ identifier: String? = nil,
                identity: Identity? = nil) {
        self.identifier = identifier
        self.identity = identity
    }

    public var isValid: Bool {
        if let idString = identifier,let id = identity {
            return id.identifier == idString
        }
        return true
    }

    public func validate() throws -> Result {
        if let idString = identifier,let id = identity {
            if idString != id.identifier {
                throw IdentityError.invalidIdentity
            }
        }
        return identity!
    }
}

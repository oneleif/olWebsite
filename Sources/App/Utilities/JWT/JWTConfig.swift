//
//  JWTConfig.swift
//  App
//
//  Created by Arkadiusz Żmudzin on 13/03/2020.
//

import JWT
import Vapor

enum JWTConfig {
    static let signerKey = Environment.get("JWT_SECRET") ?? "notSoSecret"
    static let header = JWTHeader(alg: "HS256", typ: "JWT")
    static let signer = JWTSigner.hs256(key: JWTConfig.signerKey)
    static let expirationTime: TimeInterval = 60 * 60 * 24 // one day in seconds
    static let issuer = IssuerClaim(value: "oneleif-api")
}

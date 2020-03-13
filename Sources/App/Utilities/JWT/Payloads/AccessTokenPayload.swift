//
//  AccessTokenPayload.swift
//  App
//
//  Created by Arkadiusz Żmudzin on 13/03/2020.
//

import JWT

struct AccessTokenPayload: JWTPayload {
    var issuer: IssuerClaim
    var issuedAt: IssuedAtClaim
    var expirationAt: ExpirationClaim
    var userId: User.ID
    
    init(issuedAt: Date = Date(),
         expirationAt: Date = Date().addingTimeInterval(JWTConfig.expirationTime),
         userId: User.ID) {
        self.issuer = JWTConfig.issuer
        self.issuedAt = IssuedAtClaim(value: issuedAt)
        self.expirationAt = ExpirationClaim(value: expirationAt)
        self.userId = userId
    }
    
    func verify(using signer: JWTSigner) throws {
        try self.expirationAt.verifyNotExpired()
    }
}

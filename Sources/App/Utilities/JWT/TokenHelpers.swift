//
//  TokenHelpers.swift
//  App
//
//  Created by Arkadiusz Żmudzin on 13/03/2020.
//

import JWT

class TokenHelpers {
    /// Create payload for Access Token
    fileprivate class func createPayload(from user: User) throws -> AccessTokenPayload {
        guard let id = user.id else {
            throw JWTError.payloadCreation
        }
        
        let value = UUID().uuidString
        return AccessTokenPayload(userId: id, value: value)
    }
    
    /// Create Access Token for user
    class func createAccessToken(from user: User) throws -> String {
        let payload = try TokenHelpers.createPayload(from: user)
        let header = JWTConfig.header
        let signer = JWTConfig.signer
        let jwt = JWT<AccessTokenPayload>(header: header, payload: payload)
        let tokenData = try signer.sign(jwt)
        
        guard let token = String(data: tokenData, encoding: .utf8) else {
            throw JWTError.createJWT
        }
        
        return token
    }
    
    /// Get expiration date of token
    class func expiredDate(of token: String) throws -> Date {
        let receivedJWT = try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
        
        return receivedJWT.payload.expirationAt.value
    }
    
    /// Verify token is valid or not
    class func verifyToken(_ token: String) throws {
        do {
            let _ = try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
        } catch {
            throw JWTError.verificationFailed
        }
    }
    
    /// Get user ID from token
    class func getUserId(fromPayloadOf token: String) throws -> Int {
        return try self.getAccessTokenPayload(of: token).userId
    }
    
    class func getAccessTokenValue(fromPayloadOf token: String) throws -> String {
        return try self.getAccessTokenPayload(of: token).value
    }
    
    private class func getAccessTokenPayload(of token: String) throws -> AccessTokenPayload {
        do {
            let receivedJWT = try JWT<AccessTokenPayload>(from: token, verifiedUsing: JWTConfig.signer)
            return receivedJWT.payload
        } catch {
            throw JWTError.verificationFailed
        }
    }
    
    /// Generate new Refresh Token
    class func createRefreshToken() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ... 40).map { _ in letters.randomElement()! })
    }
}

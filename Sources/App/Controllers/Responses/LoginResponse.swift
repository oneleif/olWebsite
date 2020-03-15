//
//  LoginResponse.swift
//  App
//
//  Created by Arkadiusz Żmudzin on 13/03/2020.
//

import Vapor

struct LoginResponse: Content {
    let token: AccessTokenResponse
    let user: PublicUserResponse
}

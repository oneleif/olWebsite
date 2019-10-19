//
//  ImageUpload.swift
//  App
//
//  Created by Zach Eriksen on 10/19/19.
//

import Vapor

struct ImageUpload: Content {
    var picture: Data
}

struct ImageUploadResponse: Content {
    let fileName: String?
}

extension ImageUpload: Parameter {
    typealias ResolvedParameter = String
    
    static func resolveParameter(_ parameter: String,
                                 on container: Container) throws -> ImageUpload.ResolvedParameter {
        return parameter
    }
}

//
//  ImageController.swift
//  App
//
//  Created by Zach Eriksen on 10/19/19.
//

import Vapor
import Imperial
import Authentication

struct ImageController: RouteCollection {
    let imageFolder = "ProfilePictures/"
    
    func boot(router: Router) throws {
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        
        authSessionRouter.post("uploadImage", use: uploadImageHandler)
        authSessionRouter.get("image", ImageUpload.parameter, use: getImageHandler)
    }
    
    func uploadImageHandler(_ req: Request) throws -> Future<ImageUploadResponse> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content
            .decode(ImageUpload.self)
            .flatMap { imageData in
                let workPath = try req.make(DirectoryConfig.self).workDir
                let name = try "\(user.requireID())-\(UUID().uuidString).jpg"
                let path = workPath + self.imageFolder + name
                FileManager().createFile(atPath: path,
                                         contents: imageData.picture,
                                         attributes: nil)
                
                return Future.map(on: req) { ImageUploadResponse(fileName: name) }
        }
    }
    
    func getImageHandler(_ req: Request) throws -> Future<Response> {
        let imageName = try req.parameters.next(ImageUpload.self)
        
        let path = try req.make(DirectoryConfig.self).workDir + self.imageFolder + imageName
        
        return try req.streamFile(at: path)
    }
}

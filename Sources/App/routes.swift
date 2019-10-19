import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    let usersController = UserController()
    try router.register(collection: usersController)
    
    let imageController = ImageController()
    try router.register(collection: imageController)
    
    let imperialController = ImperialController()
    try router.register(collection: imperialController)
}

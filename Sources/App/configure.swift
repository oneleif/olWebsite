import Vapor
import Authentication
import FluentPostgreSQL

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(AuthenticationProvider())
        
    /// Create default content config
    var contentConfig = ContentConfig.default()

    /// Create custom JSON encoder
    let jsonEncoder = JSONEncoder()
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    jsonEncoder.dateEncodingStrategy = .formatted(formatter)

    /// Register JSON encoder and content config
    contentConfig.use(encoder: jsonEncoder, for: .json)
    
    services.register(contentConfig)
    
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
    middlewares.use(corsMiddleware)
    middlewares.use(SessionsMiddleware.self)
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)

    // Configure a PostgreSQL database
    let config = PostgreSQLDatabaseConfig(hostname: Environment.get("DB_HOST") ?? "localhost", 
                                          port: Int(Environment.get("DB_PORT") ?? "") ?? 5432, 
                                          username: Environment.get("DB_USER") ?? "oneleif", 
                                          database: Environment.get("DB_NAME") ?? "oneleif-\(env.name)", 
                                          password: Environment.get("DB_PASSWORD") ?? "root", 
                                          transport: .cleartext)

    let postgres = PostgreSQLDatabase(config: config)
    
    // Register the configured PostgreSQL database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: postgres, as: .psql)
    services.register(databases)

    
    if env == .testing {
        var commandConfig = CommandConfig()
        commandConfig.useFluentCommands()
        services.register(commandConfig)
    }
    
    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: PostItem.self, database: .psql)
    services.register(migrations)
    
    // Configure validations
    var validatorService = ValidatorService()
    validatorService.skipValidation = env == .development
    services.register(validatorService)
    
    // Configure model services
    let userService = UserService()
    services.register(userService)
    
    services.register(AuthService())
}

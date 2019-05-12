//
//  Express.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016-2019 ZeeZide GmbH. All rights reserved.
//

/**
 * # The Express application object
 *
 * An instance of this object represents an Express application. An Express
 * application is essentially as set of routes, configuration, and templates.
 * Applications are 'mountable' and can be added to other applications.
 *
 * In ApacheExpress you need to use the `ApacheExpress` subclass as the main
 * entry point, but you can still hook up other Express applications as
 * subapplications (e.g. mount an admin frontend under the `/admin` path).
 *
 * To get access to the active application object, use the `app` property of
 * either `IncomingMessage` or `ServerResponse`.
 *
 *
 * ## Routes
 *
 * An Express object wraps a Router and has itself all the methods attached to
 * a `RouteKeeper`. That is, you case use `get`, `post`, etc methods to setup
 * routes of the application.
 * Example:
 *
 *     let app = Express()
 *     app.use("/index") {
 *       req, res, _ in try res.render("index")
 *     }
 *
 *
 * ## Template Engines
 *
 * Express objects have a mapping of file extensions to 'template engines'. Own
 * engines can be added by calling the `engine` function:
 *
 *     engine("mustache", mustacheExpress)
 *
 * The would call the `mustacheExpress` template engine when templates with the
 * `.mustache` extensions need to be rendered.
 *
 *
 * ## SettingsHolder
 *
 * TODO: document
 *
 *
 * ## Mounted applications
 *
 * Express applications can be organized into 'sub applications' which can be
 * mounted into parent applications.
 *
 * For example to mount an admin frontend into your main application, the code
 * would look like:
 *
 *     let app = ApacheExpress.express(cmd, name: "mods_testapexdb")
 *     app.use("/admin", AdminExpress.admin())
 *
 * Where `admin` returns another Express instance representing the admin
 * application.
 * The neat thing is that the routes used within the admin application are then
 * relative to "/admin", e.g. "/admin/index" for a route targetting "/index".
 *
 */
open class Express: SettingsHolder, MountableMiddlewareObject, RouteKeeper,
                    CustomStringConvertible
{
  
  public let router        : Router
    // TBD: rather inherit? It used to be a struct, but not anmore.
  
  public var settingsStore = [ String : Any ]()
  
  public init(id: String? = nil, mount: String? = nil) {
    router = Router(id: id, pattern: mount)
    
    let me = mustacheExpress()
    engine("mustache", me)
    engine("html",     me)
    
    // defaults
    set("view engine", "mustache")
    
    if let env = process.env["EXPRESS_ENV"], !env.isEmpty {
      set("env", env)
    }
  }
  
  
  // MARK: - MiddlewareObject
  
  open func handle(error        : Error?,
                   request  req : IncomingMessage,
                   response res : ServerResponse,
                   next         : Next) throws
  {
    let oldApp = req.app
    let oldReq = res.request
    req.extra[ExpressExtKey.app] = self
    res.extra[ExpressExtKey.app] = self
    res.extra[ExpressExtKey.req] = req
    
    try router.handle(error: error, request: req, response: res) {
      ( args: Any... ) in
      // this is only called if no object in the sub-application called 'next'!
      req.extra[ExpressExtKey.app] = oldApp
      res.extra[ExpressExtKey.app] = oldApp
      res.extra[ExpressExtKey.req] = oldReq
      
      next() // continue
    }
  }
  
  open func clearAttachedState(request  req : IncomingMessage,
                               response res : ServerResponse)
  { // break cycles
    req.extra[ExpressExtKey.app] = nil
    res.extra[ExpressExtKey.app] = nil
    res.extra[ExpressExtKey.req] = nil
  }
  
  
  // MARK: - Route Keeper
  
  open func add(route e: Route) {
    router.add(route: e)
  }
  
  
  // MARK: - SettingsHolder
  
  open func set(_ key: String, _ value: Any?) {
    if let v = value {
      settingsStore[key] = v
    }
    else {
      settingsStore.removeValue(forKey: key)
    }
  }
  
  open func get(_ key: String) -> Any? {
    // TODO: inherit values from parent application?
    return settingsStore[key]
  }
  
  
  // MARK: - Engines
  
  var engines = [ String : ExpressEngine]()
  
  public func engine(_ key: String, _ engine: @escaping ExpressEngine) {
    engines[key] = engine
  }
  
  
  // MARK: - Extension Point for Subclasses
  
  open func viewDirectory(for engine: String, response: ServerResponse)
            -> String
  {
    // Maybe that should be an array
    // This should allow 'views' as a relative path.
    // Also, in Apache it should be a configuration directive.
    let viewsPath = (get("views") as? String)
                 ?? process.env["EXPRESS_VIEWS"]
             //  ?? apacheRequest.pathRelativeToServerRoot(filename: "views")
                 ?? process.cwd()
    return viewsPath
  }

  
  // MARK: - Mounting
  
  final var mountListeners = [ ( Express ) -> Void ]()
  
  @discardableResult
  public func onMount(handler lcb: @escaping ( Express ) -> Void) -> Self {
    mountListeners.append(lcb)
    return self
  }
  
  public func emitOnMount(parent: Express) {
    for listener in mountListeners {
      listener(parent)
    }
  }
  
  /// One or more path patterns on which this instance was mounted as a sub
  /// application.
  open var mountPath : [ String ]?
  
  public func mount(at: String, parent: Express) {
    if mountPath == nil {
      mountPath = [ at ]
    }
    else {
      mountPath!.append(at)
    }
    emitOnMount(parent: parent)
  }
  
  
  // MARK: - Description

  /// The identifier used in the x-powered-by header
  open var productIdentifier : String {
    return "ExExpress"
  }
  
  open var description : String {
    var ms = "<\(type(of: self)):"
    
    if router.isEmpty {
      ms += " no-routes"
    }
    else if router.count == 1 {
      ms += " route"
    }
    else {
      ms += " #routes=\(router.count)"
    }
    
    if let mountPath = mountPath, !mountPath.isEmpty {
      if mountPath.count == 1 {
        ms += " mounted=\(mountPath[0])"
      }
      else {
        ms += " mounted=[\(mountPath.joined(separator: ","))]"
      }
    }
    
    if !engines.isEmpty {
      ms += " engines="
      ms += engines.keys.joined(separator: ",")
    }
    
    if !settingsStore.isEmpty {
      for ( key, value ) in settingsStore {
        ms += " '\(key)'='\(value)'"
      }
    }
    
    ms += ">"
    return ms
  }
}


/**
 * Express rendering engine. A rendering engine is a function which gets a
 * filesystem path and options. It is responsible for parsing the template at
 * the path. And responsible for evaluating the template.
 * When it is done, it calls the callback.
 *
 * The callback arguments are currently a potential error (or nil) and the
 * result.
 */
public typealias ExpressEngine = (
    _ path:     String,
    _ options:  Any?,
    _ callback: ( Any?... ) throws -> Void
  ) throws -> Void



// keys for extra dictionary in IncomingRequest/ServerResponse

enum ExpressExtKey {
  static let app     = "io.noze.express.app"
  static let req     = "io.noze.express.request"
  static let params  = "io.noze.express.params"
  static let locals  = "io.noze.express.locals"
  static let route   = "io.noze.express.route"
  static let baseURL = "io.noze.express.baseurl"
  static let query   = "io.noze.express.query"
}


public extension Dictionary where Key : ExpressibleByStringLiteral {
  
  subscript(int key: Key) -> Int? {
    guard let v = self[key] else { return nil }
    if let i = (v as? Int) { return i }
    return Int("\(v)")
  }
  
  subscript(string key: Key) -> String? {
    guard let v = self[key] else { return nil }
    return v as? String ?? "\(v)"
  }
  
  subscript(bool key: Key) -> Bool {
    guard let v = self[key] else { return false }
    if let b = v as? Bool { return b }
    if let i = v as? Int  { return i != 0 }
    
    // TODO: optionals
    let s = (v as? String ?? "\(v)").lowercased()
    switch s {
      case "true", "yes", "1": return true
      default: return false
    }
  }
}

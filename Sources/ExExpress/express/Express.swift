//
//  Express.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/**
 * The Express application object
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
 * TODO: examples
 * TODO: document view engines
 * TODO: SettingsHolder
 * TODO: RouteKeeper
 */
open class Express: SettingsHolder, MountableMiddlewareObject, RouteKeeper,
                    CustomStringConvertible
{
  
  public let router        : Router
  public var settingsStore = [ String : Any ]()
  
  public init(id: String? = nil, mount: String? = nil) {
    router = Router(id: id, pattern: mount)
    
    // defaults
    set("view engine", "mustache")
    engine("mustache", mustacheExpress)
    engine("html",     mustacheExpress)
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
    
    try router.handle(error: error, request: req, response: res) { _ in
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
  
  public func set(_ key: String, _ value: Any?) {
    if let v = value {
      settingsStore[key] = v
    }
    else {
      settingsStore.removeValue(forKey: key)
    }
  }
  
  public func get(_ key: String) -> Any? {
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


public typealias ExpressEngine = (
    _ path:    String,
    _ options: Any?,
    _ done:    @escaping ( Any?... ) throws -> Void
  ) throws -> Void



// keys for extra dictionary in IncomingRequest/ServerResponse

enum ExpressExtKey {
  static let app     = "io.noze.express.app"
  static let req     = "io.noze.express.request"
  static let params  = "io.noze.express.params"
  static let locals  = "io.noze.express.locals"
  static let route   = "io.noze.express.route"
  static let baseURL = "io.noze.express.baseurl"
}


public extension Dictionary where Key : ExpressibleByStringLiteral {
  public subscript(int key : Key) -> Int? {
    guard let v = self[key] else { return nil }
    if let i = (v as? Int) { return i }
    return Int("\(v)")
  }
}

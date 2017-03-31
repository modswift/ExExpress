//
//  RouteKeeper.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/**
 * An object which keeps routes.
 *
 * Within the express module only the Express object itself is a route keeper.
 *
 * The primary purpose of this protocol is to decouple all the convenience 
 * `use`, `get` etc functions from the actual functionality: `add(route:)`.
 */
public protocol RouteKeeper: class {
  
  func add(route e: Route)
  
}

// MARK: - Route Method

public extension RouteKeeper {
  
  /**
   * Returns a route to gate on a path. Since a `Route` itself is a RouteKeeper,
   * you can then hookup additional routes.
   *
   * Example:
   *
   *     app.route("/cows")
   *       .get  { req, res, next ... }
   *       .post { req, res, next ... }
   *
   */
  public func route(_ p: String) -> Route {
    let route = Route(pattern: nil, method: nil, middleware: [])
    add(route: route)
    return route
  }
  
}


// MARK: - Add Middleware
  
public extension RouteKeeper {
  
  @discardableResult
  public func use(_ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: nil, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  public func use(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  public func all(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  public func get(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "GET", middleware: [cb]))
    return self
  }
  @discardableResult
  public func post(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "POST", middleware: [cb]))
    return self
  }
  @discardableResult
  public func head(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "HEAD", middleware: [cb]))
    return self
  }
  @discardableResult
  public func put(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "PUT", middleware: [cb]))
    return self
  }
  @discardableResult
  public func del(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "DELETE", middleware: [cb]))
    return self
  }
  @discardableResult
  public func patch(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "PATCH", middleware: [cb]))
    return self
  }

  @discardableResult
  public func get(_ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: nil, method: "GET", middleware: [cb]))
    return self
  }
  @discardableResult
  public func post(_ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: nil, method: "POST", middleware: [cb]))
    return self
  }
  @discardableResult
  public func head(_ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: nil, method: "HEAD", middleware: [cb]))
    return self
  }
  @discardableResult
  public func put(_ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: nil, method: "PUT", middleware: [cb]))
    return self
  }
  @discardableResult
  public func del(_ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: nil, method: "DELETE", middleware: [cb]))
    return self
  }
  @discardableResult
  public func patch(_ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: nil, method: "PATCH", middleware: [cb]))
    return self
  }
}

fileprivate func mountIfPossible(pattern : String,
                                 parent  : RouteKeeper,
                                 child   : MiddlewareObject)
{
  guard let parent = parent as? Express                   else { return }
  guard let child  = child  as? MountableMiddlewareObject else { return }
  child.mount(at: pattern, parent: parent)
}

public extension RouteKeeper {
  // Directly attach MiddlewareObject's as Middleware. That is:
  //   let app   = express()
  //   let admin = express()
  //   app.use("/admin", admin)
  // TBD: should we have a Route which keeps the object? Has various advantages,
  //      particularily during debugging.
  
  @discardableResult
  public func use(_ mw: MiddlewareObject) -> Self {
    return use(mw.middleware)
  }
  
  @discardableResult
  public func use(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(pattern: p, parent: self, child: mw)
    return use(p, mw.middleware)
  }
  
  @discardableResult
  public func all(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(pattern: p, parent: self, child: mw)
    return all(p, mw.middleware)
  }
  
  @discardableResult
  public func get(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(pattern: p, parent: self, child: mw)
    return get(p, mw.middleware)
  }
  
  @discardableResult
  public func post(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(pattern: p, parent: self, child: mw)
    return post(p, mw.middleware)
  }
  
  @discardableResult
  public func head(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(pattern: p, parent: self, child: mw)
    return head(p, mw.middleware)
  }
  
  @discardableResult
  public func put(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(pattern: p, parent: self, child: mw)
    return put(p, mw.middleware)
  }
  
  @discardableResult
  public func del(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(pattern: p, parent: self, child: mw)
    return del(p, mw.middleware)
  }
  
  @discardableResult
  public func patch(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(pattern: p, parent: self, child: mw)
    return patch(p, mw.middleware)
  }
}

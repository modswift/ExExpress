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
public protocol RouteKeeper {
  
  mutating func add(route e: Route)
  
}

// MARK: - Add Middleware
  
public extension RouteKeeper {
  
  @discardableResult
  public mutating func use(_ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: nil, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  public mutating func use(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  public mutating func all(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  public mutating func get(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "GET", middleware: [cb]))
    return self
  }
  @discardableResult
  public mutating func post(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "POST", middleware: [cb]))
    return self
  }
  @discardableResult
  public mutating func head(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "HEAD", middleware: [cb]))
    return self
  }
  @discardableResult
  public mutating func put(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "PUT", middleware: [cb]))
    return self
  }
  @discardableResult
  public mutating func del(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "DELETE", middleware: [cb]))
    return self
  }
  @discardableResult
  public mutating func patch(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: "PATCH", middleware: [cb]))
    return self
  }
}

fileprivate func mountIfPossible(parent: RouteKeeper, child: MiddlewareObject) {
  guard let parent = parent as? Express                   else { return }
  guard let child  = child  as? MountableMiddlewareObject else { return }
  child.emitOnMount(parent: parent)
}

public extension RouteKeeper {
  // Directly attach MiddlewareObject's as Middleware. That is:
  //   let app   = express()
  //   let admin = express()
  //   app.use("/admin", admin)
  
  @discardableResult
  public mutating func use(_ mw: MiddlewareObject) -> Self {
    mountIfPossible(parent: self, child: mw)
    return use(mw.middleware)
  }
  
  @discardableResult
  public mutating func use(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(parent: self, child: mw)
    return use(p, mw.middleware)
  }
  
  @discardableResult
  public mutating func all(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(parent: self, child: mw)
    return all(p, mw.middleware)
  }
  
  @discardableResult
  public mutating func get(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(parent: self, child: mw)
    return get(p, mw.middleware)
  }
  
  @discardableResult
  public mutating func post(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(parent: self, child: mw)
    return post(p, mw.middleware)
  }
  
  @discardableResult
  public mutating func head(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(parent: self, child: mw)
    return head(p, mw.middleware)
  }
  
  @discardableResult
  public mutating func put(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(parent: self, child: mw)
    return put(p, mw.middleware)
  }
  
  @discardableResult
  public mutating func del(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(parent: self, child: mw)
    return del(p, mw.middleware)
  }
  
  @discardableResult
  public mutating func patch(_ p: String, _ mw: MiddlewareObject) -> Self {
    mountIfPossible(parent: self, child: mw)
    return patch(p, mw.middleware)
  }
}

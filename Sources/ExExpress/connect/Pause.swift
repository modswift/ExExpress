//
//  Pause.swift
//  Noze.io
//
//  Created by Helge Hess on 21/07/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

/// Middleware to simulate latency.
///
/// Pause all requests:
///
///     app.use(pause(1337)) // wait for 1337ms, then continue
///     app.get("/") { req, res in
///       res.send("Waited 1337 ms")
///     }
///
public func pause(_ timeout: Int, _ error: Error? = nil) -> Middleware {
  return { req, res, next in
    // OBVIOUSLY THIS IS NON-SENSE in the Apache context ;-)
    // Use a proper throttling module.
    let micro = timeout * 1000
    usleep(useconds_t(micro))
    
    if let error = error {
      throw error
    }
    else {
      next()
    }
  }
}

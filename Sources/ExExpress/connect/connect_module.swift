//
// Copyright (C) 2017-2019 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 26/01/2017.
//

public extension http.Server {
  
  func connect(middleware: Middleware...) -> Connect {
    let app = Connect()
    
    for m in middleware {
      _ = app.use(m)
    }
    
    self.onRequest(handler: app.handle)
    
    return app
  }
  
}

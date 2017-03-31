//
//  TestSupport.swift
//  ExExpress
//
//  Created by Helge Hess on 31/03/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

// Helper objects for tests. In 3.0 there is no simple way to share such in just
// the tests I thijk.

class TestMessageBase : HttpMessageBaseType {
  
  let log : ConsoleType = console.defaultConsole
  
  // this is extra storage to attach more info to the message
  var extra = [ String : Any ]()
  
  
  // MARK: - Headers
  
  func setHeader(_ name: String, _ value: Any) {
    headers[name.lowercased()] = value
  }
  func removeHeader(_ name: String) {
    headers.removeValue(forKey: name.lowercased())
  }
  func getHeader(_ name: String) -> Any? {
    return headers[name]
  }
  
  var headers : Dictionary<String, Any> = [
    "content-type": "text/html"
  ]
  
}

class TestRequest : TestMessageBase, IncomingMessage {

  var httpVersion = "HTTP/1.1"
  var method      = "GET"
  var url         = "/"
  
  var body : String? = nil
  
  // hack, use a proper stream
  func readChunks(bufsize: Int,
                  onRead: ( UnsafeBufferPointer<UInt8> ) throws -> Void) throws
  {
    guard let body = body else { return }
    
    let buffer = Array(body.utf8)
    try buffer.withUnsafeBufferPointer { bp in
      try onRead(bp)
    }
  }
  
}

class TestResponse : TestMessageBase, ServerResponse {
  
  var statusCode  : Int? = 200
  var headersSent : Bool = false
  var dataWritten = [ UInt8 ]()
  
  func writeHead(_ statusCode: Int, _ headers: Dictionary<String, Any>) {
    self.statusCode = statusCode
    
    // merge in headers
    for (key, value) in headers {
      setHeader(key, value)
    }
  }
  
  func writev(buckets chunks: [ [ UInt8 ] ], done: DoneCB?) throws {
    chunks.forEach { dataWritten.append(contentsOf: $0) }
  }
  
  func end() throws {
    if let cb = finishListener { cb(self) }
  }
  
  var finishListener : (( ServerResponse ) -> Void)? = nil
  
  func onceFinish(handler: @escaping ( ServerResponse ) -> Void) {
    assert(finishListener == nil)
    finishListener = handler
  }
  func onFinish  (handler: @escaping ( ServerResponse ) -> Void) {
    onceFinish(handler: handler)
  }
  
}

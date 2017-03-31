//
//  ExpressTests.swift
//  ExpressTests
//
//  Created by Helge Hess on 31/03/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import XCTest
@testable import ExExpress

class ExExRouteTests: XCTestCase {
  
  #if false
  func testSimpleExactPathMatch() throws {
    let app = Express()
    
    var matched = false
    app.get("/hello") { _, _, _ in matched = true }
    
    let req = TestRequest()
    let res = TestResponse()
    try app.requestHandler(req, res)
    
    XCTAssert(matched, "middleware wasn't triggered as expected")
  }
  #endif
  
}

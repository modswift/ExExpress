//
//  QueryStringTests.swift
//  ExExpress
//
//  Created by Helge Hess on 02.05.17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import XCTest
@testable import ExExpress

class QueryStringTests: XCTestCase {
 
  let sample1 = "draw=1&columns%5B0%5D%5Bdata%5D=login&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=true&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=name&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=true&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B2%5D%5Bdata%5D=cities&columns%5B2%5D%5Bname%5D=&columns%5B2%5D%5Bsearchable%5D=true&columns%5B2%5D%5Borderable%5D=true&columns%5B2%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B2%5D%5Bsearch%5D%5Bregex%5D=false&order%5B0%5D%5Bcolumn%5D=0&order%5B0%5D%5Bdir%5D=asc&start=0&length=10&search%5Bvalue%5D=&search%5Bregex%5D=false&_=1493677490768"

  let queryKeyNested = "foo[bar][baz]"
    // 'foo[bar][baz]=foobarbaz' -> [ "foo": [ "bar": [ "baz": "foobarbaz" ] ] ]
  
  let queryKeyArray   = "a[]"
    // 'a[]=b&a[]=c')            -> [ "a": [ "b", "c" ] ]
  
  let queryKeyIndexedArray = "a[1]"
    // 'a[1]=b&a[3]=c'           -> [ "a": [ nil, "b", nil, "c" ] ]  (max: 20)
  
  let queryKeyDotted = "a.b"
    // 'a.b=c' (allowsDot)       -> [ "a": [ "b": "c" ] ]
  
  let queryKeyArrayOfObjects = "a[][b]"
    // 'a[][b]=c'                -> [ "a": [ [ "b": "c" ] ] ]
  
  func testQueryStringParsing() throws {
    let qp = querystring.parse(sample1)
    print("QP: \(qp)")
    
    XCTAssertNotNil(qp["search[value]"])
    XCTAssertEqual(qp["length"] as? String, "10")
  }
  
  func testNestedKey() throws {
    let keyPath = qs.parseKeyPath(queryKeyNested, allowsDot: false)
    XCTAssertEqual(keyPath.count, 3)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "foo") }
    else { XCTAssert(false, "not a string key") }

    if case .Key(let value) = keyPath[1] { XCTAssertEqual(value, "bar") }
    else { XCTAssert(false, "not a string key") }

    if case .Key(let value) = keyPath[2] { XCTAssertEqual(value, "baz") }
    else { XCTAssert(false, "not a string key") }
  }
  
  func testArrayKey() throws {
    let keyPath = qs.parseKeyPath(queryKeyArray, allowsDot: false)
    XCTAssertEqual(keyPath.count, 2)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a") }
    else { XCTAssert(false, "not a string key") }
    
    if case .Array = keyPath[1] { }
    else { XCTAssert(false, "not an array key") }
  }
  
  func testIndexedArrayKey() throws {
    let keyPath = qs.parseKeyPath(queryKeyIndexedArray, allowsDot: false)
    XCTAssertEqual(keyPath.count, 2)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a") }
    else { XCTAssert(false, "not a string key") }
    
    if case .Index(let value) = keyPath[1] { XCTAssertEqual(value, 1) }
    else { XCTAssert(false, "not an index key") }
  }
  
  func testDottedDisabled() throws {
    let keyPath = qs.parseKeyPath(queryKeyDotted, allowsDot: false)
    XCTAssertEqual(keyPath.count, 1)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a.b") }
    else { XCTAssert(false, "not a string key") }
  }
  
  func testDottedEnabled() throws {
    let keyPath = qs.parseKeyPath(queryKeyDotted, allowsDot: true)
    XCTAssertEqual(keyPath.count, 2)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a") }
    else { XCTAssert(false, "not a string key") }
    
    if case .Key(let value) = keyPath[1] { XCTAssertEqual(value, "b") }
    else { XCTAssert(false, "not a string key") }
  }
  
  func testArrayOfObjects() throws {
    let keyPath = qs.parseKeyPath(queryKeyArrayOfObjects, allowsDot: false)
    XCTAssertEqual(keyPath.count, 3)
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a") }
    else { XCTAssert(false, "not a string key") }
    
    if case .Array = keyPath[1] { }
    else { XCTAssert(false, "not an array key") }
    
    if case .Key(let value) = keyPath[2] { XCTAssertEqual(value, "b") }
    else { XCTAssert(false, "not a string key") }
  }
  
  func testQueryKeyDepthLimit() throws {
    let keyPath = qs.parseKeyPath("a[b][c][d]", depth: 1, allowsDot: false)
    XCTAssertEqual(keyPath.count, 3)
    
    print("Keypath: \(keyPath)")
    
    if case .Key(let value) = keyPath[0] { XCTAssertEqual(value, "a") }
    else { XCTAssert(false, "not a string key") }

    if case .Key(let value) = keyPath[1] { XCTAssertEqual(value, "b") }
    else { XCTAssert(false, "not a string key") }

    if case .Key(let value) = keyPath[2] { XCTAssertEqual(value, "[c][d]") }
    else { XCTAssert(false, "not a string key") }
  }
}

